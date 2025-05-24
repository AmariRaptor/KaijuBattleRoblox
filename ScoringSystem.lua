-- ScoringSystem.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MainModule = require(ReplicatedStorage:WaitForChild("MainModule"))

local ScoringSystem = {}

function ScoringSystem:Init()
    self.scores = {}
    self.objectives = {
        KILL = 10,
        BUILDING_DESTROY = 20,
        SUPPORT = 5,
        SURVIVAL = 1
    }
end

function ScoringSystem:UpdateScore(player, action, amount)
    if not self.scores[player.UserId] then
        self.scores[player.UserId] = {
            total = 0,
            kills = 0,
            buildings = 0,
            support = 0,
            survival = 0
        }
    end
    
    local score = self.scores[player.UserId]
    
    if action == "KILL" then
        score.kills = score.kills + 1
        score.total = score.total + self.objectives.KILL * amount
    elseif action == "BUILDING" then
        score.buildings = score.buildings + 1
        score.total = score.total + self.objectives.BUILDING_DESTROY * amount
    elseif action == "SUPPORT" then
        score.support = score.support + 1
        score.total = score.total + self.objectives.SUPPORT * amount
    elseif action == "SURVIVAL" then
        score.survival = score.survival + 1
        score.total = score.total + self.objectives.SURVIVAL * amount
    end
end

function ScoringSystem:GetLeaderboard()
    local leaderboard = {}
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
    
    -- Sort by total score
    table.sort(leaderboard, function(a, b)
        return a.totalScore > b.totalScore
    end)
    
    return leaderboard
end

return ScoringSystem
