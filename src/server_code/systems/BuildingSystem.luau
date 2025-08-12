--!strict
-- BuildingSystem.server.luau
-- Handles all building-related functionality in the game

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local BuildingSystem = {}
BuildingSystem.__index = BuildingSystem

-- Constants
local DAMAGE_COOLDOWN = 0.5 -- Seconds between damage applications
local REPAIR_COOLDOWN = 1.0 -- Seconds between repairs
local DAMAGE_COLOR = Color3.fromRGB(255, 0, 0)
local HEAL_COLOR = Color3.fromRGB(0, 255, 0)

-- Create RemoteEvents for client-server communication
local Events = Instance.new("Folder")
Events.Name = "BuildingEvents"
Events.Parent = ReplicatedStorage

local BuildingDamaged = Instance.new("RemoteEvent")
BuildingDamaged.Name = "BuildingDamaged"
BuildingDamaged.Parent = Events

local BuildingHealed = Instance.new("RemoteEvent")
BuildingHealed.Name = "BuildingHealed"
BuildingHealed.Parent = Events

local BuildingDestroyed = Instance.new("RemoteEvent")
BuildingDestroyed.Name = "BuildingDestroyed"
BuildingDestroyed.Parent = Events

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
        HEALTH = 1000,
        MAX_HEALTH = 1000,
        SIZE = Vector3.new(20, 100, 20),
        DAMAGE = 0,
        COST = 2000,
        COOLDOWN = 0,
        RANGE = 0,
        DESTRUCTIBLE = true,
        EFFECTS = {
            SMOKE = true,
            LIGHTS = true,
            DAMAGE_SMOKE = true
        },
        DAMAGE_STATES = {
            {healthPercent = 0.75, effects = {SMOKE = true}},
            {healthPercent = 0.5, effects = {SMOKE = true, DAMAGE_VISUAL = true}},
            {healthPercent = 0.25, effects = {SMOKE = true, DAMAGE_VISUAL = true, FIRE = true}}
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
        HEALTH = 800,
        MAX_HEALTH = 800,
        SIZE = Vector3.new(30, 20, 30),
        DAMAGE = 0,
        COST = 1500,
        COOLDOWN = 1,
        RANGE = 30,
        DESTRUCTIBLE = true,
        EFFECTS = {
            LIGHTS = true,
            HEALING_AURA = true
        },
        DAMAGE_STATES = {
            {healthPercent = 0.5, effects = {SMOKE = true}},
            {healthPercent = 0.2, effects = {SMOKE = true, DAMAGE_VISUAL = true}}
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
    
    -- Add health value
    local healthValue = Instance.new("NumberValue")
    healthValue.Name = "Health"
    healthValue.Value = buildingConfig.HEALTH
    healthValue.Parent = primaryPart
    
    -- Add max health value
    local maxHealthValue = Instance.new("NumberValue")
    maxHealthValue.Name = "MaxHealth"
    maxHealthValue.Value = buildingConfig.MAX_HEALTH or buildingConfig.HEALTH
    maxHealthValue.Parent = primaryPart
       
    -- Add building type attribute
    local typeAttr = Instance.new("StringValue")
    typeAttr.Name = "BuildingType"
    typeAttr.Value = buildingType
    typeAttr.Parent = primaryPart
    
    -- Add damage state
    local damageState = Instance.new("NumberValue")
    damageState.Name = "DamageState"
    damageState.Value = 0
    damageState.Parent = primaryPart
    
    -- Add to model
    primaryPart.Parent = model
    model.PrimaryPart = primaryPart
    
    -- Add to workspace
    local buildingsFolder = workspace:FindFirstChild("Buildings") or Instance.new("Folder")
    buildingsFolder.Name = "Buildings"
    buildingsFolder.Parent = workspace
    model.Parent = buildingsFolder
    
    -- Set model name with timestamp
    model.Name = string.format("%s_%d", buildingType, os.time())
    
    -- Create health bar
    self:_createHealthBar(model)
    
    return model :: ModelWithPrimaryPart
end

-- Internal: Create a health bar for a building
function BuildingSystem:_createHealthBar(building: Model)
    local primaryPart = building.PrimaryPart
    if not primaryPart then return end
    
    -- Create BillboardGui for health bar
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "BuildingHealthBar"
    billboard.Size = UDim2.new(5, 0, 0.5, 0)
    billboard.StudsOffset = Vector3.new(0, primaryPart.Size.Y/2 + 2, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 100
    
    -- Create background frame
    local background = Instance.new("Frame")
    background.Name = "Background"
    background.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    background.BorderSizePixel = 2
    background.BorderColor3 = Color3.fromRGB(20, 20, 20)
    background.Size = UDim2.new(1, 0, 1, 0)
    background.Parent = billboard
    
    -- Create health bar
    local healthBar = Instance.new("Frame")
    healthBar.Name = "HealthBar"
    healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    healthBar.BorderSizePixel = 0
    healthBar.Size = UDim2.new(1, 0, 1, 0)
    healthBar.Parent = background
    
    -- Add to building
    billboard.Parent = primaryPart
    
    -- Update health bar when health changes
    local healthValue = primaryPart:WaitForChild("Health")
    local maxHealthValue = primaryPart:WaitForChild("MaxHealth")
    
    local function updateHealthBar()
        local health = healthValue.Value
        local maxHealth = maxHealthValue.Value
        local healthPercent = math.clamp(health / maxHealth, 0, 1)
        
        -- Update health bar size and color
        healthBar.Size = UDim2.new(healthPercent, 0, 1, 0)
        
        -- Change color based on health percentage
        if healthPercent > 0.6 then
            healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0) -- Green
        elseif healthPercent > 0.3 then
            healthBar.BackgroundColor3 = Color3.fromRGB(255, 255, 0) -- Yellow
        else
            healthBar.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Red
        end
        
        -- Update damage state
        local damageState = 0
        local buildingConfig = self.BUILDING_TYPES[primaryPart:FindFirstChild("BuildingType").Value]
        if buildingConfig and buildingConfig.DAMAGE_STATES then
            for i, state in ipairs(buildingConfig.DAMAGE_STATES) do
                if healthPercent <= state.healthPercent then
                    damageState = i
                end
            end
        end
        
        -- Apply damage state effects
        if primaryPart:FindFirstChild("DamageState") then
            primaryPart.DamageState.Value = damageState
            self:_updateDamageEffects(building, damageState)
        end
    end
    
    -- Connect health changed event
    healthValue.Changed:Connect(updateHealthBar)
    updateHealthBar()
end

-- Internal: Update damage effects based on damage state
function BuildingSystem:_updateDamageEffects(building: Model, state: number)
    local primaryPart = building.PrimaryPart
    if not primaryPart then return end
    
    local buildingType = primaryPart:FindFirstChild("BuildingType")
    if not buildingType then return end
    
    local buildingConfig = self.BUILDING_TYPES[buildingType.Value]
    if not buildingConfig or not buildingConfig.DAMAGE_STATES then return end
    
    -- Clear existing effects
    for _, child in ipairs(primaryPart:GetChildren()) do
        if child:IsA("ParticleEmitter") or child:IsA("Fire") or child:IsA("Smoke") then
            child:Destroy()
        end
    end
    
    -- Apply effects for current and all previous damage states
    for i = 1, state do
        local stateData = buildingConfig.DAMAGE_STATES[i]
        if stateData and stateData.effects then
            for effectName, enabled in pairs(stateData.effects) do
                if enabled then
                    if effectName == "SMOKE" then
                        local smoke = Instance.new("Smoke")
                        smoke.Color = Color3.fromRGB(100, 100, 100)
                        smoke.Opacity = 0.8
                        smoke.RiseVelocity = 3
                        smoke.Size = 0.2
                        smoke.Parent = primaryPart
                    elseif effectName == "FIRE" then
                        local fire = Instance.new("Fire")
                        fire.Size = 8
                        fire.Heat = 5
                        fire.Parent = primaryPart
                    elseif effectName == "DAMAGE_VISUAL" then
                        -- Add cracks or other damage decals
                        local decal = Instance.new("Decal")
                        decal.Texture = "rbxassetid://2592362371" -- Crack texture
                        decal.Face = Enum.NormalId.Front
                        decal.Transparency = 0.5
                        decal.Parent = primaryPart
                    end
                end
            end
        end
    end
end

-- Internal: Apply visual effects to a building
function BuildingSystem:_applyBuildingEffects(building: ModelWithPrimaryPart, effects: {[string]: boolean}?)
    if not effects then return end
    
    for effectName, enabled in pairs(effects) do
        if not enabled then continue end
        
        if effectName == "SMOKE" then
            local smoke = Instance.new("Smoke")
            smoke.Color = Color3.fromRGB(200, 200, 200)
            smoke.Opacity = 0.3
            smoke.RiseVelocity = 2
            smoke.Size = 0.1
            smoke.Enabled = false -- Start disabled, enabled by damage state
            smoke.Parent = building.PrimaryPart
        elseif effectName == "LIGHTS" then
            local light = Instance.new("PointLight")
            light.Brightness = 1
            light.Range = 20
            light.Color = Color3.fromRGB(255, 255, 200)
            light.Parent = building.PrimaryPart
        elseif effectName == "HEALING_AURA" then
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
            aura.Rate = 5
            aura.Speed = NumberRange.new(2)
            aura.SpreadAngle = Vector2.new(0, 180)
            aura.Parent = building.PrimaryPart
        end
    end
end

-- Damage a building
function BuildingSystem:damageBuilding(building: Model, amount: number, attacker: Player?)
    if not building or not building:IsA("Model") then return false end
    
    local primaryPart = building.PrimaryPart
    if not primaryPart then return false end
    
    local healthValue = primaryPart:FindFirstChild("Health")
    local maxHealthValue = primaryPart:FindFirstChild("MaxHealth")
    if not healthValue or not maxHealthValue then return false end
    
    -- Apply damage
    local newHealth = math.max(0, healthValue.Value - amount)
    healthValue.Value = newHealth
    
    -- Fire damage event
    BuildingDamaged:FireAllClients(building, healthValue.Value, maxHealthValue.Value, attacker)
    
    -- Check if building is destroyed
    if newHealth <= 0 then
        self:destroyBuilding(building, attacker)
        return true
    end
    
    return false
end

-- Heal a building
function BuildingSystem:healBuilding(building: Model, amount: number, healer: Player?)
    if not building or not building:IsA("Model") then return false end
    
    local primaryPart = building.PrimaryPart
    if not primaryPart then return false end
    
    local healthValue = primaryPart:FindFirstChild("Health")
    local maxHealthValue = primaryPart:FindFirstChild("MaxHealth")
    if not healthValue or not maxHealthValue then return false end
    
    -- Apply healing (don't exceed max health)
    local newHealth = math.min(maxHealthValue.Value, healthValue.Value + amount)
    if newHealth > healthValue.Value then
        healthValue.Value = newHealth
        BuildingHealed:FireAllClients(building, healthValue.Value, maxHealthValue.Value, healer)
        return true
    end
    
    return false
end

-- Destroy a building
function BuildingSystem:destroyBuilding(building: Model, destroyer: Player?)
    if not building or not building:IsA("Model") then return end
    
    local primaryPart = building.PrimaryPart
    if not primaryPart then return end
    
    -- Fire destroyed event
    BuildingDestroyed:FireAllClients(building, destroyer)
    
    -- Create explosion effect
    local explosion = Instance.new("Explosion")
    explosion.Position = primaryPart.Position
    explosion.BlastRadius = 10
    explosion.BlastPressure = 500000
    explosion.DestroyJointRadiusPercent = 0
    explosion.Parent = workspace
    
    -- Remove building after a delay
    task.delay(0.1, function()
        building:Destroy()
    end)
    
    return true
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

-- Create global instance
local buildingSystem = BuildingSystem.new()

-- Module exports
return buildingSystem
