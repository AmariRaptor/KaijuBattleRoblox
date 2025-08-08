--!strict
-- SimpleSystemCheck.luau
-- A minimal script to check system initialization in the MCP environment

local function checkSystem(systemName: string): (boolean, string)
    print("\n🔍 Checking system: " .. systemName)
    
    -- Try to find the system module
    local success, system = pcall(function()
        return require(script.Parent.systems[systemName])
    end)
    
    if not success then
        local errorMsg = "❌ Failed to require " .. systemName .. ": " .. tostring(system)
        warn(errorMsg)
        return false, errorMsg
    end
    
    -- Check if the system is a table
    if type(system) ~= "table" then
        local errorMsg = "❌ " .. systemName .. " is not a table (got " .. type(system) .. ")"
        warn(errorMsg)
        return false, errorMsg
    end
    
    -- Check for init method
    if type(system.init) ~= "function" then
        local errorMsg = "❌ " .. systemName .. " is missing init method"
        warn(errorMsg)
        return false, errorMsg
    end
    
    -- Try to initialize
    local initSuccess, initResult = pcall(system.init, system)
    if not initSuccess then
        local errorMsg = "❌ " .. systemName .. " init failed: " .. tostring(initResult)
        warn(errorMsg)
        return false, errorMsg
    end
    
    local successMsg = "✅ " .. systemName .. " passed all checks"
    print(successMsg)
    return true, successMsg
end

-- Main function
local function main()
    print("\n🔧 Starting System Check 🔧\n")
    
    -- List of systems to check
    local systemsToCheck = {
        "ClassSystem",
        "CharacterSystem",
        "BuildingSystem",
        "KaijuSystem",
        "ScoringSystem"
    }
    
    local results = {}
    local passed = 0
    
    -- Run checks
    for _, systemName in ipairs(systemsToCheck) do
        local success, message = checkSystem(systemName)
        results[systemName] = {success = success, message = message}
        if success then
            passed = passed + 1
        end
    end
    
    -- Print summary
    print("\n📊 Results:")
    for systemName, result in pairs(results) do
        print(string.format("%s %s: %s", 
            result.success and "✅" or "❌", 
            systemName, 
            result.message or "No details"))
    end
    
    print("\n📈 Summary:")
    print(string.format("✅ %d/%d systems passed", passed, #systemsToCheck))
    print(string.format("📉 %.0f%% success rate", (passed / #systemsToCheck) * 100))
    
    return passed == #systemsToCheck, results
end

-- Run the check
local success, result = pcall(main)
if not success then
    warn("❌ Checker encountered an error: " .. tostring(result))
    return false, "Checker error: " .. tostring(result)
end

return result
