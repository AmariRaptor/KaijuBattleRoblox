--!strict
-- Script to directly check MainModule in ServerScriptService

print("=== Direct MainModule Check ===\n")

-- 1. Get ServerScriptService
local success, ServerScriptService = pcall(function()
    return game:GetService("ServerScriptService")
end)

if not success then
    warn("❌ Failed to get ServerScriptService:", ServerScriptService)
    return
end

print("✅ Successfully got ServerScriptService")

-- 2. List all children of ServerScriptService
print("\n=== ServerScriptService Children ===")
local children = {}
for _, child in ipairs(ServerScriptService:GetChildren()) do
    table.insert(children, string.format("%s (%s)", child.Name, child.ClassName))
end

table.sort(children)
for _, childInfo in ipairs(children) do
    print("  - " .. childInfo)
end

-- 3. Look for MainModule
print("\n=== Looking for MainModule ===")
local mainModule = ServerScriptService:FindFirstChild("MainModule")

if not mainModule then
    warn("❌ MainModule not found in ServerScriptService")
    return
end

print("✅ Found MainModule: " .. mainModule:GetFullName())
print("   Class: " .. mainModule.ClassName)

-- 4. Check if it's a ModuleScript
if not mainModule:IsA("ModuleScript") then
    warn("❌ MainModule is not a ModuleScript (it's a " .. mainModule.ClassName .. ")")
    return
end

print("✅ MainModule is a ModuleScript")

-- 5. Check source
local source = mainModule.Source
print("\n=== MainModule Source (first 200 chars) ===")
print(string.sub(source, 1, 200) .. (string.len(source) > 200 and "..." or ""))

-- 6. Try to require
print("\n=== Attempting to require MainModule ===")
local success, result = pcall(require, mainModule)

if not success then
    warn("❌ Failed to require MainModule:")
    warn(result)
    return
end

print("✅ Successfully required MainModule")
print("   Return type: " .. type(result))

-- 7. Check if it has required methods
print("\n=== Checking MainModule Interface ===")
local requiredMethods = {"init", "isInitialized", "getSystem", "getInitializedSystems"}
local interfaceOk = true

for _, method in ipairs(requiredMethods) do
    if type(result[method]) ~= "function" then
        warn("❌ Missing required method: " .. method)
        interfaceOk = false
    end
end

if not interfaceOk then
    warn("\n❌ MainModule is missing required methods")
    return
end

print("✅ MainModule has all required methods")

-- 8. Try to initialize
print("\n=== Attempting to initialize MainModule ===")
local initSuccess, initResult = pcall(result.init, result)

if not initSuccess then
    warn("❌ MainModule:init() failed:")
    warn(initResult)
    return
end

print("✅ MainModule:init() completed successfully")

-- 9. Check initialization state
print("\n=== Checking Initialization State ===")
local isInitialized = result:isInitialized()
print("   isInitialized(): " .. tostring(isInitialized))

-- 10. Check initialized systems
print("\n=== Checking Initialized Systems ===")
local systems = result:getInitializedSystems()
local systemCount = 0
for _ in pairs(systems) do systemCount += 1 end

print("   Initialized systems count: " .. systemCount)
if systemCount > 0 then
    print("   Systems:")
    for name, _ in pairs(systems) do
        print("   - " .. name)
    end
end

print("\n=== Direct MainModule Check Complete ===\n")
