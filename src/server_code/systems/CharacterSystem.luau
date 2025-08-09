--!strict
-- CharacterSystem.server.luau
-- Handles character initialization and class-based attributes for players,
-- plus server-side player state (health, energy, cooldowns, ultimate) and validation.

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Types
type CharacterAttributes = {
    MaxHealth: number,
    WalkSpeed: number,
    JumpPower: number,
    Abilities: {string}?,
}

type PlayerState = {
    maxHealth: number,
    health: number,
    energy: number,
    ultimate: number,
    cooldowns: { [string]: number }?,
    className: string,
    alive: boolean,
}

type CharacterSystem = {
    init: () -> boolean,
    onPlayerAdded: (player: Player) -> (),
    onCharacterAdded: (character: Model) -> (),
    getClassAttributes: (className: string) -> CharacterAttributes?,
    getPlayerState: (player: Player) -> PlayerState?,
    validateAbilityUse: (player: Player, abilityName: string) -> (boolean, string?),
}

-- Default configuration (will be overridden by GameConfig if available)
local Config = {
    Classes = {
        Kaiju = {
            MaxHealth = 500,
            WalkSpeed = 24,
            JumpPower = 50,
            Abilities = {"Smash", "Charge", "Roar"}
        },
        Guardian = {
            MaxHealth = 200,
            WalkSpeed = 16,
            JumpPower = 50,
            Abilities = {"ShieldBash", "Taunt", "Rally"}
        },
        Engineer = {
            MaxHealth = 150,
            WalkSpeed = 18,
            JumpPower = 50,
            Abilities = {"Repair", "Turret", "SpeedBoost"}
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

-- Player state storage
local playerStates: { [string]: PlayerState } = {}

-- Heartbeat connection for energy regen & cooldown ticks
local _heartbeatConn: RBXScriptConnection?

local CharacterSystem: any = {}
CharacterSystem.__index = CharacterSystem

-- Helper: get abilities config defaults
local function getAbilitiesConfig()
    if success and gameConfig and gameConfig.Abilities then
        return gameConfig.Abilities
    end
    -- fallback defaults
    return {
        EnergyMax = 100,
        EnergyRegen = 8,
        UltimateThreshold = 100,
        UltimateGainPerDamage = 0.5,
        Defaults = {},
    }
end

--[[
    Gets the attributes for a specific class.
    @param className string The name of the class to get attributes for.
    @return CharacterAttributes? The attributes for the class, or nil if not found.
]]
function CharacterSystem.getClassAttributes(className: string): CharacterAttributes?
    -- Config may be a full GameConfig when loaded; support both shapes
    if Config and Config.Classes and Config.Classes[className] then
        return Config.Classes[className] :: CharacterAttributes
    end
    return nil
end

-- Internal helper: initialize server-side player state
local function initializePlayerState(player: Player)
    if not player then return end
    local uid = tostring(player.UserId)

    local playerClassValue = player:FindFirstChild("PlayerClass")
    local className = "Guardian"
    if playerClassValue and playerClassValue:IsA("StringValue") then
        className = playerClassValue.Value
    end

    local attributes = CharacterSystem.getClassAttributes(className)
    local maxHealth = (attributes and attributes.MaxHealth) or 100

    local abilitiesCfg = getAbilitiesConfig()
    local energyMax = abilitiesCfg.EnergyMax or 100

    local state: PlayerState = {
        maxHealth = maxHealth,
        health = maxHealth,
        energy = energyMax,
        ultimate = 0,
        cooldowns = {},
        className = className,
        alive = true,
    }

    playerStates[uid] = state
end

-- Public: get server-side player state
function CharacterSystem.getPlayerState(player: Player): PlayerState?
    if not player then return nil end
    local uid = tostring(player.UserId)
    return playerStates[uid]
end

-- Validates and applies the cost/cooldown for an ability use.
-- Returns (true, nil) if valid and applied; otherwise (false, reason).
function CharacterSystem.validateAbilityUse(player: Player, abilityName: string): (boolean, string?)
    if not player then return false, "Invalid player" end
    local state = CharacterSystem.getPlayerState(player)
    if not state then return false, "No player state" end
    if not state.alive then return false, "Player is not alive" end

    local abilitiesCfg = getAbilitiesConfig()
    local def = (abilitiesCfg.Defaults and abilitiesCfg.Defaults[abilityName]) or nil
    local cost = (def and def.Cost) or 0
    local cooldown = (def and def.Cooldown) or 0

    if state.energy < cost then
        return false, "Not enough energy"
    end

    local remaining = state.cooldowns and state.cooldowns[abilityName] or 0
    if remaining > 0 then
        return false, "Ability on cooldown"
    end

    -- Apply cost and cooldown
    state.energy = math.max(0, state.energy - cost)
    if cooldown > 0 then
        state.cooldowns[abilityName] = cooldown
    end

    return true, nil
end

-- Called when a character Model is added for a player.
function CharacterSystem.onCharacterAdded(character: Model)
    local player = Players:GetPlayerFromCharacter(character)
    if not player then
        warn("Character added without a valid player")
        return
    end

    local humanoidInst = character:FindFirstChildOfClass("Humanoid")
    if not humanoidInst or not humanoidInst:IsA("Humanoid") then
        warn("Character has no Humanoid")
        return
    end
    local humanoid = humanoidInst :: Humanoid

    local playerClassValue = player:FindFirstChild("PlayerClass")
    if not playerClassValue or not playerClassValue:IsA("StringValue") then
        warn("Player has no valid PlayerClass")
        return
    end

    local className = playerClassValue.Value
    local attributes = CharacterSystem.getClassAttributes(className)

    if not attributes then
        warn(string.format("No attributes found for class: %s", className))
        return
    end

    -- Apply class attributes to humanoid
    humanoid.MaxHealth = attributes.MaxHealth
    humanoid.Health = attributes.MaxHealth
    humanoid.WalkSpeed = attributes.WalkSpeed
    humanoid.JumpPower = attributes.JumpPower

    -- Update server-side state if present
    local state = CharacterSystem.getPlayerState(player)
    if not state then
        initializePlayerState(player)
        state = CharacterSystem.getPlayerState(player)
    end
    if state then
        state.maxHealth = attributes.MaxHealth
        state.health = attributes.MaxHealth
        state.className = className
        state.alive = true
    end

    -- Add class tag for identification (ensure proper StringValue type)
    local existingTag = character:FindFirstChild("ClassTag")
    if existingTag and existingTag:IsA("StringValue") then
        existingTag.Value = className
    else
        -- Remove non-StringValue tags if present, then create proper StringValue
        if existingTag then
            existingTag:Destroy()
        end
        local newTag = Instance.new("StringValue")
        newTag.Name = "ClassTag"
        newTag.Value = className
        newTag.Parent = character
    end

    -- Keep server state in sync with humanoid health
    humanoid.HealthChanged:Connect(function(newHealth: number)
        local s = CharacterSystem.getPlayerState(player)
        if s then
            s.health = newHealth
            if newHealth <= 0 then
                s.alive = false
            end
        end
    end)

    print(string.format(
        "%s's character created. Class: %s, MaxHealth: %d, WalkSpeed: %d, JumpPower: %d",
        player.Name,
        className,
        humanoid.MaxHealth,
        humanoid.WalkSpeed,
        humanoid.JumpPower
    ))
end

-- Connects the CharacterAdded event for a given player.
function CharacterSystem.onPlayerAdded(player: Player)
    if not player or not player:IsA("Player") then
        warn("Invalid player provided to onPlayerAdded")
        return
    end

    -- Set up PlayerClass if it doesn't exist
    if not player:FindFirstChild("PlayerClass") then
        local playerClass = Instance.new("StringValue")
        playerClass.Name = "PlayerClass"
        playerClass.Value = "Guardian" -- Default class
        playerClass.Parent = player
    end

    -- Initialize server-side player state
    initializePlayerState(player)

    -- Connect character added event
    player.CharacterAdded:Connect(function(character)
        task.wait() -- Wait for character to fully load
        CharacterSystem.onCharacterAdded(character)
    end)

    -- Set up existing character if it exists
    if player.Character then
        task.defer(function()
            CharacterSystem.onCharacterAdded(player.Character)
        end)
    end
end

-- Initializes the CharacterSystem.
function CharacterSystem.init(): boolean
    -- Connect to all current and future players
    Players.PlayerAdded:Connect(CharacterSystem.onPlayerAdded)

    -- Clean up state when players leave
    Players.PlayerRemoving:Connect(function(player)
        if player then
            playerStates[tostring(player.UserId)] = nil
        end
    end)

    -- Set up existing players
    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(CharacterSystem.onPlayerAdded, player)
    end

    -- Heartbeat: energy regen and cooldown ticking
    local abilitiesCfg = getAbilitiesConfig()
    local energyRegen = abilitiesCfg.EnergyRegen or 8

    _heartbeatConn = RunService.Heartbeat:Connect(function(dt: number)
        for uid, st in pairs(playerStates) do
            if st and st.alive then
                -- Energy regen
                local maxE = abilitiesCfg.EnergyMax or 100
                st.energy = math.min(maxE, (st.energy or 0) + energyRegen * dt)

                -- Cooldown ticks
                if st.cooldowns then
                    for ability, timeLeft in pairs(st.cooldowns) do
                        local newTime = math.max(0, timeLeft - dt)
                        if newTime <= 0 then
                            st.cooldowns[ability] = nil
                        else
                            st.cooldowns[ability] = newTime
                        end
                    end
                end
            end
        end
    end)

    print("CharacterSystem initialized")
    return true
end

return CharacterSystem
