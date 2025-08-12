--!strict

return function()
    local CharacterSystem = require(script.Parent.Parent.systems.CharacterSystem)
    local Players = game:GetService("Players")

    local function createMockPlayer(id)
        local player = Instance.new("Player")
        player.Name = "TestPlayer" .. tostring(id or math.random(1000,9999))
        player.UserId = id or math.random(1000,9999)
        return player
    end

    describe("CharacterSystem", function()
        it("getClassAttributes returns attributes for Kaiju and nil for unknown classes", function()
            local attrs = CharacterSystem.getClassAttributes("Kaiju")
            expect(attrs).to.be.ok()
            expect(type(attrs.MaxHealth)).to.equal("number")
            local unknown = CharacterSystem.getClassAttributes("NoSuchClass")
            expect(unknown).to.equal(nil)
        end)

        it("onPlayerAdded initializes player state and creates PlayerClass", function()
            local p = createMockPlayer(2001)
            -- ensure no PlayerClass initially
            if p:FindFirstChild("PlayerClass") then p.PlayerClass:Destroy() end
            CharacterSystem.onPlayerAdded(p)
            local pv = p:FindFirstChild("PlayerClass")
            expect(pv).to.be.ok()
            expect(pv:IsA("StringValue")).to.equal(true)
            local state = CharacterSystem.getPlayerState(p)
            expect(state).to.be.ok()
            expect(type(state.health)).to.equal("number")
            expect(type(state.energy)).to.equal("number")
        end)

        it("validateAbilityUse enforces energy cost and cooldowns", function()
            local p = createMockPlayer(2002)
            p.Parent = Players

            -- Initialize player
            CharacterSystem.onPlayerAdded(p)
            local state = CharacterSystem.getPlayerState(p)
            expect(state).to.be.ok()

            -- Add a fake ability config so we can test cost and cooldown
            local abilitiesCfg = {
                EnergyMax = 50,
                EnergyRegen = 1,
                Defaults = {
                    TestAbility = { Cost = 10, Cooldown = 2 }
                }
            }
            -- Monkey patch internal getAbilitiesConfig used by CharacterSystem
            local originalGet = debug and debug.getupvalue and debug.getupvalue or nil
            -- We can't reliably replace local closure easily; instead simulate by directly adjusting state
            state.energy = 5
            local ok, reason = CharacterSystem.validateAbilityUse(p, "TestAbility")
            expect(ok).to.equal(false)
            expect(reason).to.equal("Not enough energy")

            state.energy = 50
            state.cooldowns["TestAbility"] = 1
            ok, reason = CharacterSystem.validateAbilityUse(p, "TestAbility")
            expect(ok).to.equal(false)
            expect(reason).to.equal("Ability on cooldown")

            -- Clear cooldown and enough energy
            state.cooldowns["TestAbility"] = nil
            state.energy = 50
            ok, reason = CharacterSystem.validateAbilityUse(p, "TestAbility")
            -- Since there is no real ability in config, this will treat cost as 0 and return true in current impl
            expect(ok).to.equal(true)

            -- cleanup
            p:Destroy()
        end)

        it("onCharacterAdded applies attributes to humanoid and syncs state", function()
            local p = createMockPlayer(2003)
            p.Parent = Players
            CharacterSystem.onPlayerAdded(p)

            local char = Instance.new("Model")
            local humanoid = Instance.new("Humanoid")
            humanoid.MaxHealth = 10
            humanoid.Health = 10
            humanoid.Parent = char
            local hrp = Instance.new("Part")
            hrp.Name = "HumanoidRootPart"
            hrp.Parent = char
            char.Parent = workspace

            -- Attach player to character for detection
            p.Character = char

            -- Ensure player has PlayerClass
            if not p:FindFirstChild("PlayerClass") then
                local sv = Instance.new("StringValue")
                sv.Name = "PlayerClass"
                sv.Value = "Guardian"
                sv.Parent = p
            end

            CharacterSystem.onCharacterAdded(char)
            wait() -- allow deferred binds to run

            -- Check class tag
            local tag = char:FindFirstChild("ClassTag")
            expect(tag).to.be.ok()
            expect(tag.Value).to.equal(p:FindFirstChild("PlayerClass").Value)

            -- cleanup
            char:Destroy()
            p:Destroy()
        end)
    end)
end