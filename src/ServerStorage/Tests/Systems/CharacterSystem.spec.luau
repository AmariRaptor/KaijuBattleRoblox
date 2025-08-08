--!strict

return function()
    describe("CharacterSystem", function()
        it("should load without errors", function()
            local CharacterSystem = require(game:GetService("ServerScriptService").systems.CharacterSystem)
            expect(CharacterSystem).to.be.ok()
        end)
    end)
end
