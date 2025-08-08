--!strict

local _Players = game:GetService("Players")

-- Type definitions for BuildingSystem
type Building = {
    buildingType: string,
    health: number,
    maxHealth: number,
    owner: Player,
    lastDamageTime: number?,
    lastRepairTime: number?,
    isDestroyed: boolean,
    id: string,
    position: Vector3,
    model: Model?,
    effects: { [string]: boolean },
    destroy: (self: Building) -> (),
    damage: (self: Building, amount: number) -> (),
    repair: (self: Building, amount: number) -> (),
    addEffect: (self: Building, effectName: string) -> (),
    removeEffect: (self: Building, effectName: string) -> (),
    hasEffect: (self: Building, effectName: string) -> boolean,
    getHealthPercentage: (self: Building) -> number,
    update: (self: Building, dt: number) -> ()
}

-- Mock BuildingSystem type that matches the actual implementation
type BuildingSystem = {
    new: () -> {
        createBuilding: (self: any, buildingType: string, position: Vector3, owner: Player) -> Building?
    }
}

-- Mock player for testing
local function createMockPlayer()
    local player = Instance.new("Player")
    player.Name = "TestPlayer"
    player.UserId = 12345
    return player :: Player
end

-- Helper to safely get a building
local function getBuilding(buildingSystem: any, buildingType: string, position: Vector3, owner: Player): Building
    local building = buildingSystem:createBuilding(buildingType, position, owner)
    assert(building ~= nil, "Failed to create building")
    return building :: Building
end

-- Create a test plan
local tests = {}

-- Test suite for BuildingSystem
tests["BuildingSystem"] = {
    testCreateSkyscraper = function()
        local BuildingSystem: BuildingSystem = require(game:GetService("ReplicatedStorage").BuildingSystem)
        local testPlayer = createMockPlayer()
        local buildingSystemInstance = BuildingSystem.new()
        
        local position = Vector3.new(0, 0, 0)
        local building = getBuilding(buildingSystemInstance, "SKYSCRAPER", position, testPlayer)
        
        assert(building.buildingType == "SKYSCRAPER", "Building type should be SKYSCRAPER")
        assert(building.health == 200, "Building health should be 200")
        assert(building.owner == testPlayer, "Building owner should be test player")
    end,
    
    testCreateHospital = function()
        local BuildingSystem: BuildingSystem = require(game:GetService("ReplicatedStorage").BuildingSystem)
        local testPlayer = createMockPlayer()
        local buildingSystemInstance = BuildingSystem.new()
        
        local position = Vector3.new(10, 0, 10)
        local building = getBuilding(buildingSystemInstance, "HOSPITAL", position, testPlayer)
        
        assert(building.buildingType == "HOSPITAL", "Building type should be HOSPITAL")
        assert(building.health == 150, "Building health should be 150")
        assert(building.owner == testPlayer, "Building owner should be test player")
    end,
    
    testApplyDamage = function()
        local BuildingSystem: BuildingSystem = require(game:GetService("ReplicatedStorage").BuildingSystem)
        local testPlayer = createMockPlayer()
        local buildingSystemInstance = BuildingSystem.new()
        
        local position = Vector3.new(0, 0, 0)
        local building = getBuilding(buildingSystemInstance, "SKYSCRAPER", position, testPlayer)
        
        local initialHealth = building.health
        building:damage(50)
        
        assert(building.health == initialHealth - 50, "Health should decrease by 50")
        assert(building.lastDamageTime ~= nil, "Last damage time should be set")
    end,
    
    testRepairBuilding = function()
        local BuildingSystem: BuildingSystem = require(game:GetService("ReplicatedStorage").BuildingSystem)
        local testPlayer = createMockPlayer()
        local buildingSystemInstance = BuildingSystem.new()
        
        local position = Vector3.new(0, 0, 0)
        local building = getBuilding(buildingSystemInstance, "SKYSCRAPER", position, testPlayer)
        
        -- First damage the building
        building:damage(50)
        local damagedHealth = building.health
        
        -- Then repair it
        building:repair(30)
        
        assert(building.health == damagedHealth + 30, "Health should increase by 30")
        assert(building.lastRepairTime ~= nil, "Last repair time should be set")
    end,
    
    testDestroyBuilding = function()
        local BuildingSystem: BuildingSystem = require(game:GetService("ReplicatedStorage").BuildingSystem)
        local testPlayer = createMockPlayer()
        local buildingSystemInstance = BuildingSystem.new()
        
        local position = Vector3.new(0, 0, 0)
        local building = getBuilding(buildingSystemInstance, "SKYSCRAPER", position, testPlayer)
        
        -- Store original destroy method
        local originalDestroy = building.destroy
        local wasDestroyed = false
        
        -- Override destroy method to track calls
        building.destroy = function(self: Building): ()
            wasDestroyed = true
            originalDestroy(self)
        end
        
        -- Deal enough damage to destroy the building
        building:damage(1000)
        
        assert(wasDestroyed == true, "Destroy method should be called")
        assert(building.isDestroyed == true, "Building should be marked as destroyed")
    end,
    
    testHealthBounds = function()
        local BuildingSystem: BuildingSystem = require(game:GetService("ReplicatedStorage").BuildingSystem)
        local testPlayer = createMockPlayer()
        local buildingSystemInstance = BuildingSystem.new()
        
        local position = Vector3.new(0, 0, 0)
        local building = getBuilding(buildingSystemInstance, "SKYSCRAPER", position, testPlayer)
        
        -- Test health doesn't go below zero
        building:damage(1000)
        assert(building.health == 0, "Health should not go below zero")
        
        -- Test health doesn't exceed max health
        local maxHealth = building.maxHealth
        building:repair(1000)
        assert(building.health == maxHealth, "Health should not exceed max health")
    end
}

return tests
