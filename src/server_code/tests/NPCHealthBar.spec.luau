--!strict

return function()
    local NPCHealthBar = require(script.Parent.Parent.systems.NPCHealthBar)

    describe("NPCHealthBar", function()
        it("init returns true", function()
            local ok = NPCHealthBar:init()
            expect(ok).to.equal(true)
        end)

        it("registerNPC initializes state and optionally creates gui", function()
            local model = Instance.new("Model")
            local part = Instance.new("Part")
            part.Name = "PrimaryPart"
            part.Parent = model
            model.PrimaryPart = part
            model.Parent = workspace

            local state = NPCHealthBar:registerNPC(model, 100)
            expect(state).to.be.ok()
            expect(type(state.health)).to.equal("number")
            expect(state.health).to.equal(100)

            -- cleanup
            model:Destroy()
        end)

        it("getHealthPercentage returns correct fractions", function()
            local model = Instance.new("Model")
            local part = Instance.new("Part")
            part.Name = "PrimaryPart"
            part.Parent = model
            model.PrimaryPart = part
            model.Parent = workspace

            local s = NPCHealthBar:registerNPC(model, 200)
            expect(NPCHealthBar:getHealthPercentage(model)).to.equal(1)

            NPCHealthBar:updateHealth(model, 100)
            expect(NPCHealthBar:getHealthPercentage(model)).to.equal(0.5)

            NPCHealthBar:updateHealth(model, 0)
            expect(NPCHealthBar:getHealthPercentage(model)).to.equal(0)

            -- cleanup
            model:Destroy()
        end)

        it("applyDamage reduces health and clamps at zero", function()
            local model = Instance.new("Model")
            local part = Instance.new("Part")
            part.Name = "PrimaryPart"
            part.Parent = model
            model.PrimaryPart = part
            model.Parent = workspace

            local s = NPCHealthBar:registerNPC(model, 50)
            local remaining = NPCHealthBar:applyDamage(model, 20)
            expect(remaining).to.equal(30)
            remaining = NPCHealthBar:applyDamage(model, 50)
            expect(remaining).to.equal(0)

            model:Destroy()
        end)

        it("destroyNPC removes state and GUI", function()
            local model = Instance.new("Model")
            local part = Instance.new("Part")
            part.Name = "PrimaryPart"
            part.Parent = model
            model.PrimaryPart = part
            model.Parent = workspace

            local s = NPCHealthBar:registerNPC(model, 30)
            expect(NPCHealthBar:getState(model)).to.be.ok()

            NPCHealthBar:destroyNPC(model)
            expect(NPCHealthBar:getState(model)).to.equal(nil)

            -- cleanup
            model:Destroy()
        end)
    end)
end