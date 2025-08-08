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
} :: {string}

--[[
    Assigns a random class to a player.
    @param player The player to assign a class to.
    @return string The class that was assigned.
]]
function ClassSystem.assignRandomClass(player: Player): string
    -- Remove existing class if it exists
    local existingClass = player:FindFirstChild("PlayerClass")
    if existingClass and existingClass:IsA("StringValue") then
        existingClass:Destroy()
    end
    
    -- Create a value to store the player's class
    local playerClass = Instance.new("StringValue")
    playerClass.Name = "PlayerClass"
    
    -- Assign a random class
    local randomIndex = math.random(1, #CLASSES)
    local className = CLASSES[randomIndex] :: string
    playerClass.Value = className
    playerClass.Parent = player

    print(string.format("%s has been assigned the class: %s", player.Name, className))
    return className
end

--[[
    Called when a player is added to the game.
    @param player The player who joined.
]]
local function onPlayerAdded(player: Player)
    -- Assign a random class to the player
    ClassSystem.assignRandomClass(player)
    
    -- TODO: Connect to character added to give tools/abilities
end

--[[
    Initializes the ClassSystem.
    @return boolean True if initialization was successful
]]
function ClassSystem.init()
    -- Connect to player joining event
    Players.PlayerAdded:Connect(onPlayerAdded)
    
    -- Initialize existing players
    for _, player in ipairs(Players:GetPlayers() :: {Player}) do
        task.spawn(onPlayerAdded, player)
    end
    
    return true -- Indicate successful initialization
end

return ClassSystem
