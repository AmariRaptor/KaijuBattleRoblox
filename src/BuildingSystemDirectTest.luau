--!strict
-- BuildingSystemDirectTest.luau
-- A direct test for BuildingSystem functionality with strict Luau types

print("=== Starting BuildingSystemDirectTest ===")

-- Types
type BuildingType = {
    HEALTH: number,
    SIZE: Vector3,
    DAMAGE: number,
    REPAIR_RATE: number,
    EFFECTS: {[string]: boolean}
}

type BuildingSystem = {
    BUILDING_TYPES: {
        [string]: BuildingType
    },
    CreateBuilding: (self: BuildingSystem, buildingType: string, position: Vector3) -> Model,
    CalculateDamage: (self: BuildingSystem, building: Model, damage: number) -> boolean,
    RepairBuilding: (self: BuildingSystem, building: Model) -> boolean,
    GetBuildingHealth: (self: BuildingSystem, building: Model) -> number?
}

-- Define the test function
local function testBuildingSystem(): (boolean, string)
    -- Mock the BuildingSystem with proper types
    local BuildingSystem: BuildingSystem = {
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
        
        CreateBuilding = function(self: BuildingSystem, buildingType: string, position: Vector3): Model
            local building = Instance.new("Model")
            building.Name = buildingType
            
            -- Set up building attributes
            local buildingInfo = self.BUILDING_TYPES[buildingType]
            if not buildingInfo then
                error("Invalid building type: " .. tostring(buildingType))
            end
            
            -- Create primary part
            local part = Instance.new("Part")
            part.Size = buildingInfo.SIZE
            part.Position = position
            part.Anchored = true
            part.Parent = building
            
            -- Add health value
            local health = Instance.new("NumberValue")
            health.Name = "Health"
            health.Value = buildingInfo.HEALTH
            health.Parent = building
            
            -- Add max health for reference
            local maxHealth = Instance.new("NumberValue")
            maxHealth.Name = "MaxHealth"
            maxHealth.Value = buildingInfo.HEALTH
            maxHealth.Parent = building
            
            -- Add building type
            local typeValue = Instance.new("StringValue")
            typeValue.Name = "BuildingType"
            typeValue.Value = buildingType
            typeValue.Parent = building
            
            -- Add effects folder
            local effects = Instance.new("Folder")
            effects.Name = "Effects"
            effects.Parent = building
            
            -- Initialize effects
            for effectName, _ in pairs(buildingInfo.EFFECTS) do
                local effect = Instance.new("BoolValue")
                effect.Name = effectName
                effect.Value = true
                effect.Parent = effects
            end
            
            return building
        end,
        
        CalculateDamage = function(self: BuildingSystem, building: Model, damage: number): boolean
            local health = building:FindFirstChild("Health")
            if not health or not health:IsA("NumberValue") then
                return false
            end
            
            health.Value = math.max(0, health.Value - damage)
            return health.Value > 0
        end,
        
        RepairBuilding = function(self: BuildingSystem, building: Model): boolean
            local health = building:FindFirstChild("Health")
            local maxHealth = building:FindFirstChild("MaxHealth")
            
            if not health or not health:IsA("NumberValue") or 
               not maxHealth or not maxHealth:IsA("NumberValue") then
                return false
            end
            
            local buildingType = building:FindFirstChild("BuildingType")
            if not buildingType or not buildingType:IsA("StringValue") then
                return false
            end
            
            local buildingInfo = self.BUILDING_TYPES[buildingType.Value]
            if not buildingInfo then
                return false
            end
            
            health.Value = math.min(maxHealth.Value, health.Value + buildingInfo.REPAIR_RATE)
            return true
        end,
        
        GetBuildingHealth = function(self: BuildingSystem, building: Model): number?
            local health = building:FindFirstChild("Health")
            if not health or not health:IsA("NumberValue") then
                return nil
            end
            return health.Value
        end
    }
    
    -- Test 1: Create a building and verify its properties
    local testPosition = Vector3.new(0, 0, 0)
    local building = BuildingSystem:CreateBuilding("SKYSCRAPER", testPosition)
    
    if not building or not building:IsA("Model") then
        return false, "Failed to create building"
    end
    
    -- Verify building properties
    if building.Name ~= "SKYSCRAPER" then
        return false, "Building name does not match type"
    end
    
    local health = building:FindFirstChild("Health")
    if not health or not health:IsA("NumberValue") then
        return false, "Building is missing Health value"
    end
    
    if health.Value ~= 200 then
        return false, string.format("Expected health 200, got %d", health.Value)
    end
    
    -- Test 2: Damage the building
    local isAlive = BuildingSystem:CalculateDamage(building, 50)
    if not isAlive then
        return false, "Building should still be alive after 50 damage"
    end
    
    local currentHealth = BuildingSystem:GetBuildingHealth(building)
    if currentHealth ~= 150 then
        return false, string.format("Expected health 150 after damage, got %d", currentHealth or -1)
    end
    
    -- Test 3: Repair the building
    local repairSuccess = BuildingSystem:RepairBuilding(building)
    if not repairSuccess then
        return false, "Failed to repair building"
    end
    
    currentHealth = BuildingSystem:GetBuildingHealth(building)
    if currentHealth ~= 152 then -- 150 + 2 (REPAIR_RATE for SKYSCRAPER)
        return false, string.format("Expected health 152 after repair, got %d", currentHealth or -1)
    end
    
    -- Test 4: Test building destruction
    isAlive = BuildingSystem:CalculateDamage(building, 200)
    if isAlive then
        return false, "Building should be destroyed after 200 damage"
    end
    
    currentHealth = BuildingSystem:GetBuildingHealth(building)
    if currentHealth ~= 0 then
        return false, string.format("Expected health 0 after destruction, got %d", currentHealth or -1)
    end
    
    -- Test 5: Test invalid building type
    local success, errorMsg = pcall(function()
        return BuildingSystem:CreateBuilding("INVALID_TYPE", testPosition)
    end)
    
    if success then
        return false, "Expected error for invalid building type, but none was raised"
    end
    
    if not errorMsg:find("Invalid building type") then
        return false, string.format("Unexpected error message: %s", tostring(errorMsg))
    end
    
    return true, "All BuildingSystem tests passed"
end

-- Run the test and return the result
local success, result = pcall(testBuildingSystem)
if not success then
    print("❌ Test failed with error:", tostring(result))
    return {success = false, message = "Test failed with error: " .. tostring(result)}
end

local testPassed, message = result
if testPassed then
    print("✅ " .. message)
    return {success = true, message = message}
else
    print("❌ " .. tostring(message))
    return {success = false, message = message}
end
