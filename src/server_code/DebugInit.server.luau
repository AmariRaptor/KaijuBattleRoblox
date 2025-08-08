--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("\n=== DebugInit Script Started ===\n")

-- 1. Check if systems folder exists
local systemsFolder = ServerScriptService:FindFirstChild("systems")
if not systemsFolder then
    warn("❌ 'systems' folder not found in ServerScriptService")
    return
end

-- 2. List all systems in the folder
print("=== Systems in ServerScriptService/systems ===")
local systemModules = {}
for _, child in ipairs(systemsFolder:GetChildren()) do
    if child:IsA("ModuleScript") then
        table.insert(systemModules, child.Name)
        print("- " .. child.Name .. " (ModuleScript)")
    else
        print("- " .. child.Name .. " (" .. child.ClassName .. " - not a ModuleScript)")
    end
end
print("\nTotal ModuleScripts found:", #systemModules)

-- 3. Create a test system to verify module loading
local function testSystemLoad(systemName: string)
    print("\n" .. string.rep("=", 60))
    print("🔍 Testing system: " .. systemName)
    print(string.rep("=", 60))
    
    -- Find the module
    local moduleScript = systemsFolder:FindFirstChild(systemName)
    if not moduleScript or not moduleScript:IsA("ModuleScript") then
        warn("❌ " .. systemName .. " not found or not a ModuleScript")
        return false
    end
    
    print("✅ Found ModuleScript: " .. moduleScript:GetFullName())
    
    -- Require the module
    local success, moduleTable = pcall(require, moduleScript)
    if not success then
        warn("❌ Failed to require " .. systemName .. ":")
        warn(moduleTable)
        return false
    end
    
    print("✅ Successfully required " .. systemName)
    print("  - Module type: " .. typeof(moduleTable))
    
    -- Check if the module has an init function
    if type(moduleTable) ~= "table" then
        warn("❌ Module did not return a table (got: " .. typeof(moduleTable) .. ")")
        return false
    end
    
    print("  - Has init():", type(moduleTable.init) == "function" and "✅" or "❌")
    
    -- Try to initialize if init exists
    if type(moduleTable.init) == "function" then
        print("  - Calling init()...")
        local initSuccess, initResult = pcall(moduleTable.init, moduleTable)
        if not initSuccess then
            warn("❌ init() failed:")
            warn(initResult)
            return false
        end
        print("  - init() result:", initResult ~= nil and tostring(initResult) or "nil")
    end
    
    return true
end

-- 4. Test loading each system
print("\n=== Testing System Loading ===")
local successCount = 0
for _, systemName in ipairs(systemModules) do
    if testSystemLoad(systemName) then
        successCount += 1
    end
end

-- 5. Print summary
print("\n=== Test Summary ===")
print(string.format("Successfully loaded %d/%d systems", successCount, #systemModules))

-- 6. Test MainModule initialization
print("\n=== Testing MainModule Initialization ===")
local mainModule = ServerScriptService:FindFirstChild("MainModule")
if not mainModule or not mainModule:IsA("ModuleScript") then
    warn("❌ MainModule not found in ServerScriptService")
    return
end

print("✅ Found MainModule")

-- Require MainModule
local success, module = pcall(require, mainModule)
if not success then
    warn("❌ Failed to require MainModule:")
    warn(module)
    return
end

print("✅ Successfully required MainModule")

-- Initialize MainModule
print("\n=== Initializing MainModule ===")
local initSuccess, initResult = pcall(module.init, module)
if not initSuccess then
    warn("❌ MainModule:init() failed:")
    warn(initResult)
    return
end

print("✅ MainModule:init() completed successfully")

-- Check initialized systems
if type(module.getInitializedSystems) ~= "function" then
    warn("❌ MainModule does not have getInitializedSystems method")
    return
end

local systems = module:getInitializedSystems()
print("\n=== Initialized Systems ===")

if next(systems) == nil then
    warn("⚠️ No systems were initialized!")
    
    -- Debug: Try to access initializedSystems directly (if possible)
    print("\n=== Debug: Checking MainModule state ===")
    print("- initializedSystems type:", typeof(module.initializedSystems))
    print("- initializedSystems content:")
    for k, v in pairs(module) do
        if k == "initializedSystems" then
            print("  - " .. k .. ": " .. tostring(v))
            if type(v) == "table" then
                print("    - Table contents:")
                for sysName, _ in pairs(v) do
                    print("      - " .. tostring(sysName))
                end
            end
        end
    end
else
    print("✅ Successfully initialized systems:")
    for name, _ in pairs(systems) do
        print("- " .. name)
    end
end

print("\n=== DebugInit Script Complete ===")
