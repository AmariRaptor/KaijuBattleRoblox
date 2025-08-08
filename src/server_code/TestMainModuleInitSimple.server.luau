--!strict
-- Simple test script for MainModule initialization

print("=== Starting MainModule Test ===\n")

-- Services
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 1. Check if MainModule exists
print("1. Checking for MainModule in ServerScriptService...")
local mainModule = ServerScriptService:FindFirstChild("MainModule")
if not mainModule or not mainModule:IsA("ModuleScript") then
    warn("❌ MainModule not found in ServerScriptService")
    print("   Available children in ServerScriptService:")
    for _, child in ipairs(ServerScriptService:GetChildren()) do
        print("   - " .. child:GetFullName() .. " (" .. child.ClassName .. ")")
    end
    return
end
print("✅ Found MainModule: " .. mainModule:GetFullName())

-- 2. Print the first few lines of MainModule source
print("\n2. MainModule source preview:")
local sourceLines = {}
for line in mainModule.Source:gmatch("[^\r\n]+") do
    table.insert(sourceLines, line)
end

-- Print first 10 lines or all if less than 10
local linesToShow = math.min(10, #sourceLines)
for i = 1, linesToShow do
    print("   " .. sourceLines[i])
end
if #sourceLines > 10 then
    print("   ... (" .. (#sourceLines - 10) .. " more lines)")
end

-- 3. Try to require MainModule
print("\n3. Attempting to require MainModule...")
local success, module = pcall(require, mainModule)
if not success then
    warn("❌ Failed to require MainModule:")
    warn(module)
    return
end
print("✅ Successfully required MainModule")

-- 4. Check if MainModule has required methods
print("\n4. Checking MainModule interface...")
local requiredMethods = {"init", "isInitialized", "getSystem", "getInitializedSystems"}
local interfaceOk = true

for _, method in ipairs(requiredMethods) do
    if type(module[method]) ~= "function" then
        warn("❌ Missing required method: " .. method)
        interfaceOk = false
    end
end

if not interfaceOk then
    warn("\n❌ MainModule is missing required methods")
    return
end
print("✅ MainModule has all required methods")

-- 5. Check initialization state
print("\n5. Checking initialization state...")
local isInitialized = module:isInitialized()
print("   isInitialized(): " .. tostring(isInitialized))

-- 6. Try to initialize
print("\n6. Attempting to initialize MainModule...")
local initSuccess, initResult = pcall(function()
    return module:init()
end)

if not initSuccess then
    warn("❌ MainModule:init() failed:")
    warn(initResult)
    return
end
print("✅ MainModule:init() completed successfully")

-- 7. Check initialization state again
print("\n7. Checking initialization state after init...")
isInitialized = module:isInitialized()
print("   isInitialized(): " .. tostring(isInitialized))

-- 8. Check initialized systems
print("\n8. Checking initialized systems...")
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

print("\n=== Test Complete ===\n")
