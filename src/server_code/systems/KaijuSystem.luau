--!strict
-- KaijuSystem.server.luau
-- Handles Kaiju AI, attacks, phases, and integration with Match and Scoring systems

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local success, GameConfig = pcall(function()
    return require(script.Parent.Parent.Parent.shared.config.GameConfig)
end)
if not success then
    GameConfig = nil
end

type KaijuAbility = {
    Cooldown: number?,
    Damage: number?,
    Range: number?,
    Duration: number?,
    BuffMultiplier: number?,
    SoundId: string?,
}

type KaijuDef = {
    Name: string,
    MaxHealth: number,
    Size: Vector3,
    PhaseThresholds: { number }?,
    Abilities: { [string]: KaijuAbility }?,
}

type KaijuState = {
    model: Model,
    humanoid: Humanoid,
    defName: string,
    def: KaijuDef?,
    phase: number,
    aiRunning: boolean,
    lastAttackTimes: { [string]: number },
    damageLog: { [number]: number },
    isAlive: boolean,
}

local KaijuSystem = {}
KaijuSystem.__index = KaijuSystem

function KaijuSystem:init(): boolean
    print("🔄 Initializing KaijuSystem...")
    self.kaijus = {} :: { [string]: KaijuState }
    self.kaijuFolder = Workspace:FindFirstChild("Kaijus")
    if not self.kaijuFolder then
        local f = Instance.new("Folder")
        f.Name = "Kaijus"
        f.Parent = Workspace
        self.kaijuFolder = f
    end

    local eventsFolder = ReplicatedStorage:FindFirstChild("GameEvents")
    if not eventsFolder then
        eventsFolder = Instance.new("Folder")
        eventsFolder.Name = "GameEvents"
        eventsFolder.Parent = ReplicatedStorage
    end

    local ev = eventsFolder:FindFirstChild("KaijuKilled")
    if ev and ev:IsA("RemoteEvent") then
        self.KaijuKilledEvent = ev
    else
        local newEv = Instance.new("RemoteEvent")
        newEv.Name = "KaijuKilled"
        newEv.Parent = eventsFolder
        self.KaijuKilledEvent = newEv
    end

    print("✅ KaijuSystem initialized")
    return true
end

local function defaultKaijuDef(): KaijuDef
    return {
        Name = "Basic",
        MaxHealth = 3000,
        Size = Vector3.new(20, 10, 20),
        PhaseThresholds = { 0.6, 0.3 },
        Abilities = {
            Stomp = { Cooldown = 6, Damage = 80, Range = 15 },
            Swipe = { Cooldown = 1.5, Damage = 25, Range = 6 },
            Charge = { Cooldown = 8, Damage = 100, Range = 40 },
        },
    }
end

function KaijuSystem:getKaijuDef(defName: string?): KaijuDef
    if GameConfig and GameConfig.KaijuDefs then
        if defName and GameConfig.KaijuDefs[defName] then
            return GameConfig.KaijuDefs[defName] :: KaijuDef
        end
        for _, v in pairs(GameConfig.KaijuDefs) do
            return v :: KaijuDef
        end
    end
    return defaultKaijuDef()
end

local function findNearestPlayerFromPosition(position: Vector3)
    local nearestPlayer = nil
    local nearestDist = math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player and player.Character and player.Character:IsA("Model") then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hrp:IsA("BasePart") and humanoid and humanoid.Health > 0 then
                local dist = (hrp.Position - position).Magnitude
                if dist < nearestDist then
                    nearestDist = dist
                    nearestPlayer = player
                end
            end
        end
    end
    return nearestPlayer, nearestDist
end

function KaijuSystem:spawnKaiju(spawnPosition: Vector3?, defName: string?): Model
    local def = self:getKaijuDef(defName)
    local model = Instance.new("Model")
    model.Name = "Kaiju_" .. tostring(math.random(1, 1e6))

    local size = def.Size or Vector3.new(20, 10, 20)
    local root = Instance.new("Part")
    root.Name = "HumanoidRootPart"
    root.Size = size
    root.Position = spawnPosition or Vector3.new(0, size.Y / 2 + 5, 0)
    root.Anchored = false
    root.CanCollide = true
    root.Parent = model

    local humanoid = Instance.new("Humanoid")
    humanoid.Name = "KaijuHumanoid"
    humanoid.MaxHealth = def.MaxHealth or 1000
    humanoid.Health = humanoid.MaxHealth
    humanoid.Parent = model

    local tag = Instance.new("StringValue")
    tag.Name = "KaijuTag"
    tag.Value = def.Name or "Kaiju"
    tag.Parent = model

    model.Parent = self.kaijuFolder

    local state: KaijuState = {
        model = model,
        humanoid = humanoid :: Humanoid,
        defName = def.Name or "Basic",
        def = def,
        phase = 1,
        aiRunning = false,
        lastAttackTimes = {},
        damageLog = {},
        isAlive = true,
    }

    humanoid.Died:Connect(function()
        state.isAlive = false
        task.spawn(function()
            self:handleKaijuDeath(state)
        end)
    end)

    humanoid.HealthChanged:Connect(function(newHealth: number)
        self:handleKaijuHealthChanged(state, newHealth)
    end)

    self.kaijus[model.Name] = state

    self:setupAbilities(model)
    self:startAI(state)

    return model
end

function KaijuSystem:setupAbilities(kaiju: Model)
    if not kaiju or not kaiju:IsA("Model") then error("Invalid Kaiju model provided") end

    local energyBeam = kaiju:FindFirstChild("EnergyBeam")
    if not (energyBeam and energyBeam:IsA("RemoteEvent")) then
        energyBeam = Instance.new("RemoteEvent")
        energyBeam.Name = "EnergyBeam"
        energyBeam.Parent = kaiju
    end
    energyBeam.OnServerEvent:Connect(function(player: Player, targetPosition: Vector3)
        self:onAbilityUsed(player, kaiju, "EnergyBeam", { target = targetPosition })
    end)

    local roarEvent = kaiju:FindFirstChild("RoarEvent")
    if not (roarEvent and roarEvent:IsA("RemoteEvent")) then
        roarEvent = Instance.new("RemoteEvent")
        roarEvent.Name = "RoarEvent"
        roarEvent.Parent = kaiju
    end
    roarEvent.OnServerEvent:Connect(function(player: Player, ...)
        self:onAbilityUsed(player, kaiju, "Roar", ...)
    end)

    -- Ensure there is a Roar sound
    local roarSound = kaiju:FindFirstChild("Roar")
    if not (roarSound and roarSound:IsA("Sound")) then
        roarSound = Instance.new("Sound")
        roarSound.Name = "Roar"
        local sid = (GameConfig and GameConfig.Kaiju and GameConfig.Kaiju.Abilities and GameConfig.Kaiju.Abilities.Roar and GameConfig.Kaiju.Abilities.Roar.SoundId) or nil
        if sid then roarSound.SoundId = "rbxassetid://" .. tostring(sid) end
        roarSound.Parent = kaiju
    end

    return { energyBeam = energyBeam :: RemoteEvent, roarEvent = roarEvent :: RemoteEvent, roarSound = roarSound :: Sound }
end

function KaijuSystem:onAbilityUsed(player: Player, kaijuModel: Model, abilityName: string, abilityData: { [string]: any }?)
    if not player then
        warn("Invalid player for ability use")
        return
    end
    if not kaijuModel or not kaijuModel:IsA("Model") then
        warn("Invalid kaiju model for ability use")
        return
    end

    if abilityName == "EnergyBeam" then
        self:handleEnergyBeam(player, kaijuModel, abilityData or {})
    elseif abilityName == "Roar" then
        self:handleRoar(player, kaijuModel, abilityData or {})
    else
        warn("Unknown Kaiju ability:", abilityName)
    end
end

function KaijuSystem:handleEnergyBeam(player: Player, kaiju: Model, data: { target: Vector3 })
    local dmg = (GameConfig and GameConfig.Kaiju and GameConfig.Kaiju.Abilities and GameConfig.Kaiju.Abilities.EnergyBeam and GameConfig.Kaiju.Abilities.EnergyBeam.Damage) or 30
    local range = (GameConfig and GameConfig.Kaiju and GameConfig.Kaiju.Abilities and GameConfig.Kaiju.Abilities.EnergyBeam and GameConfig.Kaiju.Abilities.EnergyBeam.Range) or 50
    local target = data.target or (kaiju and kaiju:FindFirstChild("HumanoidRootPart") and (kaiju:FindFirstChild("HumanoidRootPart") :: BasePart).Position) or Vector3.new(0,0,0)

    for _, pl in ipairs(Players:GetPlayers()) do
        if pl and pl.Character and pl.Character:IsA("Model") then
            local hrp = pl.Character:FindFirstChild("HumanoidRootPart")
            local humanoid = pl.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hrp:IsA("BasePart") and humanoid and humanoid.Health > 0 then
                if (hrp.Position - target).Magnitude <= range then
                    pcall(function()
                        humanoid.Health = math.max(0, humanoid.Health - dmg)
                    end)
                end
            end
        end
    end
end

function KaijuSystem:handleRoar(player: Player, kaiju: Model, data: {})
    local roarSound = kaiju:FindFirstChild("Roar")
    if roarSound and roarSound:IsA("Sound") then roarSound:Play() end
    -- Additional effects to be added (buffs, stun, etc.)
end

function KaijuSystem:applyDamageToPlayer(targetPlayer: Player, damage: number, kaijuState: KaijuState, sourceUserId: number?)
    if not targetPlayer or not targetPlayer.Character then return end
    local humanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid or not humanoid:IsA("Humanoid") then return end

    pcall(function()
        if humanoid.Health > 0 then
            humanoid.Health = math.max(0, humanoid.Health - damage)
        end
    end)

    if kaijuState and sourceUserId then
        kaijuState.damageLog[sourceUserId] = (kaijuState.damageLog[sourceUserId] or 0) + damage
    end
end

function KaijuSystem:performSwipe(kaijuState: KaijuState, targetPlayer: Player)
    if not kaijuState or not targetPlayer then return end
    local def = kaijuState.def
    local ability = (def and def.Abilities and def.Abilities.Swipe) or { Damage = 25, Cooldown = 1.5, Range = 6 }
    local now = os.clock()
    local last = kaijuState.lastAttackTimes["Swipe"] or 0
    if now - last < (ability.Cooldown or 1.5) then return end
    kaijuState.lastAttackTimes["Swipe"] = now
    self:applyDamageToPlayer(targetPlayer, ability.Damage or 25, kaijuState)
end

function KaijuSystem:performStomp(kaijuState: KaijuState)
    if not kaijuState then return end
    local def = kaijuState.def
    local ability = (def and def.Abilities and def.Abilities.Stomp) or { Damage = 80, Cooldown = 6, Range = 15 }
    local now = os.clock()
    local last = kaijuState.lastAttackTimes["Stomp"] or 0
    if now - last < (ability.Cooldown or 6) then return end
    kaijuState.lastAttackTimes["Stomp"] = now

    local origin = kaijuState.model:FindFirstChild("HumanoidRootPart")
    if not origin or not origin:IsA("BasePart") then return end
    local originPos = origin.Position

    for _, pl in ipairs(Players:GetPlayers()) do
        if pl and pl.Character and pl.Character:IsA("Model") then
            local hrp = pl.Character:FindFirstChild("HumanoidRootPart")
            local humanoid = pl.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hrp:IsA("BasePart") and humanoid and humanoid.Health > 0 then
                local dist = (hrp.Position - originPos).Magnitude
                if dist <= (ability.Range or 15) then
                    self:applyDamageToPlayer(pl, ability.Damage or 80, kaijuState)
                end
            end
        end
    end
end

function KaijuSystem:performCharge(kaijuState: KaijuState, targetPlayer: Player)
    if not kaijuState or not targetPlayer then return end
    local def = kaijuState.def
    local ability = (def and def.Abilities and def.Abilities.Charge) or { Damage = 100, Cooldown = 8, Range = 40 }
    local now = os.clock()
    local last = kaijuState.lastAttackTimes["Charge"] or 0
    if now - last < (ability.Cooldown or 8) then return end
    kaijuState.lastAttackTimes["Charge"] = now

    local origin = kaijuState.model:FindFirstChild("HumanoidRootPart")
    if not origin or not origin:IsA("BasePart") then return end
    local hrp = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp or not hrp:IsA("BasePart") then return end
    local dist = (hrp.Position - origin.Position).Magnitude
    if dist <= (ability.Range or 40) then
        self:applyDamageToPlayer(targetPlayer, ability.Damage or 100, kaijuState)
    end
end

function KaijuSystem:startAI(kaijuState: KaijuState)
    if not kaijuState or kaijuState.aiRunning then return end
    kaijuState.aiRunning = true

    task.spawn(function()
        while kaijuState.isAlive and kaijuState.humanoid and kaijuState.humanoid.Health > 0 do
            local hrp = kaijuState.model:FindFirstChild("HumanoidRootPart")
            if not hrp or not hrp:IsA("BasePart") then
                task.wait(0.5)
            else
                local player, dist = findNearestPlayerFromPosition(hrp.Position)
                if player then
                    local def = kaijuState.def
                    local swipeRange = (def and def.Abilities and def.Abilities.Swipe and def.Abilities.Swipe.Range) or 6
                    local stompRange = (def and def.Abilities and def.Abilities.Stomp and def.Abilities.Stomp.Range) or 15
                    local chargeRange = (def and def.Abilities and def.Abilities.Charge and def.Abilities.Charge.Range) or 40

                    if dist <= (swipeRange or 6) then
                        self:performSwipe(kaijuState, player)
                    elseif dist <= (stompRange or 15) then
                        self:performStomp(kaijuState)
                    else
                        self:performCharge(kaijuState, player)
                    end
                end

                task.wait(0.5)
            end
        end
        kaijuState.aiRunning = false
    end)
end

function KaijuSystem:handleKaijuHealthChanged(kaijuState: KaijuState, newHealth: number)
    if not kaijuState or not kaijuState.def then return end
    local def = kaijuState.def
    local thresholds = def.PhaseThresholds or { 0.6, 0.3 }
    local maxHealth = kaijuState.humanoid and kaijuState.humanoid.MaxHealth or 1
    local ratio = newHealth / maxHealth

    local newPhase = 1
    if thresholds[2] and ratio <= thresholds[2] then
        newPhase = 3
    elseif thresholds[1] and ratio <= thresholds[1] then
        newPhase = 2
    end

    if newPhase ~= kaijuState.phase then
        kaijuState.phase = newPhase
        print(string.format("[Kaiju] Phase changed to %d for %s", newPhase, kaijuState.model.Name))
    end
end

function KaijuSystem:handleKaijuDeath(kaijuState: KaijuState)
    if not kaijuState then return end
    print("[Kaiju] Kaiju died:", kaijuState.model.Name)

    local topUid, topDamage = nil, 0
    for uid, dmg in pairs(kaijuState.damageLog or {}) do
        if dmg > topDamage then
            topDamage = dmg
            topUid = uid
        end
    end

    if topUid then
        local player = Players:GetPlayerByUserId(topUid)
        if player then
            local ok, scoring = pcall(function()
                local module = script.Parent:FindFirstChild("ScoringSystem")
                if module then
                    return require(module)
                end
                return nil
            end)
            if ok and scoring and type(scoring.UpdateScore) == "function" then
                pcall(function()
                    scoring:UpdateScore(player, "KILL", 1)
                end)
            end
        end
    end

    pcall(function()
        local msModule = script.Parent:FindFirstChild("MatchSystem")
        if msModule then
            local matchSys = require(msModule)
            if matchSys and type(matchSys.onKaijuKilled) == "function" then
                pcall(function() matchSys:onKaijuKilled() end)
            end
        end
    end)

    if self.KaijuKilledEvent then
        pcall(function()
            self.KaijuKilledEvent:FireAllClients({ kaijuName = kaijuState.model.Name })
        end)
    end

    task.spawn(function()
        task.wait(2)
        if kaijuState.model and kaijuState.model.Parent then
            kaijuState.model:Destroy()
        end
        self.kaijus[kaijuState.model.Name] = nil
    end)
end

return KaijuSystem
