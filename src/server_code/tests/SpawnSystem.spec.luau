--!strict

return function()
    local SpawnSystem = require(script.Parent.Parent.systems.SpawnSystem)

    local function createMockPlayer()
        local player = Instance.new("Player")
        player.Name = "TestPlayer"
        player.UserId = 99999
        return player
    end

    describe("SpawnSystem", function()
        it("initializes and creates props folder and props", function()
            local ok = SpawnSystem:init()
            expect(ok).to.equal(true)
            local propsFolder = SpawnSystem.propsFolder
            expect(propsFolder).to.be.ok()
            local children = propsFolder and propsFolder:GetChildren() or {}
            expect(type(children)).to.equal("table")
            expect(#children >= 0).to.equal(true)
        end)

        it("spawnKaiju returns a Model with a Humanoid", function()
            local model = SpawnSystem:spawnKaiju(Vector3.new(0,5,0))
            expect(model).to.be.ok()
            expect(model:IsA("Model")).to.equal(true)
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            expect(humanoid).to.be.ok()
        end)
    end)
end