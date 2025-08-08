--!strict
-- Script to verify the current state of MainModule in ServerScriptService

print("=== Verifying MainModule State ===\n")

-- Services
local ServerScriptService = game:GetService("ServerScriptService")

-- 1. Check if MainModule exists
print("1. Checking for MainModule in ServerScriptService...")
local mainModule = ServerScriptService:FindFirstChild("MainModule")

if not mainModule then
    warn("❌ MainModule not found in ServerScriptService")
    print("   Available children in ServerScriptService:")
    for _, child in ipairs(ServerScriptService:GetChildren()) do
        print("   - " .. child:GetFullName() .. " (" .. child.ClassName .. ")")
    end
    return
end

print("✅ Found MainModule: " .. mainModule:GetFullName())
print("   Class: " .. mainModule.ClassName)

-- 2. Check if it's a ModuleScript
if not mainModule:IsA("ModuleScript") then
    warn("❌ MainModule is not a ModuleScript (it's a " .. mainModule.ClassName .. ")")
    return
end

print("✅ MainModule is a ModuleScript")

-- 3. Check source code
local source = mainModule.Source
print("\n2. MainModule source code length: " .. #source .. " characters")
print("   First 200 characters: " .. string.sub(source, 1, 200) .. (string.len(source) > 200 and "..." or ""))

-- 4. Try to require the module
print("\n3. Attempting to require MainModule...")
local success, module = pcall(require, mainModule)

if not success then
    warn("❌ Failed to require MainModule:")
    warn(module)
    return
end

print("✅ Successfully required MainModule")
print("   Module type: " .. type(module))

-- 5. Check for required methods
print("\n4. Checking for required methods...")
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

-- 6. Check initialization state
print("\n5. Checking initialization state...")
local isInitialized = module:isInitialized()
print("   isInitialized(): " .. tostring(isInitialized))

-- 7. If not initialized, try to initialize
if not isInitialized then
    print("\n6. Attempting to initialize MainModule...")
    local initSuccess, initResult = pcall(module.init, module)
    
    if not initSuccess then
        warn("❌ MainModule:init() failed:")
        warn(initResult)
    else
        print("✅ MainModule:init() completed successfully")
        print("   isInitialized() after init: " .. tostring(module:isInitialized()))
    end
end

-- 8. Check initialized systems
print("\n7. Checking initialized systems...")
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

-- 9. Try to get a system
print("\n8. Testing getSystem()...")
local testSystem = module:getSystem("TestSystem1")
print("   getSystem(\"TestSystem1\"): " .. (testSystem and "✅ Found" or "❌ Not found"))

print("\n=== MainModule State Verification Complete ===\n")
