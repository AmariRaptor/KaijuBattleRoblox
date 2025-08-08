--!strict
-- ScoringSystem.server.luau
-- Handles all scoring-related functionality in the game

-- Services
local Players = game:GetService("Players")

-- Types
type Player = typeof(Players.LocalPlayer)
type ScoreEntry = {
    total: number,
    kills: number,
    buildings: number,
    support: number,
    survival: number
}

local ScoringSystem = {}
ScoringSystem.__index = ScoringSystem

-- Constructor
function ScoringSystem.new()
    local self = setmetatable({}, ScoringSystem)
    
    -- Initialize scores table
    self.scores = {}
    
    -- Define scoring objectives with point values
    self.objectives = {
        KILL = 10,
        BUILDING_DESTROY = 20,
        SUPPORT = 5,
        SURVIVAL = 1
    }
    
    return self
end

-- Standardized init method (for compatibility with Main script)
function ScoringSystem:init(): boolean
    print("🔄 Initializing ScoringSystem...")
    -- Already initialized in new()
    print("✅ ScoringSystem initialized successfully")
    return true
end

-- Updates a player's score based on the action performed
-- @param player The player whose score to update
-- @param action The type of action that was performed ("KILL", "BUILDING", "SUPPORT", "SURVIVAL")
-- @param amount The multiplier for the score (defaults to 1)
function ScoringSystem:UpdateScore(player, action, amount)
    local userId = player.UserId
    local scoreAmount = amount or 1
    
    -- Initialize player's score entry if it doesn't exist
    if not self.scores[userId] then
        self.scores[userId] = {
            total = 0,
            kills = 0,
            buildings = 0,
            support = 0,
            survival = 0
        }
    end
    
    local score = self.scores[userId]
    
    -- Update score based on action type
    if action == "KILL" then
        score.kills = score.kills + scoreAmount
        score.total = score.total + (self.objectives.KILL * scoreAmount)
    elseif action == "BUILDING" then
        score.buildings = score.buildings + scoreAmount
        score.total = score.total + (self.objectives.BUILDING_DESTROY * scoreAmount)
    elseif action == "SUPPORT" then
        score.support = score.support + scoreAmount
        score.total = score.total + (self.objectives.SUPPORT * scoreAmount)
    elseif action == "SURVIVAL" then
        score.survival = score.survival + scoreAmount
        score.total = score.total + (self.objectives.SURVIVAL * scoreAmount)
    else
        warn(string.format("[ScoringSystem] Unknown action type: %s", tostring(action)))
    end
end

-- Gets the current leaderboard sorted by total score
-- @return A sorted table of leaderboard entries
function ScoringSystem:GetLeaderboard()
    local leaderboard = {}
    
    -- Convert scores to leaderboard entries
    for userId, stats in pairs(self.scores) do
        table.insert(leaderboard, {
            userId = userId,
            totalScore = stats.total,
            kills = stats.kills,
            buildings = stats.buildings,
            support = stats.support,
            survival = stats.survival
        })
    end
    
    -- Sort by total score in descending order
    table.sort(leaderboard, function(a, b)
        return a.totalScore > b.totalScore
    end)
    
    return leaderboard
end

return ScoringSystem
