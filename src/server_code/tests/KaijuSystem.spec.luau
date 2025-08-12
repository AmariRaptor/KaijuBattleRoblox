--!strict

return function()
    local KaijuSystem = require(script.Parent.Parent.systems.KaijuSystem)
    local Players = game:GetService("Players")
    local TestHelpers = require(script.Parent.TestHelpers)

    describe("KaijuSystem", function()
        it("init creates kaiju folder and events", function()
            local ok = KaijuSystem:init()
            expect(ok).to.equal(true)
            expect(KaijuSystem.kaijuFolder).to.be.ok()
            expect(KaijuSystem.KaijuKilledEvent).to.be.ok()
        end)

        it("spawnKaiju creates a Model with Humanoid and KaijuTag", function()
            local model = KaijuSystem:spawnKaiju(Vector3.new(0,5,0))
            expect(model).to.be.ok()
            expect(model:IsA("Model")).to.equal(true)
            expect(model:FindFirstChildOfClass("Humanoid")).to.be.ok()
            local tag = model:FindFirstChild("KaijuTag")
            expect(tag).to.be.ok()
            expect(type(tag.Value)).to.equal("string")
        end)

        it("applyDamageToPlayer reduces player humanoid health", function()
            local p = TestHelpers.createMockPlayer()
            local char = Instance.new("Model")
            local hrp = Instance.new("Part")
            hrp.Name = "HumanoidRootPart"
            hrp.Parent = char
            local humanoid = Instance.new("Humanoid")
            humanoid.MaxHealth = 100
            humanoid.Health = 100
            humanoid.Parent = char
            char.Parent = workspace
            p.Character = char

            KaijuSystem:applyDamageToPlayer(p, 40, nil, nil)
            expect(humanoid.Health).to.equal(60)
        end)

        it("handleEnergyBeam damages players within range", function()
            KaijuSystem:init()
            local p = TestHelpers.createMockPlayer()
            p.Parent = Players

            local char = Instance.new("Model")
            local hrp = Instance.new("Part")
            hrp.Name = "HumanoidRootPart"
            hrp.Position = Vector3.new(5,5,0)
            hrp.Parent = char
            local humanoid = Instance.new("Humanoid")
            humanoid.MaxHealth = 100
            humanoid.Health = 100
            humanoid.Parent = char
            char.Parent = workspace
            p.Character = char

            local kaiju = KaijuSystem:spawnKaiju(Vector3.new(0,5,0))
            KaijuSystem:handleEnergyBeam(p, kaiju, { target = hrp.Position })

            expect(humanoid.Health).to.be.less.than(100)

            -- cleanup
            if type(p.Destroy) == "function" then p:Destroy() end
            char:Destroy()
        end)

        it("performSwipe damages target and respects cooldown", function()
            local p = TestHelpers.createMockPlayer()
            p.Name = "SwipeTarget"
            p.UserId = 22222
            local char = Instance.new("Model")
            local hrp = Instance.new("Part")
            hrp.Name = "HumanoidRootPart"
            hrp.Position = Vector3.new(1,5,0)
            hrp.Parent = char
            local humanoid = Instance.new("Humanoid")
            humanoid.MaxHealth = 100
            humanoid.Health = 100
            humanoid.Parent = char
            char.Parent = workspace
            p.Character = char

            local kaijuModel = KaijuSystem:spawnKaiju(Vector3.new(0,5,0))
            local state = KaijuSystem.kaijus[kaijuModel.Name]
            state.lastAttackTimes["Swipe"] = os.clock() - 999

            KaijuSystem:performSwipe(state, p)
            expect(humanoid.Health).to.be.less.than(100)

            local after = humanoid.Health

            state.lastAttackTimes["Swipe"] = os.clock()
            KaijuSystem:performSwipe(state, p)
            expect(humanoid.Health).to.equal(after)

            -- cleanup
            char:Destroy()
            if type(p.Destroy) == "function" then p:Destroy() end
        end)

        it("performStomp hits players within range", function()
            KaijuSystem:init()
            local P = Players
            local closeP = TestHelpers.createMockPlayer()
            closeP.Name = "ClosePlayer"
            closeP.UserId = 33333
            closeP.Parent = P

            local farP = TestHelpers.createMockPlayer()
            farP.Name = "FarPlayer"
            farP.UserId = 44444
            farP.Parent = P

            local closeChar = Instance.new("Model")
            local closeHrp = Instance.new("Part")
            closeHrp.Name = "HumanoidRootPart"
            closeHrp.Position = Vector3.new(2,5,0)
            closeHrp.Parent = closeChar
            local closeHum = Instance.new("Humanoid")
            closeHum.MaxHealth = 100
            closeHum.Health = 100
            closeHum.Parent = closeChar
            closeChar.Parent = workspace
            closeP.Character = closeChar

            local farChar = Instance.new("Model")
            local farHrp = Instance.new("Part")
            farHrp.Name = "HumanoidRootPart"
            farHrp.Position = Vector3.new(100,5,0)
            farHrp.Parent = farChar
            local farHum = Instance.new("Humanoid")
            farHum.MaxHealth = 100
            farHum.Health = 100
            farHum.Parent = farChar
            farChar.Parent = workspace
            farP.Character = farChar

            local kaijuModel = KaijuSystem:spawnKaiju(Vector3.new(0,5,0))
            local state = KaijuSystem.kaijus[kaijuModel.Name]
            state.lastAttackTimes["Stomp"] = os.clock() - 999

            KaijuSystem:performStomp(state)

            expect(closeHum.Health).to.be.less.than(100)
            expect(farHum.Health).to.equal(100)

            -- cleanup
            closeChar:Destroy()
            farChar:Destroy()
            if type(closeP.Destroy) == "function" then closeP:Destroy() end
            if type(farP.Destroy) == "function" then farP:Destroy() end
        end)

        it("performCharge damages target when in range", function()
            local p = TestHelpers.createMockPlayer()
            p.Name = "ChargeTarget"
            p.UserId = 55555
            local char = Instance.new("Model")
            local hrp = Instance.new("Part")
            hrp.Name = "HumanoidRootPart"
            hrp.Position = Vector3.new(10,5,0)
            hrp.Parent = char
            local humanoid = Instance.new("Humanoid")
            humanoid.MaxHealth = 100
            humanoid.Health = 100
            humanoid.Parent = char
            char.Parent = workspace
            p.Character = char

            local kaijuModel = KaijuSystem:spawnKaiju(Vector3.new(0,5,0))
            local state = KaijuSystem.kaijus[kaijuModel.Name]
            state.lastAttackTimes["Charge"] = os.clock() - 999

            KaijuSystem:performCharge(state, p)
            expect(humanoid.Health).to.be.less.than(100)

            -- cleanup
            char:Destroy()
            if type(p.Destroy) == "function" then p:Destroy() end
        end)

        it("handleKaijuHealthChanged transitions phases", function()
            local kaijuModel = KaijuSystem:spawnKaiju(Vector3.new(0,5,0))
            local state = KaijuSystem.kaijus[kaijuModel.Name]
            local maxH = state.humanoid.MaxHealth or 100

            KaijuSystem:handleKaijuHealthChanged(state, maxH * 0.7)
            expect(state.phase).to.equal(1)

            KaijuSystem:handleKaijuHealthChanged(state, maxH * 0.5)
            expect(state.phase).to.equal(2)

            KaijuSystem:handleKaijuHealthChanged(state, maxH * 0.2)
            expect(state.phase).to.equal(3)

            -- cleanup
            kaijuModel:Destroy()
        end)
    end)
end