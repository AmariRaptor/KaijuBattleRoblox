--!strict
-- KaijuSystem.server.luau
-- Handles Kaiju-specific functionality and abilities

-- Services
local _ReplicatedStorage = game:GetService("ReplicatedStorage")
local _Players = game:GetService("Players")

-- Types
type KaijuAbilities = {
    energyBeam: RemoteEvent,
    roar: Sound,
    roarEvent: RemoteEvent
}

local KaijuSystem = {}
KaijuSystem.__index = KaijuSystem

-- Default configuration (will be overridden by GameConfig if available)
local Config = {
    Kaiju = {
        Size = Vector3.new(10, 5, 10),
        BaseHealth = 500,
        Abilities = {
            Roar = {
                SoundId = "123456789"
            }
        }
    },
    Classes = {
        Kaiju = {
            WalkSpeed = 24,
            JumpPower = 50
        }
    }
}

-- Try to load GameConfig, but don't fail if it doesn't exist
local success, gameConfig = pcall(function()
    return require(script.Parent.Parent.Parent.shared.config.GameConfig)
end)

if success and gameConfig then
    Config = gameConfig
end

-- Private functions
local function validatePlayer(player: Player): (boolean, string?)
    if not player or not player:IsA("Player") then
        return false, "Invalid player"
    end
    return true
end

local function createKaijuModel(): Model
    local kaiju = Instance.new("Model")
    kaiju.Name = "Kaiju"
    
    -- Add hitbox (torso)
    local hitbox = Instance.new("Part")
    hitbox.Name = "HumanoidRootPart"
    hitbox.Size = Config.Kaiju.Size
    hitbox.Position = Vector3.new(0, Config.Kaiju.Size.Y / 2 + 5, 0)
    hitbox.Anchored = false
    hitbox.CanCollide = true
    hitbox.Massless = false
    hitbox.Parent = kaiju
    
    -- Add humanoid with configurable stats
    local humanoid = Instance.new("Humanoid")
    humanoid.MaxHealth = Config.Kaiju.BaseHealth
    humanoid.Health = humanoid.MaxHealth
    humanoid.WalkSpeed = Config.Classes.Kaiju.WalkSpeed
    humanoid.JumpPower = Config.Classes.Kaiju.JumpPower
    humanoid.Parent = kaiju
    
    -- Add tag for identification
    local tag = Instance.new("StringValue")
    tag.Name = "KaijuTag"
    tag.Value = "true"
    tag.Parent = kaiju
    
    return kaiju
end

-- Constructor (kept for backward compatibility)
function KaijuSystem.new()
    local self = setmetatable({}, KaijuSystem)
    
    -- Initialize the system
    self:init()
    
    return self
end

-- Standardized init method
function KaijuSystem:init()
    print("🔄 Initializing KaijuSystem...")
    
    -- Initialize any necessary properties
    self.players = {}
    
    -- Set up any event connections here
    
    print("✅ KaijuSystem initialized successfully")
    return true
end

function KaijuSystem:spawnKaiju(player: Player): Model
    local success, errorMsg = validatePlayer(player)
    if not success then
        error(errorMsg or "Failed to spawn Kaiju")
    end
    
    local character = player.Character or player.CharacterAdded:Wait()
    
    -- Clean up existing Kaiju if it exists
    local existingKaiju = character:FindFirstChild("Kaiju")
    if existingKaiju then
        existingKaiju:Destroy()
    end
    
    -- Create and set up new Kaiju
    local kaiju = createKaijuModel()
    kaiju.Parent = character
    
    -- Set up abilities
    self:setupAbilities(kaiju)
    
    return kaiju
end

function KaijuSystem:setupAbilities(kaiju: Model): KaijuAbilities
    if not kaiju or not kaiju:IsA("Model") then
        error("Invalid Kaiju model provided")
    end
    
    -- Energy beam ability
    local energyBeam = Instance.new("RemoteEvent")
    energyBeam.Name = "EnergyBeam"
    energyBeam.Parent = kaiju
    
    -- Set up energy beam handler
    energyBeam.OnServerEvent:Connect(function(player: Player, targetPosition: Vector3)
        self:onAbilityUsed(player, "EnergyBeam", {target = targetPosition})
    end)
    
    -- Roar ability
    local roar = Instance.new("Sound")
    roar.Name = "Roar"
    roar.SoundId = "rbxassetid://" .. Config.Kaiju.Abilities.Roar.SoundId or ""
    roar.Volume = 1
    roar.Parent = kaiju
    
    -- Set up roar handler
    local roarEvent = Instance.new("RemoteEvent")
    roarEvent.Name = "RoarEvent"
    roarEvent.Parent = kaiju
    
    roarEvent.OnServerEvent:Connect(function(player: Player, ...: any)
        self:onAbilityUsed(player, "Roar", ...)
    end)
    
    return {
        energyBeam = energyBeam,
        roar = roar,
        roarEvent = roarEvent
    }
end

function KaijuSystem:onAbilityUsed(player: Player, abilityName: string, abilityData: {[string]: any}?)
    if not player or not player.Character then 
        warn("Invalid player or character for ability use:", player, abilityName)
        return 
    end
    
    local kaiju = player.Character:FindFirstChild("Kaiju")
    if not kaiju then 
        warn("No Kaiju model found for player:", player.Name)
        return 
    end
    
    -- Handle different abilities
    if abilityName == "EnergyBeam" then
        self:handleEnergyBeam(player, kaiju, abilityData or {})
    elseif abilityName == "Roar" then
        self:handleRoar(player, kaiju, abilityData or {})
    else
        warn("Unknown ability:", abilityName)
    end
end

function KaijuSystem:handleEnergyBeam(player: Player, kaiju: Model, data: {target: Vector3})
    -- Implement energy beam logic
    print(string.format("%s used EnergyBeam at position: %s", player.Name, tostring(data.target)))
    -- TODO: Add cooldown, damage calculation, and visual effects
end

function KaijuSystem:handleRoar(player: Player, kaiju: Model, data: {})
    -- Implement roar logic
    print(string.format("%s used Roar", player.Name))
    
    -- Play roar sound if it exists
    local roarSound = kaiju:FindFirstChild("Roar")
    if roarSound and roarSound:IsA("Sound") then
        roarSound:Play()
    end
    
    -- TODO: Add cooldown and area effect logic
end

return KaijuSystem
