--!strict
-- ScoringSystem.spec.luau
-- Test suite for ScoringSystem

local TestEZ = require(game:GetService("ReplicatedStorage").TestEZ)

local function testScoringSystem()
    -- Mock the ScoringSystem
    local ScoringSystem = {
        scores = {},
        objectives = {
            KILL = 10,
            BUILDING_DESTROY = 20,
            SUPPORT = 5,
            SURVIVAL = 1
        },
        
        UpdateScore = function(self, player, action, amount)
            amount = amount or 1
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
        end,
        
        GetLeaderboard = function(self)
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
    }
    
    -- Test data
    local testPlayers = {
        { UserId = 1, Name = "Player1" },
        { UserId = 2, Name = "Player2" },
        { UserId = 3, Name = "Player3" }
    }
    
    -- Test cases
    local testCases = {
        {
            description = "should initialize scores for a new player",
            action = function()
                ScoringSystem:UpdateScore(testPlayers[1], "KILL")
                local score = ScoringSystem.scores[testPlayers[1].UserId]
                return score and score.total == 10 and score.kills == 1
            end
        },
        {
            description = "should accumulate scores for multiple actions",
            action = function()
                ScoringSystem:UpdateScore(testPlayers[1], "KILL") -- +10
                ScoringSystem:UpdateScore(testPlayers[1], "BUILDING") -- +20
                local score = ScoringSystem.scores[testPlayers[1].UserId]
                return score and score.total == 30 and score.kills == 2 and score.buildings == 1
            end
        },
        {
            description = "should handle multiple players independently",
            action = function()
                ScoringSystem:UpdateScore(testPlayers[2], "SUPPORT") -- +5
                ScoringSystem:UpdateScore(testPlayers[3], "SURVIVAL") -- +1
                
                local score2 = ScoringSystem.scores[testPlayers[2].UserId]
                local score3 = ScoringSystem.scores[testPlayers[3].UserId]
                
                return score2 and score2.total == 5 and score2.support == 1
                    and score3 and score3.total == 1 and score3.survival == 1
            end
        },
        {
            description = "should return a sorted leaderboard",
            action = function()
                -- Clear and reset test data
                ScoringSystem.scores = {}
                
                -- Add scores in non-sorted order
                ScoringSystem:UpdateScore(testPlayers[1], "KILL") -- 10
                ScoringSystem:UpdateScore(testPlayers[2], "BUILDING") -- 20
                ScoringSystem:UpdateScore(testPlayers[3], "SUPPORT") -- 5
                
                local leaderboard = ScoringSystem:GetLeaderboard()
                
                -- Leaderboard should be sorted by totalScore in descending order
                return #leaderboard == 3
                    and leaderboard[1].totalScore == 20 -- Player 2 with BUILDING
                    and leaderboard[2].totalScore == 10 -- Player 1 with KILL
                    and leaderboard[3].totalScore == 5  -- Player 3 with SUPPORT
            end
        },
        {
            description = "should handle custom amounts for scoring",
            action = function()
                -- Clear and reset test data
                ScoringSystem.scores = {}
                
                -- Test with custom amounts
                ScoringSystem:UpdateScore(testPlayers[1], "KILL", 3) -- 10 * 3 = 30
                ScoringSystem:UpdateScore(testPlayers[1], "SUPPORT", 2) -- 5 * 2 = 10
                
                local score = ScoringSystem.scores[testPlayers[1].UserId]
                
                return score and score.total == 40 -- 30 + 10
                    and score.kills == 3
                    and score.support == 2
            end
        }
    }
    
    -- Run tests
    local results = {}
    
    for i, testCase in ipairs(testCases) do
        local success, result = pcall(testCase.action)
        table.insert(results, {
            success = success and result == true,
            message = success and testCase.description or ("Test error: " .. tostring(result)),
            error = not success and tostring(result)
        })
    end
    
    return results
end

-- Run tests and format results
local results = testScoringSystem()
local successCount = 0
local failureCount = 0

for _, result in ipairs(results) do
    if result.success then
        successCount = successCount + 1
        print("✅ " .. result.message)
    else
        failureCount = failureCount + 1
        print("❌ " .. result.message)
        if result.error then
            print("   Error: " .. result.error)
        end
    end
end

print("\n=== ScoringSystem Test Summary ===")
print(string.format("Total Tests: %d", #results))
print(string.format("✅ Passed: %d", successCount))
print(string.format("❌ Failed: %d", failureCount))

-- Return overall result
return {
    success = failureCount == 0,
    message = string.format("ScoringSystem tests completed. %d passed, %d failed", successCount, failureCount)
}
