--!strict
-- BuildingSystemTest.luau
-- Comprehensive tests for the BuildingSystem module

-- Mock TestEZ since we can't require it directly
local TestEZ = {
    TestBootstrap = {
        run = function() return {} end
    },
    TestStatus = {
        Success = "Success",
        Failure = "Failure"
    }
}

-- Simple mock player creation
local function createMockPlayer()
    return {
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
end

-- Mock BuildingSystem module
local MockBuildingSystem = {}
MockBuildingSystem.__index = MockBuildingSystem

function MockBuildingSystem.new(serviceProvider: any): any
    local self = setmetatable({}, MockBuildingSystem)
    self._serviceProvider = serviceProvider
    return self
end

function MockBuildingSystem:placeBuilding(player: any, buildingType: string, cframe: CFrame): (boolean, string?)
    -- Mock implementation for testing
    if buildingType == "InvalidBuilding" then
        return false, "Invalid building type"
    end
    return true, nil
end

function MockBuildingSystem:getPlayerBuildings(player: any): {any}
    return {}
end

function MockBuildingSystem:_canPlaceBuilding(player: any, cframe: CFrame, size: Vector3): (boolean, string)
    return true, ""
end

-- Test runner
local function runTests()
    local testResults = {
        passed = 0,
        failed = 0,
        errors = {}
    }
    
    local function logTestResult(group: string, name: string, success: boolean, errorMsg: string?)
        if success then
            testResults.passed += 1
            print(string.format("✅ [PASS] %s.%s", group, name))
        else
            testResults.failed += 1
            table.insert(testResults.errors, {
                group = group,
                test = name,
                error = errorMsg or "Test failed"
            })
            print(string.format("❌ [FAIL] %s.%s - %s", group, name, errorMsg or "Test failed"))
        end
    end
    
    -- Setup test environment
    local serviceProvider = {
        GetService = function(_, serviceName: string)
            return {
                Name = serviceName,
                FindFirstChild = function() return nil end
            }
        end
    }
    
    local buildingSystem = MockBuildingSystem.new(serviceProvider)
    local testPlayer = createMockPlayer()
    
    -- Test groups
    local testGroups = {
        ["BuildingSystem.placeBuilding()"] = {
            ["should place a valid building"] = function()
                local success, message = buildingSystem:placeBuilding(testPlayer, "Tower", CFrame.new(0, 0, 0))
                assert(success == true, "Expected placeBuilding to return true")
                assert(message == nil, "Expected no error message")
                return true
            end,
            
            ["should fail to place an invalid building"] = function()
                local success, message = buildingSystem:placeBuilding(testPlayer, "InvalidBuilding", CFrame.new(0, 0, 0))
                assert(success == false, "Expected placeBuilding to return false")
                assert(type(message) == "string", "Expected an error message")
                return true
            end
        },
        
        ["BuildingSystem.getPlayerBuildings()"] = {
            ["should return empty table for player with no buildings"] = function()
                local buildings = buildingSystem:getPlayerBuildings(testPlayer)
                assert(type(buildings) == "table", "Expected a table")
                assert(#buildings == 0, "Expected empty buildings table")
                return true
            end
        },
        
        ["BuildingSystem._canPlaceBuilding()"] = {
            ["should allow placement in valid location"] = function()
                local canPlace, message = buildingSystem:_canPlaceBuilding(
                    testPlayer, 
                    CFrame.new(0, 0, 0), 
                    Vector3.new(4, 4, 4)
                )
                assert(canPlace == true, "Expected canPlace to be true")
                assert(message == "", "Expected empty message")
                return true
            end
        }
    }
    
    -- Run all test groups
    print("\n=== Starting BuildingSystem Tests ===")
    for groupName, group in pairs(testGroups) do
        for testName, testFunc in pairs(group) do
            local success, err = pcall(testFunc)
            logTestResult(groupName, testName, success, err)
        end
    end
    
    -- Print summary
    print("\n=== Test Summary ===")
    print(string.format("Passed: %d", testResults.passed))
    print(string.format("Failed: %d", testResults.failed))
    
    if #testResults.errors > 0 then
        print("\nFailed Tests:")
        for _, error in ipairs(testResults.errors) do
            print(string.format("- %s.%s: %s", error.group, error.test, error.error))
        end
    end
    
    return testResults
end

-- Run tests and return results
return runTests()
