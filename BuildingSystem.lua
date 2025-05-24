                                                    -- BuildingSystem.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MainModule = require(ReplicatedStorage:WaitForChild("MainModule"))

local BuildingSystem = {}

-- Building types and their properties
BuildingSystem.BUILDING_TYPES = {
    SKYSCRAPER = {
        HEALTH = 200,
        SIZE = Vector3.new(10, 50, 10),
        DAMAGE = 5,
        REPAIR_RATE = 2,
        EFFECTS = {
            SMOKE = true,
            LIGHTS = true
        }
    },
    FACTORY = {
        HEALTH = 150,
        SIZE = Vector3.new(20, 10, 20),
        DAMAGE = 10,
        REPAIR_RATE = 1,
        EFFECTS = {
            SMOKE = true,
            FIRE = true
        }
    },
    POWER_PLANT = {
        HEALTH = 250,
        SIZE = Vector3.new(15, 15, 15),
        DAMAGE = 8,
        REPAIR_RATE = 3,
        EFFECTS = {
            ENERGY = true,
            LIGHTS = true
        }
    },
    HOSPITAL = {
        HEALTH = 180,
        SIZE = Vector3.new(12, 12, 12),
        DAMAGE = 7,
        REPAIR_RATE = 2,
        EFFECTS = {
            LIGHTS = true,
            MEDICAL = true
        }
    },
    MILITARY_BASE = {
        HEALTH = 300,
        SIZE = Vector3.new(25, 15, 25),
        DAMAGE = 15,
        REPAIR_RATE = 1,
        EFFECTS = {
            SMOKE = true,
            FIRE = true,
            LIGHTS = true
        }
    }
}

function BuildingSystem:CreateBuilding(buildingType, position)
    local building = Instance.new("Model")
    building.Name = buildingType
    
    -- Get building properties
    local buildingProps = self.BUILDING_TYPES[buildingType]
    
    -- Create base structure
    local base = Instance.new("Part")
    base.Size = buildingProps.SIZE
    base.Position = position
    base.Anchored = true
    base.Parent = building
    
    -- Add building-specific parts
    if buildingType == "SKYSCRAPER" then
        self:createSkyscraper(building)
    elseif buildingType == "FACTORY" then
        self:createFactory(building)
    elseif buildingType == "POWER_PLANT" then
        self:createPowerPlant(building)
    elseif buildingType == "HOSPITAL" then
        self:createHospital(building)
    elseif buildingType == "MILITARY_BASE" then
        self:createMilitaryBase(building)
    end
    
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
    
    -- Add effects
    if buildingProps.EFFECTS.SMOKE then
        self:addSmokeEffect(building)
    end
    if buildingProps.EFFECTS.FIRE then
        self:addFireEffect(building)
    end
    if buildingProps.EFFECTS.LIGHTS then
        self:addLightEffect(building)
    end
    if buildingProps.EFFECTS.ENERGY then
        self:addEnergyEffect(building)
    end
    if buildingProps.EFFECTS.MEDICAL then
        self:addMedicalEffect(building)
    end
    
    -- Add destruction effects
    local destruction = Instance.new("Folder")
    destruction.Name = "Destruction"
    destruction.Parent = building
    
    return building
end

function BuildingSystem:createSkyscraper(building)
    -- Create main structure
    local tower = Instance.new("Part")
    tower.Size = Vector3.new(8, 80, 8)
    tower.Position = building:GetPrimaryPartCFrame().Position + Vector3.new(0, 40, 0)
    tower.Parent = building
    
    -- Add windows
    for i = 1, 16 do
        local window = Instance.new("Part")
        window.Size = Vector3.new(2, 1, 2)
        window.Position = tower.Position + Vector3.new(0, i * 5, 0)
        window.BrickColor = BrickColor.new("Bright blue")
        window.Parent = building
    end
    
    -- Add antenna
    local antenna = Instance.new("Part")
    antenna.Size = Vector3.new(1, 10, 1)
    antenna.Position = tower.Position + Vector3.new(0, 85, 0)
    antenna.BrickColor = BrickColor.new("Neon green")
    antenna.Parent = building
end

function BuildingSystem:createFactory(building)
    -- Create factory structure
    local factory = Instance.new("Part")
    factory.Size = Vector3.new(30, 15, 30)
    factory.Position = building:GetPrimaryPartCFrame().Position + Vector3.new(0, 7.5, 0)
    factory.Parent = building
    
    -- Add smokestacks
    for i = -1, 1, 2 do
        local smokestack = Instance.new("Part")
        smokestack.Size = Vector3.new(2, 15, 2)
        smokestack.Position = factory.Position + Vector3.new(i * 10, 15, 0)
        smokestack.Parent = building
        
        -- Add smoke effect
        local smoke = Instance.new("ParticleEmitter")
        smoke.Rate = 15
        smoke.Lifetime = NumberRange.new(3, 5)
        smoke.Color = ColorSequence.new(Color3.fromRGB(100, 100, 100))
        smoke.Parent = smokestack
    end
    
    -- Add conveyor belt
    local conveyor = Instance.new("Part")
    conveyor.Size = Vector3.new(20, 1, 2)
    conveyor.Position = factory.Position + Vector3.new(0, 5, 0)
    conveyor.BrickColor = BrickColor.new("Bright yellow")
    conveyor.Parent = building
end

function BuildingSystem:createPowerPlant(building)
    -- Create main structure
    local plant = Instance.new("Part")
    plant.Size = Vector3.new(25, 20, 25)
    plant.Position = building:GetPrimaryPartCFrame().Position + Vector3.new(0, 10, 0)
    plant.Parent = building
    
    -- Add cooling towers
    for i = -1, 1, 2 do
        local tower = Instance.new("Part")
        tower.Size = Vector3.new(8, 30, 8)
        tower.Position = plant.Position + Vector3.new(i * 10, 35, 0)
        tower.Parent = building
        
        -- Add steam effect
        local steam = Instance.new("ParticleEmitter")
        steam.Rate = 20
        steam.Lifetime = NumberRange.new(4, 6)
        steam.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
        steam.Parent = tower
    end
    
    -- Add energy core
    local core = Instance.new("Part")
    core.Size = Vector3.new(10, 10, 10)
    core.Position = plant.Position + Vector3.new(0, 15, 0)
    core.BrickColor = BrickColor.new("Neon green")
    core.Parent = building
end

function BuildingSystem:createHospital(building)
    -- Create main structure
    local hospital = Instance.new("Part")
    hospital.Size = Vector3.new(20, 20, 20)
    hospital.Position = building:GetPrimaryPartCFrame().Position + Vector3.new(0, 10, 0)
    hospital.Parent = building
    
    -- Add cross sign
    local cross = Instance.new("Part")
    cross.Size = Vector3.new(5, 1, 5)
    cross.Position = hospital.Position + Vector3.new(0, 15, 0)
    cross.BrickColor = BrickColor.new("Bright red")
    cross.Parent = building
    
    -- Add medical supplies
    for i = -1, 1, 2 do
        local supply = Instance.new("Part")
        supply.Size = Vector3.new(3, 1, 3)
        supply.Position = hospital.Position + Vector3.new(i * 5, 5, 0)
        supply.BrickColor = BrickColor.new("Bright blue")
        supply.Parent = building
    end
end

function BuildingSystem:createMilitaryBase(building)
    -- Create main structure
    local base = Instance.new("Part")
    base.Size = Vector3.new(30, 15, 30)
    base.Position = building:GetPrimaryPartCFrame().Position + Vector3.new(0, 7.5, 0)
    base.Parent = building
    
    -- Add turrets
    for i = -1, 1, 2 do
        for j = -1, 1, 2 do
            local turret = Instance.new("Part")
            turret.Size = Vector3.new(2, 2, 2)
            turret.Position = base.Position + Vector3.new(i * 10, 15, j * 10)
            turret.BrickColor = BrickColor.new("Dark stone grey")
            turret.Parent = building
        end
    end
    
    -- Add radar dish
    local radar = Instance.new("Part")
    radar.Size = Vector3.new(10, 1, 10)
    radar.Position = base.Position + Vector3.new(0, 20, 0)
    radar.BrickColor = BrickColor.new("Bright blue")
    radar.Parent = building
end

function BuildingSystem:addSmokeEffect(building)
    local smoke = Instance.new("ParticleEmitter")
    smoke.Rate = 15
    smoke.Lifetime = NumberRange.new(3, 5)
    smoke.Color = ColorSequence.new(Color3.fromRGB(100, 100, 100))
    smoke.Parent = building
end

function BuildingSystem:addFireEffect(building)
    local fire = Instance.new("ParticleEmitter")
    fire.Rate = 20
    fire.Lifetime = NumberRange.new(2, 4)
    fire.Color = ColorSequence.new(Color3.fromRGB(255, 69, 0), Color3.fromRGB(255, 165, 0))
    fire.Parent = building
end

function BuildingSystem:addLightEffect(building)
    local light = Instance.new("PointLight")
    light.Range = 20
    light.Brightness = 2
    light.Color = Color3.fromRGB(255, 255, 255)
    light.Parent = building
end

function BuildingSystem:addEnergyEffect(building)
    local energy = Instance.new("ParticleEmitter")
    energy.Rate = 10
    energy.Lifetime = NumberRange.new(2, 4)
    energy.Color = ColorSequence.new(Color3.fromRGB(0, 255, 255))
    energy.Parent = building
end

function BuildingSystem:addMedicalEffect(building)
    local heal = Instance.new("ParticleEmitter")
    heal.Rate = 15
    heal.Lifetime = NumberRange.new(2, 4)
    heal.Color = ColorSequence.new(Color3.fromRGB(0, 255, 0))
    heal.Parent = building
end

return BuildingSystem
