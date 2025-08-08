--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local systemsFolder = ServerScriptService:WaitForChild("systems")

-- List of systems to check and convert
local systemNames = {
    "ClassSystem",
    "CharacterSystem",
    "BuildingSystem",
    "KaijuSystem",
    "ScoringSystem"
}

-- Function to convert a Script to a ModuleScript
local function convertToModuleScript(script: Script): ModuleScript
    local moduleScript = Instance.new("ModuleScript")
    moduleScript.Name = script.Name
    moduleScript.Source = script.Source
    moduleScript.Parent = script.Parent
    script:Destroy()
    return moduleScript
end

-- Function to test a system module
local function testSystemModule(moduleScript: ModuleScript): boolean
    print("\n=== Testing " .. moduleScript.Name .. " ===")
    
    -- Try to require the module
    local success, module = pcall(require, moduleScript)
    if not success then
        warn("❌ Failed to require " .. moduleScript.Name .. ":")
        warn(module)
        return false
    end
    
    print("✅ Successfully required " .. moduleScript.Name)
    print("Module type: " .. type(module))
    
    -- Check if it has an init function
    if type(module.init) ~= "function" then
        warn("⚠️ " .. moduleScript.Name .. " does not have an init() function")
        return false
    end
    
    print("✅ Found init() function")
    
    -- Try to initialize the module
    local initSuccess, result = pcall(module.init, module)
    if not initSuccess then
        warn("❌ " .. moduleScript.Name .. ":init() failed:")
        warn(result)
        return false
    end
    
    print("✅ " .. moduleScript.Name .. " initialized successfully")
    return true
end

-- Main function to convert and test all systems
local function convertAndTestSystems()
    print("=== Converting and Testing Systems ===\n")
    
    local allPassed = true
    
    for _, systemName in ipairs(systemNames) do
        local system = systemsFolder:FindFirstChild(systemName)
        if not system then
            warn("❌ " .. systemName .. " not found in systems folder")
            allPassed = false
        else
            -- Convert Script to ModuleScript if needed
            if system:IsA("Script") then
                print("ℹ️ Converting " .. systemName .. " from Script to ModuleScript...")
                system = convertToModuleScript(system :: Script)
            end
            
            -- Test the module
            if not testSystemModule(system :: ModuleScript) then
                allPassed = false
            end
        end
    end
    
    -- Print final results
    print("\n=== Conversion and Testing Complete ===")
    if allPassed then
        print("✅ All systems converted and initialized successfully")
    else
        warn("❌ Some systems failed to convert or initialize")
    end
    
    return allPassed
end

-- Run the conversion and testing
return convertAndTestSystems()
