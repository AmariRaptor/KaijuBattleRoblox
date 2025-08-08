--!strict
-- CheckSystems.luau
-- Simple script to check if systems can be required and initialized

-- List of systems to check
local SYSTEMS = {
    "ClassSystem",
    "CharacterSystem",
    "BuildingSystem",
    "KaijuSystem",
    "ScoringSystem"
}

local function checkSystem(systemName: string): (boolean, string?)
    print("\n🔍 Checking system: " .. systemName)
    
    -- Try to find the module in the expected location
    local modulePath = "src/server_code/systems/" .. systemName .. ".server.luau"
    local success, system = pcall(dofile, modulePath)
    
    if not success then
        warn("❌ Failed to load " .. systemName .. ": " .. tostring(system))
        return false, "Load failed"
    end
    
    if type(system) ~= "table" then
        warn("❌ " .. systemName .. " is not a table")
        return false, "Not a table"
    end
    
    -- Check for init method
    if type(system.init) ~= "function" then
        warn("⚠️ " .. systemName .. " is missing init method (using default)")
    else
        -- Try to initialize
        local initSuccess, initResult = pcall(system.init, system)
        if not initSuccess then
            warn("❌ " .. systemName .. " init failed: " .. tostring(initResult))
            return false, "Init failed"
        end
    end
    
    print("✅ " .. systemName .. " looks good!")
    return true, "Success"
end

-- Main function
local function main()
    print("\n🔧 System Checker 🔧\n")
    
    local passed = 0
    local total = #SYSTEMS
    
    for _, systemName in ipairs(SYSTEMS) do
        local success, _ = checkSystem(systemName)
        if success then
            passed = passed + 1
        end
    end
    
    -- Print summary
    print("\n📊 Results:")
    print(string.format("✅ %d/%d systems passed", passed, total))
    print(string.format("📈 %.0f%% success rate", (passed / total) * 100))
    
    return passed == total
end

-- Run the check
local success, result = pcall(main)
if not success then
    warn("❌ Checker encountered an error: " .. tostring(result))
end

return success and result
