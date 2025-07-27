--!strict
-- PowerInput.client.luau
-- Handles player input for activating powers

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local PowerEvents = ReplicatedStorage:WaitForChild("PowerEvents")
local PowerActivated = PowerEvents:WaitForChild("PowerActivated")
local PowerCooldown = PowerEvents:WaitForChild("PowerCooldown")

-- Power key bindings (can be customized)
local POWER_KEYS = {
    [Enum.KeyCode.One] = 1,    -- First power
    [Enum.KeyCode.Two] = 2,    -- Second power
    [Enum.KeyCode.Three] = 3   -- Third power
}

-- UI elements
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PowerHUD"
screenGui.ResetOnSpawn = false

-- Create power buttons
local powerButtons = {}
local activePowers = {}
local cooldowns = {}

local function createPowerButton(index: number)
    local button = Instance.new("TextButton")
    button.Name = "Power" .. index
    button.Size = UDim2.new(0, 80, 0, 80)
    button.Position = UDim2.new(0.7 + (index * 0.1), 0, 0.8, 0)
    button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    button.BorderSizePixel = 0
    button.Text = "Power " .. index
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextScaled = true
    button.Visible = false
    
    local cooldownFrame = Instance.new("Frame")
    cooldownFrame.Name = "Cooldown"
    cooldownFrame.Size = UDim2.new(1, 0, 0, 0)
    cooldownFrame.Position = UDim2.new(0, 0, 1, 0)
    cooldownFrame.AnchorPoint = Vector2.new(0, 1)
    cooldownFrame.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    cooldownFrame.BorderSizePixel = 0
    cooldownFrame.Parent = button
    
    button.MouseButton1Click:Connect(function()
        if activePowers[index] and not cooldowns[index] then
            PowerActivated:FireServer(activePowers[index])
        end
    end)
    
    button.Parent = screenGui
    return button
end

-- Initialize power buttons
for i = 1, 3 do
    powerButtons[i] = createPowerButton(i)
end

-- Update power buttons based on player's class
local function updatePowerButtons()
    local character = player.Character
    if not character then return end
    
    local playerClass = player:FindFirstChild("PlayerClass")
    if not playerClass or not playerClass:IsA("StringValue") then return end
    
    -- This would be populated based on the player's class
    -- In a real implementation, you'd get this from the server
    local classPowers = {
        ["Kaiju"] = {"Roar", "Stomp", "TailWhip"},
        ["Guardian"] = {"ShieldBash", "ProtectiveAura", "HealingWave"},
        ["Engineer"] = {"TurretDeploy", "Barrier", "EMP"}
    }
    
    activePowers = classPowers[playerClass.Value] or {}
    
    for i, power in ipairs(activePowers) do
        local button = powerButtons[i]
        if button then
            button.Text = power
            button.Visible = true
        end
    end
end

-- Handle power activation
local function onPowerActivated(sender: Player, powerName: string)
    if sender == player then return end -- Skip local player's own activations
    
    -- Play visual/audio effects for other players' power activations
    local character = sender.Character
    if not character then return end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    -- Example: Create a visual effect at the character's position
    local effect = Instance.new("ParticleEmitter")
    effect.Texture = "rbxassetid://241539689"
    effect.LightEmission = 0.5
    effect.Size = NumberSequence.new(0.5, 2)
    effect.Lifetime = NumberRange.new(0.5, 1)
    effect.Rate = 50
    effect.Speed = NumberRange.new(5, 10)
    
    local attachment = Instance.new("Attachment")
    attachment.Parent = rootPart
    effect.Parent = attachment
    
    game:GetService("Debris"):AddItem(attachment, 1)
end

-- Handle power cooldown
local function onPowerCooldown(powerName: string, cooldown: number)
    local index = table.find(activePowers, powerName)
    if not index then return end
    
    local button = powerButtons[index]
    if not button then return end
    
    local cooldownFrame = button:FindFirstChild("Cooldown")
    if not cooldownFrame then return end
    
    -- Start cooldown
    cooldowns[index] = true
    local startTime = tick()
    
    -- Animate cooldown
    local connection
    connection = game:GetService("RunService").Heartbeat:Connect(function()
        local elapsed = tick() - startTime
        local progress = math.clamp(elapsed / cooldown, 0, 1)
        
        cooldownFrame.Size = UDim2.new(1, 0, progress, 0)
        
        if progress >= 1 then
            cooldowns[index] = nil
            connection:Disconnect()
        end
    end)
end

-- Connect events
PowerActivated.OnClientEvent:Connect(onPowerActivated)
PowerCooldown.OnClientEvent:Connect(onPowerCooldown)

-- Handle keyboard input
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    local powerIndex = POWER_KEYS[input.KeyCode]
    if powerIndex and activePowers[powerIndex] and not cooldowns[powerIndex] then
        PowerActivated:FireServer(activePowers[powerIndex])
    end
end)

-- Initialize
player.CharacterAdded:Connect(function()
    updatePowerButtons()
end)

-- Add to player's GUI
screenGui.Parent = playerGui

-- Initial update
updatePowerButtons()

print("PowerInput initialized")
