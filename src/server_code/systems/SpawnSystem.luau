--!strict
-- SpawnSystem.luau
-- Responsible for creating/despawning props, managing spawn points, and spawning Kaiju on match start.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

-- Best-effort load GameConfig
local success, GameConfig = pcall(function()
    return require(script.Parent.Parent.Parent.shared.config.GameConfig)
end)
if not success then
    GameConfig = nil
end

local SpawnSystem = {}
SpawnSystem.__index = SpawnSystem

function SpawnSystem:init()
    print("🔄 Initializing SpawnSystem...")

    -- Folder for props
    self.propsFolder = Workspace:FindFirstChild("Props")
    if not self.propsFolder then
        local f = Instance.new("Folder")
        f.Name = "Props"
        f.Parent = Workspace
        self.propsFolder = f
    end

    -- Gather spawn points: prefer Workspace.SpawnPoints BaseParts, then GameConfig entries, fallback to origin
    self.spawnMarkers = {}
    local spawnFolder = Workspace:FindFirstChild("SpawnPoints")
    if spawnFolder and spawnFolder:IsA("Folder") then
        for _, child in ipairs(spawnFolder:GetChildren()) do
            if child and child:IsA("BasePart") then
                table.insert(self.spawnMarkers, child.Position)
            end
        end
    end

    if GameConfig and GameConfig.Game and GameConfig.Game.Spawn and type(GameConfig.Game.Spawn.KaijuSpawnPoints) == "table" then
        for _, v in ipairs(GameConfig.Game.Spawn.KaijuSpawnPoints) do
            if typeof(v) == "Vector3" then
                table.insert(self.spawnMarkers, v)
            end
        end
    end

    if #self.spawnMarkers == 0 then
        -- fallback marker
        table.insert(self.spawnMarkers, Vector3.new(0, 5, 0))
    end

    local spawnCfg = (GameConfig and GameConfig.Game and GameConfig.Game.Spawn) or {}
    self.propCount = spawnCfg.PropCount or 20
    self.propHealth = spawnCfg.PropHealth or 200
    self.autoStartWhenMinPlayers = spawnCfg.AutoStartWhenMinPlayers
    if self.autoStartWhenMinPlayers == nil then
        self.autoStartWhenMinPlayers = true
    end

    -- Create props now
    self:spawnProps()

    print("✅ SpawnSystem initialized (props:", tostring(self.propCount) .. ")")
    return true
end

function SpawnSystem:clearProps()
    if not self.propsFolder then return end
    for _, c in ipairs(self.propsFolder:GetChildren()) do
        pcall(function() c:Destroy() end)
    end
end

function SpawnSystem:spawnProps()
    if not self.propsFolder then return end
    self:clearProps()

    local areaRadius = 40
    local n = math.max(0, self.propCount or 0)
    if n == 0 then return end

    for i = 1, n do
        local posSeed = self.spawnMarkers[((i - 1) % #self.spawnMarkers) + 1]
        local offset = Vector3.new(math.random(-areaRadius, areaRadius), 0, math.random(-areaRadius, areaRadius))
        local part = Instance.new("Part")
        part.Name = "Prop"
        part.Size = Vector3.new(4, 4, 4)
        part.Position = posSeed + offset + Vector3.new(0, (part.Size.Y / 2), 0)
        part.Anchored = false
        part.Parent = self.propsFolder
        part.TopSurface = Enum.SurfaceType.Smooth
        part.BottomSurface = Enum.SurfaceType.Smooth

        local health = Instance.new("NumberValue")
        health.Name = "Health"
        health.Value = self.propHealth or 200
        health.Parent = part

        CollectionService:AddTag(part, "DestructibleProp")

        health.Changed:Connect(function(new)
            if type(new) == "number" and new <= 0 then
                pcall(function() part:Destroy() end)
            end
        end)
    end
end

-- Attempts to spawn a Kaiju. Best-effort: will try to require KaijuSystem in the same systems folder.
-- Returns the created Model (Kaiju) if possible, otherwise a placeholder Model.
function SpawnSystem:spawnKaiju(spawnPosition: Vector3?, defName: string?)
    local position = spawnPosition or (self.spawnMarkers[1] or Vector3.new(0, 5, 0))

    -- Try to find KaijuSystem module next to this module (avoid hard dependency at top-level to reduce cycles)
    local ok, kaijuModule = pcall(function()
        local mod = script.Parent:FindFirstChild("KaijuSystem")
        if mod and mod:IsA("ModuleScript") then
            return require(mod)
        end
        local sibling = script.Parent.Parent and script.Parent.Parent:FindFirstChild("KaijuSystem")
        if sibling and sibling:IsA("ModuleScript") then
            return require(sibling)
        end
        return nil
    end)

    if ok and kaijuModule and type(kaijuModule.spawnKaiju) == "function" then
        local success, result = pcall(function()
            return kaijuModule:spawnKaiju(position, defName)
        end)
        if success then
            return result
        end
    end

    -- Fallback placeholder Kaiju
    local model = Instance.new("Model")
    model.Name = "Kaiju_Placeholder_" .. tostring(math.random(1, 1e6))

    local root = Instance.new("Part")
    root.Name = "HumanoidRootPart"
    root.Size = Vector3.new(10, 5, 10)
    root.Position = position
    root.Anchored = false
    root.Parent = model

    local humanoid = Instance.new("Humanoid")
    humanoid.Name = "KaijuHumanoid"
    humanoid.MaxHealth = (GameConfig and GameConfig.Kaiju and GameConfig.Kaiju.BaseHealth) or 1000
    humanoid.Health = humanoid.MaxHealth
    humanoid.Parent = model

    model.Parent = Workspace:FindFirstChild("Kaijus") or Workspace

    return model
end

return SpawnSystem