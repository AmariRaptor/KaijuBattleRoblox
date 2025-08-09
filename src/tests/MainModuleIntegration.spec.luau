--!strict

return function()
    local ServerScriptService = game:GetService("ServerScriptService")

    describe("MainModule integration", function()
        it("requires and initializes MainModule without error", function()
            local mainModuleInstance = ServerScriptService:FindFirstChild("MainModule")
            assert(mainModuleInstance, "MainModule not found in ServerScriptService")
            local ok, moduleOrErr = pcall(require, mainModuleInstance)
            expect(ok).to.equal(true)
            local MainModule = moduleOrErr

            -- If there is isInitialized method, check its state or call init
            local isInitialized = nil
            if type(MainModule.isInitialized) == "function" then
                local ok2, val = pcall(MainModule.isInitialized, MainModule)
                if ok2 then isInitialized = val end
            end

            if not isInitialized and type(MainModule.init) == "function" then
                local initOk, initRes = pcall(MainModule.init, MainModule)
                expect(initOk).to.equal(true)
            end

            -- After init, ensure getInitializedSystems returns a table if present
            if type(MainModule.getInitializedSystems) == "function" then
                local ok3, systems = pcall(MainModule.getInitializedSystems, MainModule)
                expect(ok3).to.equal(true)
                expect(type(systems)).to.equal("table")
            end
        end)
    end)
end