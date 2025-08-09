--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")

local BuildingModule = require(ServerScriptService.modules.Building)

-- Types
type Building = BuildingModule.Building

--[[
    Manages all destructible buildings in the game environment.

    @class BuildingSystem
]]
local BuildingSystem = {}
BuildingSystem.__index = BuildingSystem

-- Properties
BuildingSystem.Buildings = {}
BuildingSystem.PartToBuildingMap = {}

-- Constructor
function BuildingSystem.new()
    local self = setmetatable({}, BuildingSystem)
    self.Buildings = {}
    self.PartToBuildingMap = {}
    return self
end

-- Initialize the system
function BuildingSystem:init()
    print("🔄 Initializing BuildingSystem...")

    local buildingModels = CollectionService:GetTagged("Building")

    for _, model in ipairs(buildingModels) do
        if model:IsA("Model") then
            local building = BuildingModule.new(model)
            table.insert(self.Buildings, building)

            for part, _ in pairs(building.Parts) do
                self.PartToBuildingMap[part] = building
            end
        end
    end

    print(`✅ BuildingSystem initialized with {tostring(#self.Buildings)} buildings.`)
    return true
end

--[[
    Handles damage events delegated from other systems (e.g., weapons).

    @param part BasePart The specific building part that was damaged.
    @param damage number The amount of damage to apply.
]]
function BuildingSystem:OnDamage(part: BasePart, damage: number)
    local building = self.PartToBuildingMap[part]
    if building then
        building:ApplyDamage(part, damage)
    end
end

return BuildingSystem.new()
