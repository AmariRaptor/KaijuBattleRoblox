--!strict
-- BuildingSystem.server.luau
-- Handles all building-related functionality in the game

local BuildingSystem = {}
BuildingSystem.__index = BuildingSystem

-- Services (commented out until needed)
-- local _ReplicatedStorage = game:GetService("ReplicatedStorage")
-- local _ServerStorage = game:GetService("ServerStorage")
-- local _Players = game:GetService("Players")

-- Services (commented out until needed)
-- local _ReplicatedStorage = game:GetService("ReplicatedStorage")
-- local _ServerStorage = game:GetService("ServerStorage")
-- local _Players = game:GetService("Players")

-- Types
type ModelWithPrimaryPart = Model & {
    PrimaryPart: BasePart,
    Destroying: RBXScriptSignal<() -> ()>
}

type BuildingType = {
    HEALTH: number,
    SIZE: Vector3,
    DAMAGE: number,
    COST: number,
    COOLDOWN: number,
    RANGE: number,
    EFFECTS: {[string]: boolean},
    init: (() -> ())?,
    onBuilt: ((self: BuildingType, model: Model) -> ())?,
    onDestroyed: ((self: BuildingType, model: Model) -> ())?,
    onUpdate: ((self: BuildingType, model: Model, dt: number) -> ())?,
    canBuild: ((self: BuildingType, position: Vector3) -> (boolean, string?))?,
    _applyBuildingEffects: (self: BuildingType, model: Model, effects: {[string]: boolean}) -> ()
}

type Building = {
    id: string,
    model: ModelWithPrimaryPart,
    buildingType: string,
    health: number,
    maxHealth: number,
    owner: Player,
    position: Vector3,
    isDestroyed: boolean,
    lastDamageTime: number,
    lastRepairTime: number,
    effects: {[string]: boolean},
    
    update: (self: Building, deltaTime: number) -> (),
    destroy: (self: Building) -> (),
    repair: (self: Building, amount: number) -> (),
    damage: (self: Building, amount: number) -> (),
    getHealthPercentage: (self: Building) -> number,
    addEffect: (self: Building, effectName: string) -> (),
    removeEffect: (self: Building, effectName: string) -> (),
    hasEffect: (self: Building, effectName: string) -> boolean
}

type BuildingSystem = {
    buildings: {[string]: Building},
    BUILDING_TYPES: {[string]: BuildingType},
    init: (self: BuildingSystem) -> (),
    createBuilding: (self: BuildingSystem, buildingType: string, position: Vector3, owner: Player) -> Building?,
    updateAll: (self: BuildingSystem, deltaTime: number) -> (),
    _createBuildingModel: (self: BuildingSystem, buildingType: string, position: Vector3) -> ModelWithPrimaryPart,
    _applyBuildingEffects: (self: BuildingSystem, model: ModelWithPrimaryPart, effects: {[string]: boolean}) -> ()
}

local BuildingSystemImpl = {}
BuildingSystemImpl.__index = BuildingSystemImpl

local _BUILDING_TYPES = {
    SKYSCRAPER = {
        HEALTH = 200,
        SIZE = Vector3.new(10, 50, 10),
        DAMAGE = 5,
        COST = 100,
        COOLDOWN = 10,
        RANGE = 20,
        EFFECTS = {
            SMOKE = true,
            LIGHTS = true
        },
        _applyBuildingEffects = function(self: BuildingType, model: Model, effects: {[string]: boolean})
            for effectName, enabled in pairs(effects) do
                if not enabled then continue end
                
                if effectName == "SMOKE" then
                    local smoke = Instance.new("Smoke")
                    smoke.Color = Color3.fromRGB(200, 200, 200)
                    smoke.Opacity = 0.5
                    smoke.RiseVelocity = 5
                    smoke.Size = 5
                    smoke.Parent = model.PrimaryPart
                elseif effectName == "LIGHTS" then
                    local light = Instance.new("PointLight")
                    light.Brightness = 1
                    light.Range = 20
                    light.Color = Color3.fromRGB(255, 255, 200)
                    light.Parent = model.PrimaryPart
                end
            end
        end
    },
    
    HOSPITAL = {
        HEALTH = 150,
        SIZE = Vector3.new(20, 15, 20),
        DAMAGE = 0,
        COST = 150,
        COOLDOWN = 15,
        RANGE = 25,
        EFFECTS = {
            LIGHTS = true,
            HEALING_AURA = true
        },
        _applyBuildingEffects = function(self: BuildingType, model: Model, effects: {[string]: boolean})
            for effectName, enabled in pairs(effects) do
                if not enabled then continue end
                
                if effectName == "LIGHTS" then
                    local light = Instance.new("PointLight")
                    light.Brightness = 1
                    light.Range = 20
                    light.Color = Color3.fromRGB(255, 255, 200)
                    light.Parent = model.PrimaryPart
                elseif effectName == "HEALING_AURA" then
                    -- Add healing aura effect
                    local aura = Instance.new("ParticleEmitter")
                    aura.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 0)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 255, 200))
                    })
                    aura.LightEmission = 0.8
                    aura.LightInfluence = 0
                    aura.Size = NumberSequence.new(2)
                    aura.Texture = "rbxassetid://296874871"
                    aura.Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0.5),
                        NumberSequenceKeypoint.new(1, 1)
                    })
                    aura.Lifetime = NumberRange.new(1, 2)
                    aura.Rate = 10
                    aura.Speed = NumberRange.new(2)
                    aura.SpreadAngle = Vector2.new(0, 180)
                    aura.Parent = model.PrimaryPart
                end
            end
        end
    }
}

-- Constructor (kept for backward compatibility)
function BuildingSystem.new()
    local self = setmetatable({
        buildings = {},
        BUILDING_TYPES = _BUILDING_TYPES
    }, BuildingSystem)
    
    -- Initialize the system
    self:init()
    
    return self
end

-- Standardized init method
function BuildingSystem:init()
    print("🔄 Initializing BuildingSystem...")
    
    -- Set up buildings folder
    if not workspace:FindFirstChild("Buildings") then
        local buildingsFolder = Instance.new("Folder")
        buildingsFolder.Name = "Buildings"
        buildingsFolder.Parent = workspace
    end
    
    -- Initialize building types
    for _, buildingType in pairs(self.BUILDING_TYPES) do
        if type(buildingType) == "table" and buildingType.init then
            buildingType:init()
        end
    end
    
    print("✅ BuildingSystem initialized successfully")
    return true
end

-- Create a new building
function BuildingSystemImpl:createBuilding(buildingType: string, position: Vector3, owner: Player): Building?
    local buildingTypeConfig = self.BUILDING_TYPES[buildingType]
    if not buildingTypeConfig then
        warn("Invalid building type:", buildingType)
        return nil
    end
    
    -- Create the building model
    local buildingModel = self:_createBuildingModel(buildingType, position)
    
    -- Create the building object
    local building = buildingTypeConfig.create(buildingTypeConfig, buildingModel)
    
    -- Apply building effects
    self:_applyBuildingEffects(buildingModel, buildingTypeConfig.EFFECTS)
    
    -- Store the building
    self.buildings[building.id] = building
    
    -- Set up destruction handler
    buildingModel.Destroying:Connect(function()
        self.buildings[building.id] = nil
    end)
    
    return building
end

-- Internal: Create a building model
function BuildingSystem:_createBuildingModel(buildingType: string, position: Vector3): ModelWithPrimaryPart
    local buildingConfig = self.BUILDING_TYPES[buildingType]
    if not buildingConfig then
        error("Invalid building type: " .. tostring(buildingType))
    end
    
    local model = Instance.new("Model")
    local primaryPart = Instance.new("Part")
    
    -- Configure the primary part
    primaryPart.Name = "PrimaryPart"
    primaryPart.Size = buildingConfig.SIZE
    primaryPart.Position = position
    primaryPart.Anchored = true
    primaryPart.CanCollide = true
    primaryPart.Parent = model
    
    -- Set the primary part
    model.PrimaryPart = primaryPart
    
    -- Add to workspace
    local buildingsFolder = workspace:FindFirstChild("Buildings") or Instance.new("Folder")
    buildingsFolder.Name = "Buildings"
    buildingsFolder.Parent = workspace
    model.Parent = buildingsFolder
    
    -- Set model name
    model.Name = buildingType .. "_" .. tostring(os.time())
    
    return model :: ModelWithPrimaryPart
end

-- Internal: Apply visual effects to a building
function BuildingSystem:_applyBuildingEffects(building: ModelWithPrimaryPart, effects: {[string]: boolean})
    for effectName, enabled in pairs(effects) do
        if not enabled then continue end
        
        if effectName == "SMOKE" then
            local smoke = Instance.new("Smoke")
            smoke.Color = Color3.fromRGB(200, 200, 200)
            smoke.Opacity = 0.5
            smoke.RiseVelocity = 5
            smoke.Size = 5
            smoke.Parent = building.PrimaryPart
        elseif effectName == "LIGHTS" then
            local light = Instance.new("PointLight")
            light.Brightness = 1
            light.Range = 20
            light.Color = Color3.fromRGB(255, 255, 200)
            light.Parent = building.PrimaryPart
        elseif effectName == "HEALING_AURA" then
            -- Add healing aura effect
            local aura = Instance.new("ParticleEmitter")
            aura.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 0)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 255, 200))
            })
            aura.LightEmission = 0.8
            aura.LightInfluence = 0
            aura.Size = NumberSequence.new(2)
            aura.Texture = "rbxassetid://296874871"
            aura.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.5),
                NumberSequenceKeypoint.new(1, 1)
            })
            aura.Lifetime = NumberRange.new(1, 2)
            aura.Rate = 10
            aura.Speed = NumberRange.new(2)
            aura.SpreadAngle = Vector2.new(0, 180)
            aura.Parent = building.PrimaryPart
        end
    end
end

-- Constructor (kept for backward compatibility)
function BuildingSystem.new()
    local self = setmetatable({}, BuildingSystem)
    
    -- Initialize properties
    self.buildings = {}
    self.BUILDING_TYPES = _BUILDING_TYPES
    
    -- Set up any necessary connections or initialization here
    
    return self
end

-- Standardized init method
function BuildingSystem:init()
    print("🔄 Initializing BuildingSystem...")
    
    -- Create buildings folder if it doesn't exist
    if not workspace:FindFirstChild("Buildings") then
        local buildingsFolder = Instance.new("Folder")
        buildingsFolder.Name = "Buildings"
        buildingsFolder.Parent = workspace
    end
    
    -- Any additional initialization logic here
    
    print("✅ BuildingSystem initialized successfully")
    return true
end

-- Module exports
return BuildingSystem
