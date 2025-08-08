--!strict

local ServerScriptService = game:GetService("ServerScriptService")

print("=== TestMainModuleInit started ===\n")

-- Find the MainModule
local mainModule = ServerScriptService:FindFirstChild("MainModule")
if not mainModule or not mainModule:IsA("ModuleScript") then
    warn("❌ MainModule not found in ServerScriptService")
    return
end

-- Print MainModule source for verification
print("=== MainModule Source ===")
print(mainModule.Source)
print("\n" .. string.rep("=", 50) .. "\n")

-- 1. First, require the MainModule
print("=== Step 1: Requiring MainModule ===")
local success, module = pcall(require, mainModule)
if not success then
    warn("❌ Failed to require MainModule:")
    warn(module)
    return
end

print("✅ Successfully required MainModule")
print("Module type:", typeof(module))
print("Is table:", type(module) == "table")
print("Has metatable:", getmetatable(module) ~= nil)

-- 2. Check if MainModule has the expected methods
print("\n=== Step 2: Verifying MainModule methods ===")
local methods = {
    "isInitialized",
    "getSystem",
    "getInitializedSystems",
    "init"
}

for _, method in ipairs(methods) do
    print(string.format("- %s: %s", method, type(module[method]) == "function" and "✅" or "❌"))
end

-- 3. Check if already initialized
print("\n=== Step 3: Checking initialization state ===")
local isInitialized = module:isInitialized()
print("Is initialized before init():", isInitialized and "✅ Yes" or "❌ No")

if isInitialized then
    print("\nMainModule is already initialized. Getting initialized systems...")
    local systems = module:getInitializedSystems()
    print("Number of initialized systems:", #systems)
    for name, _ in pairs(systems) do
        print("- " .. name)
    end
    return
end

-- 4. Initialize MainModule
print("\n=== Step 4: Initializing MainModule ===")
local initSuccess, initResult = pcall(function()
    return module:init()
end)

if not initSuccess then
    warn("❌ MainModule:init() failed:")
    warn(initResult)
    return
end

print("✅ MainModule:init() completed successfully")
print("Return value from init():", tostring(initResult))

-- 5. Check initialization state after init
print("\n=== Step 5: Verifying initialization ===")
isInitialized = module:isInitialized()
print("Is initialized after init():", isInitialized and "✅ Yes" or "❌ No")

-- 6. Get initialized systems
print("\n=== Step 6: Checking initialized systems ===")
local systems = module:getInitializedSystems()
print("Number of initialized systems:", #systems)

if next(systems) == nil then
    warn("⚠️ No systems were initialized!")
    
    -- Debug: Check the systemsToLoad table
    print("\n=== Debug: systemsToLoad ===")
    local systemsFolder = ServerScriptService:FindFirstChild("systems")
    if systemsFolder then
        print("Systems folder found. Contents:")
        for _, child in ipairs(systemsFolder:GetChildren()) do
            print("- " .. child.Name .. " (" .. child.ClassName .. ")")
        end
    else
        warn("❌ Systems folder not found!")
    end
    
    -- Try to access the systemsToLoad table directly
    print("\n=== Debug: Direct system initialization attempt ===")
    for _, systemName in ipairs({"ClassSystem", "CharacterSystem", "BuildingSystem", "KaijuSystem", "ScoringSystem"}) do
        local systemModule = systemsFolder and systemsFolder:FindFirstChild(systemName)
        if systemModule and systemModule:IsA("ModuleScript") then
            print("\nTrying to initialize " .. systemName .. " directly...")
            local success, result = pcall(require, systemModule)
            if success then
                print("✅ Successfully required " .. systemName)
                print("  - Type:", typeof(result))
                if type(result) == "table" then
                    print("  - Has init():", type(result.init) == "function" and "✅" or "❌")
                    if type(result.init) == "function" then
                        local initSuccess, initResult = pcall(result.init, result)
                        print("  - init() result:", initSuccess and "✅ Success" or "❌ Failed")
                        if not initSuccess then
                            warn("  - Error:", tostring(initResult))
                        end
                    end
                end
            else
                warn("❌ Failed to require " .. systemName .. ":")
                warn(result)
            end
        else
            warn("❌ " .. systemName .. " not found or not a ModuleScript")
        end
    end
else
    print("\nInitialized systems:")
    for name, system in pairs(systems) do
        print(string.format("- %s (type: %s)", name, typeof(system)))
    end
end

print("\n=== TestMainModuleInit completed ===")
