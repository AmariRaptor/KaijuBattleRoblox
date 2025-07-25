--!strict

--[[
    @class CharacterSystem
    @server

    Handles setting up player characters based on their assigned class,
    including attributes like health and abilities.
]]
local CharacterSystem = {}

local Players = game:GetService("Players")

-- Define base attributes for each class
-- This can be expanded with speed, damage multipliers, etc.
local CLASS_ATTRIBUTES = {
    Kaiju = {
        MaxHealth = 500
    },
    Guardian = {
        MaxHealth = 200
    },
    Engineer = {
        MaxHealth = 150
    }
}

--[[
    Sets up a character when it is added to the game.
    @param character Model The character model that was added.
]]
function CharacterSystem.onCharacterAdded(character: Model)
    local player = Players:GetPlayerFromCharacter(character)
    if not player then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    local playerClassValue = player:FindFirstChild("PlayerClass")
    if not playerClassValue or not playerClassValue:IsA("StringValue") then return end

    local attributes = CLASS_ATTRIBUTES[playerClassValue.Value]
    if not attributes then return end

    -- Set health based on class
    humanoid.MaxHealth = attributes.MaxHealth
    humanoid.Health = attributes.MaxHealth

    print(player.Name .. "'s character created. Class: " .. playerClassValue.Value .. ", MaxHealth: " .. tostring(humanoid.MaxHealth))
end

--[[
    Connects the CharacterAdded event for a given player.
    @param player Player The player to connect the event for.
]]
function CharacterSystem.onPlayerAdded(player: Player)
    player.CharacterAdded:Connect(CharacterSystem.onCharacterAdded)
    -- If character already exists, set it up
    if player.Character then
        CharacterSystem.onCharacterAdded(player.Character)
    end
end

--[[
    Initializes the CharacterSystem.
]]
function CharacterSystem.init()
    -- Connect to all current and future players
    Players.PlayerAdded:Connect(CharacterSystem.onPlayerAdded)
    for _, player in ipairs(Players:GetPlayers()) do
        CharacterSystem.onPlayerAdded(player)
    end
end

return CharacterSystem
