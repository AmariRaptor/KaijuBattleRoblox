--!strict

return function()
    local ClassSystem = require(script.Parent.Parent.systems.ClassSystem)

    local function createMockPlayer()
        local player = Instance.new("Player")
        player.Name = "TestPlayer"
        player.UserId = 12345
        return player
    end

    describe("ClassSystem", function()
        it("assignRandomClass assigns a PlayerClass StringValue and returns class name", function()
            local p = createMockPlayer()
            local className = ClassSystem.assignRandomClass(p)
            expect(type(className)).to.equal("string")
            local pv = p:FindFirstChild("PlayerClass")
            expect(pv).to.be.ok()
            expect(pv:IsA("StringValue")).to.equal(true)
            expect(pv.Value).to.equal(className)
        end)
    end)

end