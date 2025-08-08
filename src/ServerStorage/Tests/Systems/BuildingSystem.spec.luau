--!strict

return function()
    describe("BuildingSystem", function()
        it("should load without errors", function()
            local BuildingSystem = require(game:GetService("ServerScriptService").systems.BuildingSystem)
            expect(BuildingSystem).to.be.ok()
        end)
    end)
end
    
    -- Test suite setup
    local function setup()
        local BuildingSystem = require(BUILDING_SYSTEM_PATH)
        local buildingSystem = BuildingSystem.new(mockServiceProvider)
        
        -- Mock player with necessary attributes
        local testPlayer = createMockPlayer()
        return {
            buildingSystem = buildingSystem,
            mockWorkspace = mockWorkspace,
            mockPlayers = mockPlayers
        }
    end
    
    -- Test runner
    local function runTests()
        local testData = setup()
        local results = {
            passed = 0,
            failed = 0,
            errors = {}
                    testPlayer,
                    "TestBuilding",
                    CFrame.new(0, 0, 0)
                )
                
                TestEZ.expect(success).to.equal(false)
                TestEZ.expect(message).to.equal("Invalid position")
                
                -- Restore original method
                context.buildingSystem._canPlaceBuilding = originalCanPlace
            end,
            
            testCheckBuildingPlacement = function()
                local context = setup()
                local testPlayer = context.testPlayer
                
                -- Test valid position
                local canPlace, message = context.buildingSystem:_canPlaceBuilding(
                    testPlayer,
                    CFrame.new(0, 10, 0), -- Position above ground
                    Vector3.new(4, 4, 4)  -- Building size
                )
                
                TestEZ.expect(canPlace).to.equal(true)
                TestEZ.expect(message).to.be.ok()
                
                -- Test position too close to another building
                -- This would require mocking the spatial query in a real test
            end,
            
            testGetPlayerBuildings = function()
                local context = setup()
                local testPlayer = context.testPlayer
                
                -- Initially should be empty
                local buildings = context.buildingSystem:getPlayerBuildings(testPlayer)
                TestEZ.expect(#buildings).to.equal(0)
                
                -- After placing a building, should return it
                context.buildingSystem._canPlaceBuilding = function() return true end
                context.buildingSystem:placeBuilding(testPlayer, "TestBuilding", CFrame.new(0, 0, 0))
                
                buildings = context.buildingSystem:getPlayerBuildings(testPlayer)
                TestEZ.expect(#buildings).to.equal(1)
            end
        }
    }
    
    return tests
end
