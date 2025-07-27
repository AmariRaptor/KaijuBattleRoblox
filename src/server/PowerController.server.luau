--!strict
-- PowerController.server.luau
-- Handles power activation and cooldowns on the server

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Import the PowerSystem
local PowerSystem = require(ReplicatedStorage:WaitForChild("PowerSystem"))

-- Remote events for client-server communication
local PowerEvents = Instance.new("Folder")
PowerEvents.Name = "PowerEvents"

local PowerActivated = Instance.new("RemoteEvent")
PowerActivated.Name = "PowerActivated"
PowerActivated.Parent = PowerEvents

local PowerCooldown = Instance.new("RemoteEvent")
PowerCooldown.Name = "PowerCooldown"
PowerCooldown.Parent = PowerEvents

PowerEvents.Parent = ReplicatedStorage

-- Class to power mappings
local CLASS_POWERS = {
    Kaiju = {
        "Roar",
        "Stomp",
        "TailWhip"
    },
    Guardian = {
        "ShieldBash",
        "ProtectiveAura",
        "HealingWave"
    },
    Engineer = {
        "TurretDeploy",
        "Barrier",
        "EMP"
    }
}

-- Handle power activation requests from clients
PowerActivated.OnServerEvent:Connect(function(player: Player, powerName: string)
    -- Check if the player's class has access to this power
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end
    
    local playerClass = player:FindFirstChild("PlayerClass")
    if not playerClass or not playerClass:IsA("StringValue") then return end
    
    local classPowers = CLASS_POWERS[playerClass.Value]
    if not classPowers or not table.find(classPowers, powerName) then
        -- Player doesn't have access to this power
        return
    end
    
    -- Try to use the power
    local success, message = PowerSystem:usePower(player, powerName)
    
    if success then
        -- Notify all clients that the power was activated
        PowerActivated:FireAllClients(player, powerName)
        
        -- Notify the player of cooldown
        local power = PowerSystem:getPower(powerName)
        if power then
            PowerCooldown:FireClient(player, powerName, power.cooldown)
        end
    elseif message then
        -- Notify the player of the error
        warn(string.format("Power activation failed for %s: %s", player.Name, message))
    end
end)

-- Clean up when players leave
Players.PlayerRemoving:Connect(function(player)
    -- Clean up any power-related data for this player
    for _, power in pairs(PowerSystem) do
        if type(power) == "table" and power.lastUsed then
            power.lastUsed[player.UserId] = nil
        end
    end
end)

print("PowerController initialized")
