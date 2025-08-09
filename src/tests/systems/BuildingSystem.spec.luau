--!strict
--!global describe, it, expect, beforeEach, afterEach




return function()
    local ServerScriptService = game:GetService("ServerScriptService")
    local CollectionService = game:GetService("CollectionService")

    local BuildingSystem = require(ServerScriptService.systems.BuildingSystem)

    describe("BuildingSystem", function()
        local mockBuildingModel: Model

        beforeEach(function()
            -- Reset the system before each test to ensure a clean state
            BuildingSystem.Buildings = {}
            BuildingSystem.PartToBuildingMap = {}

            mockBuildingModel = Instance.new("Model")
            mockBuildingModel.Name = "MockBuilding"

            local part1 = Instance.new("Part")
            part1.Name = "Part1"
            part1.Parent = mockBuildingModel
            local part2 = Instance.new("Part")
            part2.Name = "Part2"
            part2.Parent = mockBuildingModel

            CollectionService:AddTag(mockBuildingModel, "Building")
        end)

        afterEach(function()
            if mockBuildingModel and mockBuildingModel.Parent then
                mockBuildingModel:Destroy()
            end
        end)

        it("should initialize and find tagged buildings", function()
            BuildingSystem:init()
            expect(#BuildingSystem.Buildings).to.equal(1)
            expect(BuildingSystem.Buildings[1].Model).to.equal(mockBuildingModel)
        end)

        it("should apply damage to a building part", function()
            BuildingSystem:init()
            local building = BuildingSystem.Buildings[1]
            local initialHealth = building.Health
            local partToDamage = building.Model:FindFirstChild("Part1")

            BuildingSystem:OnDamage(partToDamage, 50)

            expect(building.Health).to.equal(initialHealth - 50)
            expect(building.State).to.equal("Damaged")
        end)

        it("should detach a part when its health is depleted", function()
            BuildingSystem:init()
            local building = BuildingSystem.Buildings[1]
            local partToDestroy = building.Model:FindFirstChild("Part1")

            -- Damage it enough to destroy it (default health is 100)
            BuildingSystem:OnDamage(partToDestroy, 100)

            -- The part should be destroyed and removed from the model
            expect(partToDestroy.Parent).to.equal(nil)
            -- The building's part map should no longer track it
            expect(building.Parts[partToDestroy]).to.equal(nil)
        end)

        it("should mark the building as destroyed when total health is depleted", function()
            BuildingSystem:init()
            local building = BuildingSystem.Buildings[1]
            local part1 = building.Model:FindFirstChild("Part1")
            local part2 = building.Model:FindFirstChild("Part2")

            BuildingSystem:OnDamage(part1, 100)
            BuildingSystem:OnDamage(part2, 100)

            expect(building.Health).to.equal(0)
            expect(building.State).to.equal("Destroyed")
        end)
    end)
end
