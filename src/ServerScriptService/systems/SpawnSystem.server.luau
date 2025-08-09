--!strict
-- SpawnSystem.server.luau
-- Prototypes map spawn points, destructible props, and spawns Kaiju when a match starts.
-- Lightweight, best-effort integration (avoids creating cyclic module requires).

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local success, GameConfig = pcall(function()
    return require(script.Parent.Parent.Parent.shared.config.GameConfig)
end)
if not success then
    GameConfig = nil
end

local SpawnSystem = {}
SpawnSystem.__index = SpawnSystem

function SpawnSystem:init(): boolean
    print("🔄 Initializing SpawnSystem...")
    -- Folders to hold spawn markers and props
    self.spawnFolder = Workspace:FindFirstChild("Spawns")
    if not self.spawnFolder then
        local f = Instance.new("Folder")
        f.Name = "Spawns"
        f.Parent = Workspace
        self.spawnFolder = f
    end

    self.propsFolder = Workspace:FindFirstChild("Props")
    if not self.propsFolder then
        local f = Instance.new("Folder")
        f.Name = "Props"
        f.Parent = Workspace
        self.propsFolder = f
    end

    local mapCfg = (GameConfig and GameConfig.Map) or {}
    self.kaijuSpawns = mapCfg.KaijuSpawns or { Vector3.new(0, 10, 0) }
    self.propCount = mapCfg.PropCount or 12
    self.propHealth = mapCfg.PropHealth or 500
    self.autoStartMatch = mapCfg.AutoStartMatch or false

    -- Create spawn marker parts for each configured spawn (invisible)
    for i, pos in ipairs(self.kaijuSpawns) do
        local existing = self.spawnFolder:FindFirstChild("KaijuSpawn_" .. tostring(i))
        if not existing then
            local sp = Instance.new("Part")
            sp.Name = "KaijuSpawn_" .. tostring(i)
            sp.Size = Vector3.new(2, 1, 2)
            sp.Position = pos
            sp.Anchored = true
            sp.CanCollide = false
            sp.Transparency = 1
            sp.Parent = self.spawnFolder
        end
    end

    -- Create simple destructible prop models and tag them as "Building" so BuildingSystem may pick them up
    for i = 1, self.propCount do
        local modelName = "Prop_" .. tostring(i)
        if not self.propsFolder:FindFirstChild(modelName) then
            local model = Instance.new("Model")
            model.Name = modelName

            local part = Instance.new("Part")
            part.Name = "Base"
            part.Size = Vector3.new(4, 4, 4)
            part.Position = Vector3.new(math.random(-40, 40), 4 + math.random(0, 4), math.random(-40, 40))
            part.Anchored = false
            part.Parent = model

            -- Simple health holder (used by prototypes/tests)
            local health = Instance.new("NumberValue")
            health.Name = "Health"
            health.Value = self.propHealth
            health.Parent = model

            model.PrimaryPart = part
            model.Parent = self.propsFolder

            -- Tag for BuildingSystem to discover (best-effort)
            pcall(function()
                CollectionService:AddTag(model, "Building")
            end)
        end
    end

    -- Listen for MatchStateUpdate to spawn Kaiju when match transitions to "running"
    local eventsFolder = ReplicatedStorage:FindFirstChild("GameEvents")
    if eventsFolder then
        local ms = eventsFolder:FindFirstChild("MatchStateUpdate")
        if ms and ms:IsA("RemoteEvent") then
            ms.OnServerEvent:Connect(function(_, payload: any)
                local state = payload and payload.state
                if state == "running" then
                    task.spawn(function()
                        pcall(function() self:spawnKaijus() end)
                    end)
                end
            end)
        end
    end

    -- Optional: auto-start match when min players present (best-effort)
    if self.autoStartMatch then
        Players.PlayerAdded:Connect(function()
            task.spawn(function()
                task.wait(1)
                local minPlayers = (GameConfig and GameConfig.Game and GameConfig.Game.MinPlayers) or 2
                if #Players:GetPlayers() >= minPlayers then
                    local ok, matchModule = pcall(function()
                        local mod = script.Parent:FindFirstChild("MatchSystem")
                        if mod and mod:IsA("ModuleScript") then
                            return require(mod)
                        end
                        return nil
                    end)
                    if ok and matchModule and type(matchModule.startMatch) == "function" then
                        pcall(function() matchModule:startMatch() end)
                    end
                end
            end)
        end)
    end

    print("✅ SpawnSystem initialized")
    return true
end

function SpawnSystem:spawnKaijus()
    -- Try to require KaijuSystem (best-effort). Avoid strict dependency cycles by using pcall.
    local kaijuModule = nil
    pcall(function()
        local mod = script.Parent:FindFirstChild("KaijuSystem")
        if mod and mod:IsA("ModuleScript") then
            kaijuModule = require(mod)
        end
    end)

    -- For each spawn marker, create/ask KaijuSystem to spawn a Kaiju
    local spawnMarkers = self.spawnFolder:GetChildren()
    for i, marker in ipairs(spawnMarkers) do
        local pos = nil
        if marker and marker:IsA("BasePart") then
            pos = marker.Position
        else
            pos = self.kaijuSpawns[i] or Vector3.new(0, 10, 0)
        end

        if kaijuModule and type(kaijuModule.spawnKaiju) == "function" then
            pcall(function()
                -- Some KaijuSystem variants expect (player) or (position, def); handle both with pcall wrappers
                local ok, res = pcall(function() return kaijuModule:spawnKaiju(pos) end)
                if not ok then
                    -- fallback try different signature
                    pcall(function() kaijuModule.spawnKaiju(kaijuModule, pos) end)
                end
            end)
        else
            -- Fallback: create a simple Kaiju model in the world
            local model = Instance.new("Model")
            model.Name = "Kaiju_Prototype_" .. tostring(i)
            local root = Instance.new("Part")
            root.Name = "HumanoidRootPart"
            root.Size = Vector3.new(10, 5, 10)
            root.Position = pos
            root.Anchored = false
            root.Parent = model

            local humanoid = Instance.new("Humanoid")
            humanoid.Name = "KaijuHumanoid"
            humanoid.MaxHealth = 1000
            humanoid.Health = humanoid.MaxHealth
            humanoid.Parent = model

            model.Parent = Workspace
        end
    end
end

return SpawnSystem