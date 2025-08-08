--!strict
-- MinimalBuildingSystemTest.luau
-- A minimal test script for the BuildingSystem

-- This is the main function that MCP will call
return function()
    print("🚀 Starting BuildingSystem tests...")
    
    -- Create a mock player
    local mockPlayer = {
        Name = "TestPlayer",
        UserId = 1,
        Character = {
            HumanoidRootPart = {
                CFrame = CFrame.new(0, 0, 0),
                Size = Vector3.new(2, 2, 1)
            },
            Humanoid = {
                WalkSpeed = 16,
                JumpPower = 50
            }
        }
    }
    
    -- Try to load the BuildingSystem
    local BuildingSystem
    local success, err = pcall(function()
        -- Try to get BuildingSystem from ReplicatedStorage first
        local rs = game:GetService("ReplicatedStorage")
        if rs:FindFirstChild("BuildingSystem") then
            BuildingSystem = require(rs.BuildingSystem)
        else
            -- Fallback to direct require
            BuildingSystem = require(script.Parent.Parent.systems.BuildingSystem)
        end
    end)
    
    if not success then
        local errorMsg = "❌ Failed to load BuildingSystem: " .. tostring(err)
        print(errorMsg)
        return {
            success = "false",
            error = errorMsg
        }
    end
    
    print("✅ BuildingSystem loaded successfully")
    
    -- Initialize the BuildingSystem if it has an init method
    if type(BuildingSystem.init) == "function" then
        BuildingSystem:init()
    end
    
    -- Test creating a building
    local building = BuildingSystem:createBuilding("HOSPITAL", Vector3.new(0, 0, 0), mockPlayer)
    
    if not building then
        local errorMsg = "❌ Failed to create building"
        print(errorMsg)
        return {
            success = "false",
            error = errorMsg
        }
    end
    
    print("✅ Successfully created building:", building.buildingType)
    print("   Health:", building.health, "/", building.maxHealth)
    print("   Owner:", building.owner.Name)
    
    -- Test results
    local testResults = {
        success = "true",
        message = "All tests passed",
        tests = {}
    }
    
    -- Test damaging the building if the method exists
    if type(building.damage) == "function" then
        local initialHealth = building.health
        building:damage(10)
        
        if building.health >= initialHealth then
            local errorMsg = "❌ Building damage test failed"
            print(errorMsg)
            testResults.success = "false"
            testResults.error = errorMsg
            table.insert(testResults.tests, {name = "Damage Test", passed = false, error = errorMsg})
        else
            print("✅ Building damage test passed")
            print("   Health after damage:", building.health, "/", building.maxHealth)
            table.insert(testResults.tests, {name = "Damage Test", passed = true})
        end
    else
        print("⚠️ Skipping damage test - damage method not found")
        table.insert(testResults.tests, {name = "Damage Test", skipped = true, message = "Damage method not found"})
    end
    
    -- Only continue with other tests if we haven't failed yet
    if testResults.success == "true" then
        -- Test repairing the building if the method exists
        if type(building.repair) == "function" then
            local damagedHealth = building.health
            building:repair(5)
            
            if building.health <= damagedHealth then
                local errorMsg = "❌ Building repair test failed"
                print(errorMsg)
                testResults.success = "false"
                testResults.error = errorMsg
                table.insert(testResults.tests, {name = "Repair Test", passed = false, error = errorMsg})
            else
                print("✅ Building repair test passed")
                print("   Health after repair:", building.health, "/", building.maxHealth)
                table.insert(testResults.tests, {name = "Repair Test", passed = true})
            end
        else
            print("⚠️ Skipping repair test - repair method not found")
            table.insert(testResults.tests, {name = "Repair Test", skipped = true, message = "Repair method not found"})
        end
        
        -- Test destroying the building if the method exists
        if type(building.destroy) == "function" then
            building:destroy()
            
            if not building.isDestroyed then
                local errorMsg = "❌ Building destroy test failed"
                print(errorMsg)
                testResults.success = "false"
                testResults.error = testResults.error or errorMsg
                table.insert(testResults.tests, {name = "Destroy Test", passed = false, error = errorMsg})
            else
                print("✅ Building destroy test passed")
                print("   Is destroyed:", building.isDestroyed)
                table.insert(testResults.tests, {name = "Destroy Test", passed = true})
            end
        else
            print("⚠️ Skipping destroy test - destroy method not found")
            table.insert(testResults.tests, {name = "Destroy Test", skipped = true, message = "Destroy method not found"})
        end
    end
    
    -- Print final result
    if testResults.success == "true" then
        print("\n🎉 All tests completed successfully!")
    else
        print("\n❌ Some tests failed")
    end
    
    return testResults
end
