--!strict

return function()
    local ServerScriptService = game:GetService("ServerScriptService")
    local mainModuleInstance = ServerScriptService:FindFirstChild("MainModule")
    assert(mainModuleInstance, "MainModule not found in ServerScriptService for tests")
    local MainModule = require(mainModuleInstance)

    describe("MainModule", function()
        it("getConfig returns expected shape", function()
            local cfg = MainModule.getConfig()
            expect(type(cfg)).to.equal("table")
            expect(type(cfg.debug)).to.equal("boolean")
            expect(type(cfg.maxPlayers)).to.equal("number")
            expect(type(cfg.defaultSettings)).to.equal("table")
            expect(type(cfg.defaultSettings.volume)).to.equal("number")
        end)

        it("updateConfig rejects invalid keys", function()
            local ok, err = MainModule.updateConfig({notAKey = 1})
            expect(ok).to.equal(false)
            expect(type(err)).to.equal("string")
        end)

        it("updateConfig merges nested updates", function()
            local ok = MainModule.updateConfig({defaultSettings = {volume = 0.3}})
            expect(ok).to.equal(true)
            local cfg = MainModule.getConfig()
            expect(cfg.defaultSettings.volume).to.equal(0.3)
        end)
    end)
end