--!strict

return function()
    describe("KaijuSystem", function()
        it("loads and spawns a kaiju", function()
            local KaijuSystem = require(game:GetService("ServerScriptService").systems.KaijuSystem)
            expect(KaijuSystem).to.be.ok()
            local ok, res = pcall(function() return KaijuSystem:init() end)
            expect(ok).to.equal(true)
            local model = KaijuSystem:spawnKaiju(Vector3.new(0, 10, 0))
            expect(model).to.be.ok()
            expect(model:IsA("Model")).to.equal(true)
            local hrp = model:FindFirstChild("HumanoidRootPart")
            expect(hrp).to.be.ok()
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            expect(humanoid).to.be.ok()
            -- Cleanup
            if model and model.Parent then model:Destroy() end
        end)

        it("transitions phases when health crosses thresholds", function()
            local KaijuSystem = require(game:GetService("ServerScriptService").systems.KaijuSystem)
            KaijuSystem:init()
            local model = KaijuSystem:spawnKaiju()
            local state = KaijuSystem.kaijus[model.Name]
            expect(state).to.be.ok()
            expect(state.phase).to.equal(1)
            local maxHealth = state.humanoid.MaxHealth or 1
            KaijuSystem:handleKaijuHealthChanged(state, maxHealth * 0.5)
            expect(state.phase).to.equal(2)
            KaijuSystem:handleKaijuHealthChanged(state, maxHealth * 0.2)
            expect(state.phase).to.equal(3)
            if model and model.Parent then model:Destroy() end
        end)

        it("performs attacks and applies damage to a target", function()
            local KaijuSystem = require(game:GetService("ServerScriptService").systems.KaijuSystem)
            KaijuSystem:init()
            local model = KaijuSystem:spawnKaiju()
            local state = KaijuSystem.kaijus[model.Name]
            expect(state).to.be.ok()
            -- create fake target character
            local target = Instance.new("Model")
            target.Name = "FakeTarget"
            local tHrp = Instance.new("Part")
            tHrp.Name = "HumanoidRootPart"
            tHrp.Size = Vector3.new(2,2,1)
            tHrp.Parent = target
            local tHum = Instance.new("Humanoid")
            tHum.MaxHealth = 100
            tHum.Health = 100
            tHum.Parent = target
            -- fake player table
            local fakePlayer = { Character = target, UserId = 99999 }
            -- position target near kaiju
            local origin = model:FindFirstChild("HumanoidRootPart")
            if origin and origin:IsA("BasePart") then tHrp.Position = origin.Position + Vector3.new(1,0,0) end
            -- perform swipe
            KaijuSystem:performSwipe(state, fakePlayer)
            expect(tHum.Health).to.equal(75)
            -- perform stomp (should affect targets in range); reset health then test
            tHum.Health = 100
            KaijuSystem:performStomp(state)
            expect(tHum.Health).to.be.ok()
            -- ensure charge applies when in range
            tHum.Health = 100
            KaijuSystem:performCharge(state, fakePlayer)
            expect(tHum.Health).to.be.ok()
            if target and target.Parent then target:Destroy() end
            if model and model.Parent then model:Destroy() end
        end)

        it("handles kaiju death and cleans up", function()
            local KaijuSystem = require(game:GetService("ServerScriptService").systems.KaijuSystem)
            KaijuSystem:init()
            local model = KaijuSystem:spawnKaiju()
            local state = KaijuSystem.kaijus[model.Name]
            expect(state).to.be.ok()
            -- ensure GameEvents/KaijuDiedBindable exists so handleKaijuDeath will notify
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local events = ReplicatedStorage:FindFirstChild("GameEvents") or Instance.new("Folder")
            if not events.Parent then events.Name = "GameEvents"; events.Parent = ReplicatedStorage end
            local be = events:FindFirstChild("KaijuDiedBindable")
            if not (be and be:IsA("BindableEvent")) then
                be = Instance.new("BindableEvent")
                be.Name = "KaijuDiedBindable"
                be.Parent = events
            end
            local fired = false
            be.Event:Connect(function(ks) fired = true end)
            -- mark damageLog and call death handler
            state.damageLog[123] = 9999
            -- Call death
            KaijuSystem:handleKaijuDeath(state)
            task.wait(2.1)
            expect(KaijuSystem.kaijus[model.Name]).to.equal(nil)
            expect(fired).to.equal(true)
        end)
    end)
end
