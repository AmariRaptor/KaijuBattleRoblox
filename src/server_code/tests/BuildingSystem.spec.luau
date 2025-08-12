--!strict

return function()
    local BuildingSystem = require(script.Parent.Parent.systems.BuildingSystem)

    describe("BuildingSystem", function()
        it("init creates Buildings folder", function()
            -- ensure no initial Buildings folder
            local bf = workspace:FindFirstChild("Buildings")
            if bf then bf:Destroy() end
            local ok = BuildingSystem:init()
            expect(ok).to.equal(true)
            expect(workspace:FindFirstChild("Buildings")).to.be.ok()
        end)

        it("_createBuildingModel returns model with PrimaryPart", function()
            local pos = Vector3.new(0, 5, 0)
            local model = BuildingSystem:_createBuildingModel("SKYSCRAPER", pos)
            expect(model).to.be.ok()
            expect(model.PrimaryPart).to.be.ok()
            expect(model.PrimaryPart.Size).to.equal(BuildingSystem.BUILDING_TYPES.SKYSCRAPER.SIZE or model.PrimaryPart.Size)
            expect(model.Parent).to.equal(workspace:FindFirstChild("Buildings"))
        end)

        it("_applyBuildingEffects adds effects to PrimaryPart", function()
            local pos = Vector3.new(10, 5, 0)
            local model = BuildingSystem:_createBuildingModel("HOSPITAL", pos)
            expect(model.PrimaryPart:FindFirstChildOfClass("PointLight")).to.equal(nil)
            local effects = { LIGHTS = true, HEALING_AURA = true }
            BuildingSystem:_applyBuildingEffects(model, effects)
            expect(model.PrimaryPart:FindFirstChildOfClass("PointLight")).to.be.ok()
            expect(model.PrimaryPart:FindFirstChildOfClass("ParticleEmitter")).to.be.ok()
        end)

        it("_createBuildingModel errors on invalid type", function()
            local ok, _ = pcall(function()
                BuildingSystem:_createBuildingModel("INVALID", Vector3.new(0,0,0))
            end)
            expect(ok).to.equal(false)
        end)
    end)
end
