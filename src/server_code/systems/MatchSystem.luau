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

function MatchSystem.new(): any
    local self = setmetatable({} :: any, MatchSystem)
    self.state = "lobby"
    self.players = {} :: { [string]: PlayerMatchState }
    self.matchId = nil :: string?
    self.timeRemaining = 0
    self._heartbeatConn = nil :: RBXScriptConnection?
    self.MatchStateUpdate = nil :: RemoteEvent?

    -- Ensure GameEvents / MatchStateUpdate exist
    local eventsFolder = ReplicatedStorage:FindFirstChild("GameEvents")
    if not eventsFolder then
        eventsFolder = Instance.new("Folder")
        eventsFolder.Name = "GameEvents"
        eventsFolder.Parent = ReplicatedStorage
    end

    local matchEvent = eventsFolder:FindFirstChild("MatchStateUpdate")
    if matchEvent and matchEvent:IsA("RemoteEvent") then
        self.MatchStateUpdate = matchEvent :: RemoteEvent
    else
        local ev = Instance.new("RemoteEvent")
        ev.Name = "MatchStateUpdate"
        ev.Parent = eventsFolder
        self.MatchStateUpdate = ev :: RemoteEvent
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
    local function onCharacterAdded(character)
        if not character or not character:IsA("Model") then return end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid:IsA("Humanoid") then
            humanoid.Died:Connect(function()
                self:onPlayerDied(player)
            end)
        end
    end

    if player.Character and player.Character:IsA("Model") then
        onCharacterAdded(player.Character)
    end

    player.CharacterAdded:Connect(function(char)
        -- slight defer to allow character to fully setup
        task.defer(function()
            onCharacterAdded(char)
        end)
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
            local respawnTime = (GameConfig.Game.Respawn.RespawnTime) or 10
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
            self._heartbeatConn:Disconnect()
        end)
        self._heartbeatConn = nil
    end

    self._heartbeatConn = RunService.Heartbeat:Connect(function(dt)
        if self.state ~= "running" then return end
        self.timeRemaining = math.max(0, (self.timeRemaining or 0) - dt)
        if self.timeRemaining <= 0 then
            self:handleTimeout()
        end
    end)

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
            self._heartbeatConn:Disconnect()
        end)
        self._heartbeatConn = nil
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
        pcall(function()
            self.MatchStateUpdate:FireAllClients(payload)
        end)
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
        pcall(function()
            self.MatchStateUpdate:FireAllClients(payload)
        end)
    end
end

function MatchSystem:onKaijuKilled()
    self:endMatch("Players")
end

return MatchSystem