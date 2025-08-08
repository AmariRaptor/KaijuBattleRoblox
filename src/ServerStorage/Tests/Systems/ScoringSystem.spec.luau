--!strict

return function()
    describe("ScoringSystem", function()
        it("should load without errors", function()
            local ScoringSystem = require(game:GetService("ServerScriptService").systems.ScoringSystem)
            expect(ScoringSystem).to.be.ok()
        end)
    end)
end
