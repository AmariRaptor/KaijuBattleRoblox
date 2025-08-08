--!strict

return function()
    describe("KaijuSystem", function()
        it("should load without errors", function()
            local KaijuSystem = require(game:GetService("ServerScriptService").systems.KaijuSystem)
            expect(KaijuSystem).to.be.ok()
        end)
    end)
end
