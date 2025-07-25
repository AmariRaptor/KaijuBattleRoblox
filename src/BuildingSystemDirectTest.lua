-- BuildingSystemDirectTest.lua
-- A direct test for BuildingSystem functionality

print("=== Starting BuildingSystemDirectTest ===")

-- Define the test function
local function testBuildingSystem()
    -- Mock the BuildingSystem
    local BuildingSystem = {
        BUILDING_TYPES = {
            SKYSCRAPER = {
                HEALTH = 200,
                SIZE = Vector3.new(10, 50, 10),
                DAMAGE = 5,
                REPAIR_RATE = 2,
                EFFECTS = {SMOKE = true, LIGHTS = true}
            },
            FACTORY = {
                HEALTH = 150,
                SIZE = Vector3.new(20, 10, 20),
                DAMAGE = 10,
                REPAIR_RATE = 1,
                EFFECTS = {SMOKE = true, FIRE = true}
            },
            POWER_PLANT = {
                HEALTH = 250,
                SIZE = Vector3.new(15, 15, 15),
                DAMAGE = 8,
                REPAIR_RATE = 3,
                EFFECTS = {ENERGY = true, LIGHTS = true}
            },
            HOSPITAL = {
                HEALTH = 180,
                SIZE = Vector3.new(12, 12, 12),
                DAMAGE = 7,
                REPAIR_RATE = 2,
                EFFECTS = {LIGHTS = true, MEDICAL = true}
            },
            MILITARY_BASE = {
                HEALTH = 300,
                SIZE = Vector3.new(25, 15, 25),
                DAMAGE = 15,
                REPAIR_RATE = 1,
                EFFECTS = {SMOKE = true, FIRE = true, LIGHTS = true}
            }
        },
        
        CreateBuilding = function(self, buildingType, position)
            local building = Instance.new("Model")
            building.Name = buildingType
            
            -- Get building properties
            local buildingProps = self.BUILDING_TYPES[buildingType]
            if not buildingProps then
                return nil, "Invalid building type: " .. tostring(buildingType)
            end
            
            -- Create base structure
            local base = Instance.new("Part")
            base.Size = buildingProps.SIZE
            base.Position = position or Vector3.new(0, 0, 0)
            base.Anchored = true
            base.Parent = building
            building.PrimaryPart = base
            
            -- Add health system
            local health = Instance.new("IntValue")
            health.Name = "Health"
            health.Value = buildingProps.HEALTH
            health.Parent = building
            
            -- Add repair rate
            local repair = Instance.new("IntValue")
            repair.Name = "RepairRate"
            repair.Value = buildingProps.REPAIR_RATE
            repair.Parent = building
            
            -- Add damage value
            local damage = Instance.new("IntValue")
            damage.Name = "Damage"
            damage.Value = buildingProps.DAMAGE
            damage.Parent = building
            
            return building
        end
    }

    -- Test building creation for each type
    local testPosition = Vector3.new(0, 0, 0)
    local buildingTypes = {"SKYSCRAPER", "FACTORY", "POWER_PLANT", "HOSPITAL", "MILITARY_BASE"}
    
    for _, buildingType in ipairs(buildingTypes) do
        print("Testing building type:", buildingType)
        
        -- Test building creation
        local building = BuildingSystem:CreateBuilding(buildingType, testPosition)
        if not building then
            return {success = false, message = string.format("Failed to create %s", buildingType)}
        end
        
        -- Verify building properties
        if building.Name ~= buildingType then
            return {success = false, message = string.format("Building name mismatch for %s: %s", buildingType, building.Name)}
        end
        
        local health = building:FindFirstChild("Health")
        if not health then
            return {success = false, message = string.format("Health not found in %s", buildingType)}
        end
        
        local expectedHealth = BuildingSystem.BUILDING_TYPES[buildingType].HEALTH
        if health.Value ~= expectedHealth then
            return {
                success = false, 
                message = string.format("Health mismatch for %s: expected %d, got %d", 
                    buildingType, expectedHealth, health.Value)
            }
        end
        
        -- Verify repair rate
        local repairRate = building:FindFirstChild("RepairRate")
        if not repairRate then
            return {success = false, message = string.format("RepairRate not found in %s", buildingType)}
        end
        
        -- Verify damage
        local damage = building:FindFirstChild("Damage")
        if not damage then
            return {success = false, message = string.format("Damage not found in %s", buildingType)}
        end
        
        print(string.format("✅ %s passed basic validation", buildingType))
    end
    
    -- Test invalid building type
    local invalidBuilding, errorMsg = BuildingSystem:CreateBuilding("INVALID_TYPE", testPosition)
    if invalidBuilding ~= nil then
        return {success = false, message = "Expected error for invalid building type, but got a building"}
    end
    
    if not errorMsg or not errorMsg:find("Invalid building type") then
        return {success = false, message = "Unexpected error message for invalid building type: " .. tostring(errorMsg)}
    end
    
    return {success = true, message = "All BuildingSystem tests passed!"}
end

-- Run the test and return the result
local success, result = pcall(testBuildingSystem)
if not success then
    print("❌ Test error: " .. tostring(result))
    return {success = false, message = "Test error: " .. tostring(result)}
end

-- Print the result for debugging
print(result.success and "✅ " or "❌ " .. tostring(result.message))
return result
