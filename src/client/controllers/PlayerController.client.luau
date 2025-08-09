--!strict
-- PlayerController.client.luau
-- Client-side player controller: input sending, abilities, HUD, lightweight prediction

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

local PlayerController = {}
PlayerController.__index = PlayerController

local ABILITY_KEYS = {
    [Enum.KeyCode.E] = "Primary",
    [Enum.KeyCode.One] = "Ability1",
    [Enum.KeyCode.Two] = "Ability2",
    [Enum.KeyCode.Three] = "Ability3",
}

function PlayerController:Init()
    local self = setmetatable({}, PlayerController)
    self.player = player
    self.humanoid = nil :: Humanoid?
    self.hrp = nil :: BasePart?
    self.health = 100
    self.maxHealth = 100
    self.energy = 100
    self.maxEnergy = 100
    self.score = 0
    self.inputVec = Vector3.new(0,0,0)
    self._keysDown = {}
    self._lastInputSent = 0
    self._inputInterval = 0.1

    -- GameEvents may be created by the server; attach if present and listen for creation
    self.eventsFolder = ReplicatedStorage:FindFirstChild("GameEvents")
    if self.eventsFolder then
        self:_attachGameEvents()
    else
        ReplicatedStorage.ChildAdded:Connect(function(child)
            if child and child.Name == "GameEvents" then
                self.eventsFolder = child
                self:_attachGameEvents()
            end
        end)
    end

    -- HUD
    self:_setupHUD()

    -- Controls and input sampling
    self:_setupControls()

    -- Character
    if self.player.Character then
        self:_onCharacterAdded(self.player.Character)
    end
    self.player.CharacterAdded:Connect(function(char) self:_onCharacterAdded(char) end)

    return self
end

function PlayerController:_attachGameEvents()
    if not self.eventsFolder then return end
    self.PlayerInputRemote = self.eventsFolder:FindFirstChild("PlayerInput")
    self.UseAbilityRemote = self.eventsFolder:FindFirstChild("UseAbilityRequest")
    self.MatchStateUpdate = self.eventsFolder:FindFirstChild("MatchStateUpdate")

    if self.MatchStateUpdate and self.MatchStateUpdate:IsA("RemoteEvent") then
        self.MatchStateUpdate.OnClientEvent:Connect(function(payload) self:_onMatchStateUpdate(payload) end)
    end

    -- Listen for newly created remotes
    self.eventsFolder.ChildAdded:Connect(function(child)
        if child.Name == "PlayerInput" then self.PlayerInputRemote = child end
        if child.Name == "UseAbilityRequest" then self.UseAbilityRemote = child end
        if child.Name == "MatchStateUpdate" then
            self.MatchStateUpdate = child
            self.MatchStateUpdate.OnClientEvent:Connect(function(payload) self:_onMatchStateUpdate(payload) end)
        end
    end)
end

function PlayerController:_setupHUD()
    local playerGui = self.player:WaitForChild("PlayerGui")
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "GameHUD"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui

    -- Health bar
    local healthFrame = Instance.new("Frame")
    healthFrame.Name = "HealthFrame"
    healthFrame.Size = UDim2.new(0, 200, 0, 24)
    healthFrame.Position = UDim2.new(0.02, 0, 0.9, 0)
    healthFrame.BackgroundColor3 = Color3.fromRGB(40,40,40)
    healthFrame.BorderSizePixel = 0
    healthFrame.Parent = screenGui
    local healthFill = Instance.new("Frame")
    healthFill.Name = "HealthFill"
    healthFill.Size = UDim2.new(1,0,1,0)
    healthFill.AnchorPoint = Vector2.new(0,0)
    healthFill.Position = UDim2.new(0,0,0,0)
    healthFill.BackgroundColor3 = Color3.fromRGB(170,40,40)
    healthFill.BorderSizePixel = 0
    healthFill.Parent = healthFrame

    -- Energy bar
    local energyFrame = Instance.new("Frame")
    energyFrame.Name = "EnergyFrame"
    energyFrame.Size = UDim2.new(0, 200, 0, 12)
    energyFrame.Position = UDim2.new(0.02, 0, 0.86, 0)
    energyFrame.BackgroundColor3 = Color3.fromRGB(40,40,40)
    energyFrame.BorderSizePixel = 0
    energyFrame.Parent = screenGui
    local energyFill = Instance.new("Frame")
    energyFill.Name = "EnergyFill"
    energyFill.Size = UDim2.new(1,0,1,0)
    energyFill.BackgroundColor3 = Color3.fromRGB(0,170,255)
    energyFill.BorderSizePixel = 0
    energyFill.Parent = energyFrame

    -- Score label
    local scoreLabel = Instance.new("TextLabel")
    scoreLabel.Name = "ScoreLabel"
    scoreLabel.Size = UDim2.new(0, 200, 0, 30)
    scoreLabel.Position = UDim2.new(0.78, 0, 0.02, 0)
    scoreLabel.BackgroundTransparency = 1
    scoreLabel.TextColor3 = Color3.new(1,1,1)
    scoreLabel.Text = "Score: 0"
    scoreLabel.TextScaled = true
    scoreLabel.Parent = screenGui

    -- Timer label (from MatchStateUpdate)
    local timerLabel = Instance.new("TextLabel")
    timerLabel.Name = "TimerLabel"
    timerLabel.Size = UDim2.new(0, 120, 0, 24)
    timerLabel.Position = UDim2.new(0.45, -60, 0.02, 0)
    timerLabel.BackgroundTransparency = 1
    timerLabel.TextColor3 = Color3.new(1,1,1)
    timerLabel.Text = ""
    timerLabel.TextScaled = true
    timerLabel.Parent = screenGui

    self._hud = {
        screen = screenGui,
        healthFrame = healthFrame,
        healthFill = healthFill,
        energyFrame = energyFrame,
        energyFill = energyFill,
        scoreLabel = scoreLabel,
        timerLabel = timerLabel,
    }

    -- initialize with default
    self:_updateHUDHealth(self.health, self.maxHealth)
    self:_updateHUDEnergy(self.energy, self.maxEnergy)
    self:_updateHUDScore(self.score)
end

function PlayerController:_updateHUDHealth(value, max)
    if not self._hud then return end
    local pct = 0
    if max and max > 0 then pct = math.clamp(value / max, 0, 1) else pct = 0 end
    self._hud.healthFill:TweenSize(UDim2.new(pct,0,1,0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true)
end

function PlayerController:_updateHUDEnergy(value, max)
    if not self._hud then return end
    local pct = 0
    if max and max > 0 then pct = math.clamp(value / max, 0, 1) else pct = 0 end
    self._hud.energyFill:TweenSize(UDim2.new(pct,0,1,0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true)
end

function PlayerController:_updateHUDScore(score)
    if not self._hud then return end
    self._hud.scoreLabel.Text = "Score: " .. tostring(score or 0)
end

function PlayerController:_updateTimerText(timeRemaining)
    if not self._hud then return end
    if not timeRemaining then
        self._hud.timerLabel.Text = ""
        return
    end
    local seconds = math.max(0, math.floor(timeRemaining))
    local mins = math.floor(seconds / 60)
    local secs = seconds % 60
    self._hud.timerLabel.Text = string.format("%02d:%02d", mins, secs)
end

function PlayerController:_onCharacterAdded(character)
    if not character or not character:IsA("Model") then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    self.humanoid = humanoid
    self.hrp = hrp
    if humanoid then
        self.maxHealth = humanoid.MaxHealth or self.maxHealth
        self.health = humanoid.Health or self.health
        humanoid.HealthChanged:Connect(function(h) self.health = h; self:_updateHUDHealth(h, humanoid.MaxHealth) end)
    end
end

function PlayerController:_setupControls()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            local key = input.KeyCode
            if key == Enum.KeyCode.W or key == Enum.KeyCode.A or key == Enum.KeyCode.S or key == Enum.KeyCode.D then
                self._keysDown[key] = true
            end
            local ability = ABILITY_KEYS[key]
            if ability then
                self:_useAbility(ability)
            end
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
            -- left click -> primary attack (predictive)
            self:_useAbility("Primary")
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard then
            local key = input.KeyCode
            if key == Enum.KeyCode.W or key == Enum.KeyCode.A or key == Enum.KeyCode.S or key == Enum.KeyCode.D then
                self._keysDown[key] = nil
            end
        end
    end)

    RunService.Heartbeat:Connect(function(dt)
        self:_sampleAndSendInput(dt)
    end)
end

function PlayerController:_getInputVector()
    local x = 0; local z = 0
    if self._keysDown[Enum.KeyCode.W] then z = z - 1 end
    if self._keysDown[Enum.KeyCode.S] then z = z + 1 end
    if self._keysDown[Enum.KeyCode.A] then x = x - 1 end
    if self._keysDown[Enum.KeyCode.D] then x = x + 1 end
    local vec = Vector3.new(x,0,z)
    if vec.Magnitude > 0 then
        return vec.Unit
    end
    return Vector3.new(0,0,0)
end

function PlayerController:_sampleAndSendInput(dt)
    self._lastInputSent = (self._lastInputSent or 0) + dt
    if self._lastInputSent < self._inputInterval then return end
    self._lastInputSent = 0
    local dir = self:_getInputVector()
    local payload = {
        direction = dir,
        timestamp = tick(),
        position = (self.hrp and self.hrp:IsA("BasePart") and self.hrp.Position) or Vector3.new(0,0,0),
    }
    if self.PlayerInputRemote and self.PlayerInputRemote:IsA("RemoteEvent") then
        pcall(function() self.PlayerInputRemote:FireServer(payload) end)
    end
end

function PlayerController:_useAbility(abilityName)
    -- send request to server
    if self.UseAbilityRemote and self.UseAbilityRemote:IsA("RemoteEvent") then
        pcall(function() self.UseAbilityRemote:FireServer(abilityName) end)
    end
    -- local predicted energy reduction
    local defaults = {
        Primary = {Cost = 0},
        Ability1 = {Cost = 20},
        Ability2 = {Cost = 30},
        Ability3 = {Cost = 40},
    }
    local cost = (defaults[abilityName] and defaults[abilityName].Cost) or 0
    self.energy = math.max(0, (self.energy or 0) - cost)
    self:_updateHUDEnergy(self.energy, self.maxEnergy)
end

function PlayerController:_onMatchStateUpdate(payload)
    if not payload then return end
    if payload.timeRemaining ~= nil then
        self:_updateTimerText(payload.timeRemaining)
    end
    if payload.players and type(payload.players) == "table" then
        for _, p in ipairs(payload.players) do
            if tonumber(p.userId) == player.UserId then
                if p.alive == false then
                    self:_updateHUDHealth(0, self.maxHealth)
                end
            end
        end
    end
end

return PlayerController
