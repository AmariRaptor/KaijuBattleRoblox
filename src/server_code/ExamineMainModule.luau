--!strict
-- Script to directly examine MainModule source and state

print("=== Examining MainModule ===\n")

-- 1. Get ServerScriptService
local sss = game:GetService("ServerScriptService")

-- 2. Find MainModule
local mainModule = sss:FindFirstChild("MainModule")
if not mainModule then
    warn("❌ MainModule not found in ServerScriptService")
    print("   Available children in ServerScriptService:")
    for _, child in ipairs(sss:GetChildren()) do
        print("   - " .. child:GetFullName() .. " (" .. child.ClassName .. ")")
    end
    return
end

print("✅ Found MainModule: " .. mainModule:GetFullName())
print("   Class: " .. mainModule.ClassName)

-- 3. Check if it's a ModuleScript
if not mainModule:IsA("ModuleScript") then
    warn("❌ MainModule is not a ModuleScript (it's a " .. mainModule.ClassName .. ")")
    return
end

print("✅ MainModule is a ModuleScript")

-- 4. Print source code
local source = mainModule.Source
print("\n=== MainModule Source (first 500 characters) ===")
print(string.sub(source, 1, 500) .. (string.len(source) > 500 and "..." or ""))

-- 5. Try to require the module
print("\n=== Attempting to require MainModule ===")
local success, module = pcall(require, mainModule)

if not success then
    warn("❌ Failed to require MainModule:")
    warn(module)
    return
end

print("✅ Successfully required MainModule")
print("   Module type: " .. type(module))

-- 6. Check for required methods
print("\n=== Checking for required methods ===")
local requiredMethods = {"init", "isInitialized", "getSystem", "getInitializedSystems"}
local allMethodsFound = true

for _, method in ipairs(requiredMethods) do
    if type(module[method]) ~= "function" then
        warn("❌ Missing required method: " .. method)
        allMethodsFound = false
    end
end

if allMethodsFound then
    print("✅ All required methods found")
end

-- 7. Check initialization state
print("\n=== Checking initialization state ===")
local isInitialized = module:isInitialized()
print("   isInitialized(): " .. tostring(isInitialized))

-- 8. If not initialized, try to initialize
if not isInitialized then
    print("\n=== Attempting to initialize MainModule ===")
    local initSuccess, initResult = pcall(module.init, module)
    
    if not initSuccess then
        warn("❌ MainModule:init() failed:")
        warn(initResult)
    else
        print("✅ MainModule:init() completed successfully")
        print("   isInitialized() after init: " .. tostring(module:isInitialized()))
    end
end

-- 9. Check initialized systems
print("\n=== Checking initialized systems ===")
local systems = module:getInitializedSystems()
local systemCount = 0
for _ in pairs(systems) do systemCount += 1 end

print("   Initialized systems count: " .. systemCount)
if systemCount > 0 then
    print("   Systems:")
    for name, _ in pairs(systems) do
        print("   - " .. name)
    end
end

-- 10. Try to get a system
print("\n=== Testing getSystem() ===")
local testSystem = module:getSystem("TestSystem1")
print("   getSystem(\"TestSystem1\"): " .. (testSystem and "✅ Found" or "❌ Not found"))

print("\n=== MainModule Examination Complete ===\n")
