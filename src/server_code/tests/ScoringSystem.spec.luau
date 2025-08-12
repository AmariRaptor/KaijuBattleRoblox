--!strict

return function()
    local ScoringSystem = require(script.Parent.Parent.systems.ScoringSystem)

    local function createMockPlayer()
        local player = Instance.new("Player")
        player.Name = "TestPlayer"
        player.UserId = 11111
        return player
    end

    describe("ScoringSystem", function()
        it("UpdateScore increments player's score and categories", function()
            local player = createMockPlayer()
            local s = ScoringSystem.new()
            s:init()
            s:UpdateScore(player, "KILL", 2)
            local entry = s.scores[player.UserId]
            expect(entry).to.be.ok()
            expect(entry.kills).to.equal(2)
            expect(entry.total).to.equal(2 * s.objectives.KILL)
        end)

        it("GetLeaderboard returns sorted leaderboard", function()
            local p1 = createMockPlayer()
            p1.UserId = 11111
            p1.Name = "P1"
            local p2 = createMockPlayer()
            p2.UserId = 22222
            p2.Name = "P2"

            local s = ScoringSystem.new()
            s:init()
            s:UpdateScore(p1, "KILL", 1)
            s:UpdateScore(p2, "BUILDING", 3)

            local board = s:GetLeaderboard()
            expect(type(board)).to.equal("table")
            expect(#board).to.be.ok()
            if #board >= 2 then
                expect(board[1].totalScore >= board[2].totalScore).to.equal(true)
            end
        end)
    end)
end