--!strict

game:GetService("ServerStorage")
local Players = game:GetService("Players")

-- Mock player for testing
local function createMockPlayer()
    local player = Instance.new("Player")
    player.Name = "TestPlayer"
    player.UserId = 12345
    return player
end

-- Test suite for BuildingSystem
return function()
    local BuildingSystem
    local testPlayer
    
    beforeAll(function()
        -- Load the BuildingSystem module
        BuildingSystem = require(script.Parent.Parent.systems.BuildingSystem)
        testPlayer = createMockPlayer()
        
        -- Initialize the system
        BuildingSystem:init()
    end)
    
    afterEach(function()
        -- Clean up after each test
        for _, building in pairs(BuildingSystem.buildings) do
            if building.model and building.model.Parent then
                building.model:Destroy()
            end
        end
        BuildingSystem.buildings = {}
    end)
    
    describe("BuildingSystem", function()
        it("should initialize with empty buildings table", function()
            expect(#BuildingSystem.buildings).to.equal(0)
        end)
        
        it("should create a new skyscraper building", function()
            local position = Vector3.new(0, 0, 0)
            local building = BuildingSystem:createBuilding("SKYSCRAPER", position, testPlayer)
            
            expect(building).to.be.ok()
            expect(building.buildingType).to.equal("SKYSCRAPER")
            expect(building.health).to.equal(200)
            expect(building.owner).to.equal(testPlayer)
        end)
        
        it("should create a new hospital building", function()
            local position = Vector3.new(10, 0, 10)
            local building = BuildingSystem:createBuilding("HOSPITAL", position, testPlayer)
            
            expect(building).to.be.ok()
            expect(building.buildingType).to.equal("HOSPITAL")
            expect(building.health).to.equal(150)
            expect(building.owner).to.equal(testPlayer)
        end)
        
        it("should apply damage to a building", function()
            local position = Vector3.new(0, 0, 0)
            local building = BuildingSystem:createBuilding("SKYSCRAPER", position, testPlayer)
            
            local initialHealth = building.health
            building:damage(50)
            
            expect(building.health).to.equal(initialHealth - 50)
            expect(building.lastDamageTime).to.be.ok()
        end)
        
        it("should repair a building", function()
            local position = Vector3.new(0, 0, 0)
            local building = BuildingSystem:createBuilding("SKYSCRAPER", position, testPlayer)
            
            -- First damage the building
            building:damage(50)
            local damagedHealth = building.health
            
            -- Then repair it
            building:repair(30)
            
            expect(building.health).to.equal(damagedHealth + 30)
            expect(building.lastRepairTime).to.be.ok()
        end)
        
        it("should destroy a building when health reaches zero", function()
            local position = Vector3.new(0, 0, 0)
            local building = BuildingSystem:createBuilding("SKYSCRAPER", position, testPlayer)
            
            -- Spy on the destroy method
            local destroySpy = spy.on(building, "destroy")
            
            -- Deal enough damage to destroy the building
            building:damage(1000)
            
            expect(destroySpy).to.have.been.called()
            expect(building.isDestroyed).to.equal(true)
        end)
        
        it("should apply visual effects to buildings", function()
            local position = Vector3.new(0, 0, 0)
            local building = BuildingSystem:createBuilding("SKYSCRAPER", position, testPlayer)
            
            -- Check for smoke effect
            local smoke = building.model.PrimaryPart:FindFirstChild("Smoke")
            expect(smoke).to.be.ok()
            
            -- Check for light effect
            local light = building.model.PrimaryPart:FindFirstChild("PointLight")
            expect(light).to.be.ok()
        end)
    end)
end
