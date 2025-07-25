--!strict

--[[
    @class ClassSystem
    @server

    Handles assigning classes (Kaiju, Guardian, Engineer) to players
    and managing class-specific abilities and attributes.
]]
local ClassSystem = {}

local Players = game:GetService("Players")

-- For now, we'll define the classes in a simple table.
-- This could be expanded into separate modules later.
local CLASSES = {
    "Kaiju",
    "Guardian",
    "Engineer"
}

--[[
    Assigns a random class to a player when they join.
    @param player Player The player who joined the game.
]]
function ClassSystem.onPlayerAdded(player: Player)
    -- Create a value to store the player's class
    local playerClass = Instance.new("StringValue")
    playerClass.Name = "PlayerClass"
    
    -- Assign a random class for now
    local randomIndex = math.random(1, #CLASSES)
    playerClass.Value = CLASSES[randomIndex]
    playerClass.Parent = player

    print(player.Name .. " has been assigned the class: " .. playerClass.Value)

    -- TODO: Connect to character added to give tools/abilities
end

--[[
    Initializes the ClassSystem.
]]
function ClassSystem.init()
    -- Connect to player joining event
    Players.PlayerAdded:Connect(ClassSystem.onPlayerAdded)

    -- Handle players who are already in the game
    for _, player in ipairs(Players:GetPlayers()) do
        ClassSystem.onPlayerAdded(player)
    end
end

return ClassSystem
