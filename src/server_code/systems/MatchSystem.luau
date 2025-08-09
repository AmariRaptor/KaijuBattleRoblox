--!strict
-- MatchSystem.server.luau
-- Manages match lifecycle: StartMatch, EndMatch, player management

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Load GameConfig (best-effort)
local success, GameConfig = pcall(function()
    return require(script.Parent.Parent.Parent.shared.config.GameConfig)
end)

if not success or not GameConfig then
    warn("[MatchSystem] Failed to load GameConfig; using defaults")
    GameConfig = {
        Game = {
            RoundDuration = 600,
            Respawn = {
                Enabled = true,
                RespawnTime = 10,
                ExtraLives = 2,
            },
            MinPlayers = 2,
            MaxPlayers = 10,
        },
    }
end

type PlayerMatchState = {
    player: Player,
    lives: number,
    isEliminated: boolean,
    alive: boolean,
}

local MatchSystem = {}
MatchSystem.__index = MatchSystem

function MatchSystem.new()
    local self = setmetatable({} :: any, MatchSystem)
    -- initial fields (cast where necessary for strict)
    self.state = "lobby"
    self.players = {} :: { [string]: PlayerMatchState }
    self.matchId = nil :: string?
    self.timeRemaining = 0
    self._heartbeatConn = (nil :: RBXScriptConnection?)
    self.MatchStateUpdate = (nil :: RemoteEvent?)

    -- Ensure GameEvents / MatchStateUpdate exist
    local eventsFolder = ReplicatedStorage:FindFirstChild("GameEvents")
    if not eventsFolder then
        eventsFolder = Instance.new("Folder")
        eventsFolder.Name = "GameEvents"
        eventsFolder.Parent = ReplicatedStorage
    end

    local function ensureRemote(folder: Instance, name: string): RemoteEvent
        local existing = folder:FindFirstChild(name)
        if existing and existing:IsA("RemoteEvent") then
            return existing :: RemoteEvent
        end
        local ev = Instance.new("RemoteEvent")
        ev.Name = name
        ev.Parent = folder
        return ev :: RemoteEvent
    end

    self.MatchStateUpdate = ensureRemote(eventsFolder, "MatchStateUpdate")
    self.PlayerInput = ensureRemote(eventsFolder, "PlayerInput")
    self.UseAbilityRequest = ensureRemote(eventsFolder, "UseAbilityRequest")
    self.DamageReport = ensureRemote(eventsFolder, "DamageReport")

    -- Create PowerEvents folder/remotes used by client PowerInput
    local powerFolder = ReplicatedStorage:FindFirstChild("PowerEvents")
    if not powerFolder then
        powerFolder = Instance.new("Folder")
        powerFolder.Name = "PowerEvents"
        powerFolder.Parent = ReplicatedStorage
    end
    local PowerActivated = ensureRemote(powerFolder, "PowerActivated")
    local PowerCooldown = ensureRemote(powerFolder, "PowerCooldown")

    -- Best-effort require other systems for validation/dispatch (do not require KaijuSystem to avoid cyclic deps)
    local CharacterSystem = nil
    local ScoringSystem = nil
    pcall(function()
        local mod = script.Parent:FindFirstChild("CharacterSystem")
        if mod and mod:IsA("ModuleScript") then
            CharacterSystem = require(mod)
        end
    end)
    pcall(function()
        local mod = script.Parent:FindFirstChild("ScoringSystem")
        if mod and mod:IsA("ModuleScript") then
            ScoringSystem = require(mod)
        end
    end)

    -- Ensure BindableEvent for Kaiju death exists in GameEvents and connect (used instead of requiring KaijuSystem)
    local kaijuBindable = eventsFolder:FindFirstChild("KaijuDiedBindable")
    if not (kaijuBindable and kaijuBindable:IsA("BindableEvent")) then
        kaijuBindable = Instance.new("BindableEvent")
        kaijuBindable.Name = "KaijuDiedBindable"
        kaijuBindable.Parent = eventsFolder
    end

    kaijuBindable.Event:Connect(function(kaijuState)
        -- kaijuState is optional; notify match system that Kaiju died
        pcall(function()
            self:onKaijuKilled()
        end)
    end)

    -- PlayerInput handler: record last input server-side for optional reconciliation
    if self.PlayerInput and self.PlayerInput:IsA("RemoteEvent") then
        self.PlayerInput.OnServerEvent:Connect(function(player: Player, payload: { direction: Vector3, timestamp: number, position: Vector3 }?)
            if not player or not payload then return end
            local uid = tostring(player.UserId)
            local pstate = if self.players then self.players[uid] else nil
            if pstate then
                pstate.lastInput = payload
                pstate.lastInputTime = tick()
            end
            -- Potential server-side sanity checks can be added here
        end)
    end

    -- UseAbilityRequest handler: validate via CharacterSystem then dispatch to KaijuSystem / power events
    if self.UseAbilityRequest and self.UseAbilityRequest:IsA("RemoteEvent") then
        self.UseAbilityRequest.OnServerEvent:Connect(function(player: Player, abilityName: string, abilityData: {[string]: any}?)
            if not player or not abilityName then return end

            -- Validate ability via CharacterSystem if available
            local valid, reason = true, nil
            if CharacterSystem and type(CharacterSystem.validateAbilityUse) == "function" then
                local ok, res = pcall(function()
                    return CharacterSystem.validateAbilityUse(player, abilityName)
                end)
                if ok then
                    if type(res) == "boolean" then
                        valid = res
                    elseif type(res) == "table" then
                        valid = true
                    end
                else
                    valid = false
                    reason = tostring(res)
                end
            end

            if not valid then
                warn("[MatchSystem] Ability denied:", player.Name, abilityName, reason)
                return
            end

            -- Broadcast activation for client-side FX
            if PowerActivated and PowerActivated:IsA("RemoteEvent") then
                pcall(function() PowerActivated:FireAllClients(player, abilityName) end)
            end

            -- Kaiju dispatch is handled by KaijuSystem listening to GameEvents.UseAbilityRequest (to avoid module cycles).
            -- MatchSystem validates abilities and triggers PowerActivated/PowerCooldown; KaijuSystem will act on validated requests independently.

            -- Optionally notify clients about cooldowns
            if PowerCooldown and PowerCooldown:IsA("RemoteEvent") then
                local cooldown = nil
                if GameConfig and GameConfig.Abilities and GameConfig.Abilities.Defaults and GameConfig.Abilities.Defaults[abilityName] and GameConfig.Abilities.Defaults[abilityName].Cooldown then
                    cooldown = GameConfig.Abilities.Defaults[abilityName].Cooldown
                end
                if cooldown then
                    pcall(function() PowerCooldown:FireClient(player, abilityName, cooldown) end)
                end
            end
        end)
    end

    -- DamageReport handler (logging / placeholder - server should be authoritative for damage)
    if self.DamageReport and self.DamageReport:IsA("RemoteEvent") then
        self.DamageReport.OnServerEvent:Connect(function(player: Player, dmgData: { targetUserId: number, amount: number }?)
            if not player or not dmgData then return end
            -- For now just log; authoritative damage should be applied by server systems
            warn("[MatchSystem] DamageReport received from", player.Name, dmgData)
        end)
    end

    return self
end

function MatchSystem:addPlayer(player: Player)
    if not player then return end
    local uid = tostring(player.UserId)
    if self.players[uid] then return end

    local extraLives = 2
    if GameConfig and GameConfig.Game and GameConfig.Game.Respawn and GameConfig.Game.Respawn.ExtraLives then
        extraLives = GameConfig.Game.Respawn.ExtraLives
    end

    local pstate: PlayerMatchState = {
        player = player,
        lives = extraLives,
        isEliminated = false,
        alive = true,
    }

    self.players[uid] = pstate

    -- Character death handler
    local function onCharacterAdded(character: Instance?)
        if not character or not character:IsA("Model") then return end
        local humanoidInst = character:FindFirstChildOfClass("Humanoid")
        if humanoidInst and humanoidInst:IsA("Humanoid") then
            local humanoid = humanoidInst :: Humanoid
            humanoid.Died:Connect(function()
                self:onPlayerDied(player)
            end)
        end
    end

    if player.Character and player.Character:IsA("Model") then
        onCharacterAdded(player.Character :: Instance)
    end

    player.CharacterAdded:Connect(function(char: Instance)
        onCharacterAdded(char)
    end)

    self:sendStateUpdate()
end

function MatchSystem:removePlayer(player: Player)
    if not player then return end
    local uid = tostring(player.UserId)
    self.players[uid] = nil
    self:sendStateUpdate()
end

function MatchSystem:onPlayerDied(player: Player)
    if not player then return end
    local uid = tostring(player.UserId)
    local state = self.players[uid]
    if not state then return end

    state.alive = false

    if GameConfig and GameConfig.Game and GameConfig.Game.Respawn and GameConfig.Game.Respawn.Enabled then
        state.lives = (state.lives or 0) - 1
        if state.lives > 0 then
            local respawnTime = (GameConfig and GameConfig.Game and GameConfig.Game.Respawn and GameConfig.Game.Respawn.RespawnTime) or 10
            task.spawn(function()
                task.wait(respawnTime)
                if not self.players or not self.players[uid] or self.players[uid].isEliminated then
                    return
                end
                if player and player.Parent then
                    pcall(function()
                        player:LoadCharacter()
                    end)
                end
                if self.players[uid] then
                    self.players[uid].alive = true
                end
                self:sendStateUpdate()
            end)
        else
            state.isEliminated = true
            if self:areAllPlayersEliminated() then
                self:endMatch("Kaiju")
            end
        end
    else
        state.isEliminated = true
        if self:areAllPlayersEliminated() then
            self:endMatch("Kaiju")
        end
    end

    self:sendStateUpdate()
end

function MatchSystem:areAllPlayersEliminated(): boolean
    for _, pstate in pairs(self.players or {}) do
        if not pstate.isEliminated then
            return false
        end
    end
    return true
end

function MatchSystem:startMatch(duration: number?): (boolean, string?)
    if self.state == "running" then return false, "Match already running" end

    local dur = duration or (GameConfig and GameConfig.Game and GameConfig.Game.RoundDuration) or 600
    self.state = "running"
    self.matchId = tostring(os.time())
    self.timeRemaining = dur

    for _, pstate in pairs(self.players or {}) do
        if pstate.lives == nil then
            pstate.lives = (GameConfig and GameConfig.Game and GameConfig.Game.Respawn and GameConfig.Game.Respawn.ExtraLives) or 2
            pstate.isEliminated = false
            pstate.alive = true
        end
    end

    if self._heartbeatConn then
        pcall(function()
            (self._heartbeatConn :: RBXScriptConnection):Disconnect()
        end)
        self._heartbeatConn = (nil :: RBXScriptConnection?)
    end

    self._heartbeatConn = (RunService.Heartbeat:Connect(function(dt: number)
        if self.state ~= "running" then return end
        self.timeRemaining = math.max(0, (self.timeRemaining or 0) - dt)
        if self.timeRemaining <= 0 then
            self:handleTimeout()
        end
    end) :: RBXScriptConnection)

    self:sendStateUpdate()
    print("[MatchSystem] Match started:", self.matchId, "duration:", dur)
    return true, nil
end

function MatchSystem:handleTimeout()
    if self.state ~= "running" then return end
    self:endMatch("Timeout")
end

function MatchSystem:endMatch(result: string?)
    if self.state == "ended" then return end
    self.state = "ended"
    if self._heartbeatConn then
        pcall(function()
            (self._heartbeatConn :: RBXScriptConnection):Disconnect()
        end)
        self._heartbeatConn = (nil :: RBXScriptConnection?)
    end

    local payload = {
        matchId = self.matchId,
        result = result or "Unknown",
        players = {},
    }
    for uid, pstate in pairs(self.players or {}) do
        table.insert(payload.players, {
            userId = tonumber(uid),
            lives = pstate.lives,
            isEliminated = pstate.isEliminated,
            alive = pstate.alive,
        })
    end

    if self.MatchStateUpdate then
        self.MatchStateUpdate:FireAllClients(payload)
    end

    print("[MatchSystem] Match ended:", self.matchId, "result:", result)
end

function MatchSystem:sendStateUpdate()
    local payload = {
        matchId = self.matchId,
        state = self.state,
        timeRemaining = math.floor(self.timeRemaining or 0),
        players = {},
    }
    for uid, pstate in pairs(self.players or {}) do
        table.insert(payload.players, {
            userId = tonumber(uid),
            lives = pstate.lives,
            isEliminated = pstate.isEliminated,
            alive = pstate.alive,
        })
    end
    if self.MatchStateUpdate then
        self.MatchStateUpdate:FireAllClients(payload)
    end
end

function MatchSystem:onKaijuKilled()
    self:endMatch("Players")
end

return MatchSystem