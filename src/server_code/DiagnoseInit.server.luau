--!strict
-- Diagnostic script to identify MainModule initialization issues

print("\n=== Starting MainModule Initialization Diagnostics ===\n")

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- 1. Check if MainModule exists in ServerScriptService
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

-- 2. Check MainModule's source
print("\n2. Checking MainModule source...")
local source = mainModule.Source
print("   First 100 chars: " .. source:sub(1, 100) .. "...")

-- 3. Try to require MainModule
print("\n3. Attempting to require MainModule...")
local success, module = pcall(require, mainModule)
if not success then
    warn("❌ Failed to require MainModule:")
    warn(module)
    return
end
print("✅ Successfully required MainModule")

-- 4. Check if MainModule has expected methods
print("\n4. Checking MainModule interface...")
local interfaceOk = true
local requiredMethods = {"init", "isInitialized", "getSystem", "getInitializedSystems"}

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

-- 7. Check systems initialization
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

-- 8. Check for TestEZ errors
print("\n8. Checking for TestEZ configuration...")
local testEZ = ReplicatedStorage:FindFirstChild("TestEZ")
if not testEZ then
    warn("❌ TestEZ not found in ReplicatedStorage")
else
    print("✅ Found TestEZ in ReplicatedStorage")
    
    -- Check for TestBootstrap
    local testBootstrap = testEZ:FindFirstChild("TestBootstrap")
    if not testBootstrap or not testBootstrap:IsA("ModuleScript") then
        warn("❌ TestBootstrap not found in TestEZ")
    else
        print("✅ Found TestBootstrap")
    end
end

print("\n=== Diagnostics Complete ===\n")

-- Print next steps
print("NEXT STEPS:")
print("1. Check the output above for any errors or warnings")
print("2. If MainModule fails to require, check its source code")
print("3. If initialization fails, check the error message for details")
print("4. If no systems are initialized, check the systems folder")
print("5. For TestEZ errors, ensure TestEZ is properly installed")
print("\n=== End of Diagnostics ===\n")
