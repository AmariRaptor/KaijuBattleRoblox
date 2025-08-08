--!strict
-- CharacterSystem.server.luau
-- Handles character initialization and class-based attributes for players

-- Services
local Players = game:GetService("Players")

-- Types
type CharacterAttributes = {
    MaxHealth: number,
    WalkSpeed: number,
    JumpPower: number,
    Abilities: {string}?
}

type CharacterSystem = {
    init: () -> (),
    onPlayerAdded: (player: Player) -> (),
    onCharacterAdded: (character: Model) -> (),
    getClassAttributes: (className: string) -> CharacterAttributes?
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

local CharacterSystem: CharacterSystem = {}
CharacterSystem.__index = CharacterSystem

--[[
    Gets the attributes for a specific class.
    @param className string The name of the class to get attributes for.
    @return CharacterAttributes? The attributes for the class, or nil if not found.
]]
function CharacterSystem.getClassAttributes(className: string): CharacterAttributes?
    return Config.Classes[className]
end

--[[
    Sets up a character when it is added to the game.
    @param character Model The character model that was added.
]]
function CharacterSystem.onCharacterAdded(character: Model)
    local player = Players:GetPlayerFromCharacter(character)
    if not player then
        warn("Character added without a valid player")
        return
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        warn("Character has no Humanoid")
        return
    end

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

    -- Apply class attributes
    humanoid.MaxHealth = attributes.MaxHealth
    humanoid.Health = attributes.MaxHealth
    humanoid.WalkSpeed = attributes.WalkSpeed
    humanoid.JumpPower = attributes.JumpPower

    -- Add class tag for identification
    local classTag = character:FindFirstChild("ClassTag") or Instance.new("StringValue")
    classTag.Name = "ClassTag"
    classTag.Value = className
    classTag.Parent = character

    print(string.format(
        "%s's character created. Class: %s, MaxHealth: %d, WalkSpeed: %d, JumpPower: %d",
        player.Name,
        className,
        humanoid.MaxHealth,
        humanoid.WalkSpeed,
        humanoid.JumpPower
    ))
end

--[[
    Connects the CharacterAdded event for a given player.
    @param player Player The player to connect the event for.
]]
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

--[[
    Initializes the CharacterSystem.
]]
--[[
    Initializes the CharacterSystem.
    @return boolean True if initialization was successful
]]
function CharacterSystem.init()
    -- Connect to all current and future players
    Players.PlayerAdded:Connect(CharacterSystem.onPlayerAdded)
    
    -- Set up existing players
    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(CharacterSystem.onPlayerAdded, player)
    end
    
    print("CharacterSystem initialized")
    return true -- Indicate successful initialization
end

return CharacterSystem
