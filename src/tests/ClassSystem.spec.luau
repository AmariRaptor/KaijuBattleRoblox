--!strict

-- Import TestEZ globals
local TestEZ = {}

-- Get the TestEZ module from ServerScriptService
local function getTestEZ()
    local success, result = pcall(function()
        return game:GetService("ServerScriptService").TestEZ
    end)
    
    if not success then
        warn("Could not find TestEZ in ServerScriptService")
        return nil
    end
    
    return result
end

-- Get the ClassSystem module
local function getClassSystem()
    local success, result = pcall(function()
        return require(game:GetService("ServerScriptService").systems.ClassSystem)
    end)
    
    if not success then
        warn("Could not require ClassSystem:", result)
        return nil
    end
    
    return result
end

-- Main test function
return function()
    local Players = game:GetService("Players")
    local TestEZ = getTestEZ()
    local ClassSystem = getClassSystem()
    
    if not TestEZ or not ClassSystem then
        warn("Skipping tests due to missing dependencies")
        return
    end
    
    -- Import TestEZ functions
    local describe = TestEZ.TestBootstrap.describe
    local it = TestEZ.TestBootstrap.it
    local expect = TestEZ.Expectation.new
    
    describe("ClassSystem", function()
        describe("onPlayerAdded", function()
            it("should assign a valid class to a player", function()
                -- Setup
                local mockPlayer = Instance.new("Folder")
                mockPlayer.Name = "TestPlayer"

                -- Run
                ClassSystem.onPlayerAdded(mockPlayer)

                -- Verify
                local playerClassValue = mockPlayer:FindFirstChild("PlayerClass")
                expect(playerClassValue).to.be.ok()
                expect(playerClassValue:IsA("StringValue")).to.equal(true)

                local CLASSES = {"Kaiju", "Guardian", "Engineer"}
                local classIsValid = table.find(CLASSES, playerClassValue.Value) ~= nil
                expect(classIsValid).to.equal(true)
            end)

            it("should not overwrite existing PlayerClass value", function()
                -- Setup
                local mockPlayer = Instance.new("Folder")
                mockPlayer.Name = "TestPlayer"
                local existingClass = Instance.new("StringValue")
                existingClass.Name = "PlayerClass"
                existingClass.Value = "Kaiju"
                existingClass.Parent = mockPlayer

                -- Run
                ClassSystem.onPlayerAdded(mockPlayer)

                -- Verify
                local playerClassValue = mockPlayer:FindFirstChild("PlayerClass")
                expect(playerClassValue).to.be.ok()
                expect(playerClassValue.Value).to.equal("Kaiju")
            end)
        end)
    end)
end
