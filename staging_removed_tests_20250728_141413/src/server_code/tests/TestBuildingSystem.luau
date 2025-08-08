--!strict

-- TestBuildingSystem.luau
-- A test script for the BuildingSystem module that works in MCP

-- This is a simplified test that can be run directly in MCP
local function runTest()
    print("🚀 Starting BuildingSystem MCP test...")
    
    -- Get the BuildingSystem module
    local rs = game:GetService("ReplicatedStorage")
    local BuildingSystem = require(rs.BuildingSystem)
    
    -- Create a proper Player instance for testing
    local _Players = game:GetService("Players")
    local mockPlayer = Instance.new("Player")
    mockPlayer.Name = "TestPlayer"
    mockPlayer.UserId = 1
    
    -- Create a mock Character with required properties
    local character = Instance.new("Model")
    local humanoid = Instance.new("Humanoid")
    humanoid.Parent = character
    character.Parent = workspace
    mockPlayer.Character = character
    
    -- Test creating a building
    print("🏗️ Attempting to create a hospital building...")
    local success, building = pcall(function()
        return BuildingSystem:createBuilding("HOSPITAL", Vector3.new(0, 10, 0), mockPlayer)
    end)
    
    if not success or not building then
        local errorMsg = not success and building or "Failed to create building"
        print("❌ Test failed:", errorMsg)
        return {
            success = false,
            error = tostring(errorMsg)
        }
    end
    
    -- Format position as string for output
    local positionText = "N/A"
    if typeof(building.position) == "Vector3" then
        positionText = string.format("(%.2f, %.2f, %.2f)", 
            building.position.X, building.position.Y, building.position.Z)
    end
    
    -- Convert values to strings for printing
    local buildingTypeStr = tostring(building.buildingType or "N/A")
    local healthStr = tostring(building.health or "N/A")
    local maxHealthStr = tostring(building.maxHealth or "N/A")
    local ownerName = building.owner and building.owner.Name or "N/A"
    
    print("✅ Successfully created building:")
    print("   - Type:", buildingTypeStr)
    print("   - Health:", healthStr, "/", maxHealthStr)
    print("   - Owner:", ownerName)
    print("   - Position:", positionText)
    
    -- Check if the building has the expected methods
    local hasDamage = type(building.damage) == "function"
    local hasRepair = type(building.repair) == "function"
    local hasDestroy = type(building.destroy) == "function"
    
    print("\n🔧 Building Methods:")
    print("- damage:", hasDamage and "✅" or "❌")
    print("- repair:", hasRepair and "✅" or "❌")
    print("- destroy:", hasDestroy and "✅" or "❌")
    
    -- Create test results with proper typing
    local testResults = {
        success = true,
        error = "",  -- Empty string indicates no error
        buildingType = tostring(building.buildingType or "N/A"),
        health = building.health or 0,
        maxHealth = building.maxHealth or 0,
        owner = tostring(building.owner and building.owner.Name or "N/A"),
        position = positionText,
        hasDamage = hasDamage,
        hasRepair = hasRepair,
        hasDestroy = hasDestroy,
        isDestroyed = building.isDestroyed or false
    }

    -- Cleanup
    if mockPlayer.Character then
        mockPlayer.Character:Destroy()
    end

    return testResults
end

-- Return the test function for MCP to execute
return runTest
