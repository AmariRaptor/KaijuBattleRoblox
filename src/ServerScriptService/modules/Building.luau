--!strict

--[[
    Represents a single destructible building in the game.

    @class Building
]]

-- Public type definition for the Building class
export type Building = {
    Model: Model,
    Parts: {[BasePart]: number},
    Health: number,
    State: string, -- "Intact" | "Damaged" | "Destroyed"

    -- Methods
    ApplyDamage: (self: Building, part: BasePart, damage: number) -> (),
    Destroy: (self: Building) -> (),
}

-- Internal implementation table
local BuildingImpl = {}
BuildingImpl.__index = BuildingImpl

--[[
    Detaches a part from the building model by destroying it.

    @param self Building The building instance.
    @param part BasePart The part to detach.
]]
local function DetachPart(self: Building, part: BasePart)
    part:Destroy()
    self.Parts[part] = nil -- Remove part from tracking
    print(`Detached part {part.Name} from {self.Model.Name}`)
end

-- Constructor
function BuildingImpl.new(model: Model): Building
    local self = (setmetatable({}, BuildingImpl) :: any) :: Building

    self.Model = model
    self.Parts = {}
    self.Health = 0
    self.State = "Intact"

    -- Initialize parts and health
    local totalHealth = 0
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            -- Assign a default health value to each part
            local partHealth = 100
            self.Parts[part] = partHealth
            totalHealth += partHealth
        end
    end
    self.Health = totalHealth
    print(`New building created for model: {self.Model.Name} with {self.Health} total health.`)

    return self
end

--[[
    Applies damage to a specific part of the building.

    @param self Building The building instance.
    @param part BasePart The part that was hit.
    @param damage number The amount of damage to apply.
]]
function BuildingImpl:ApplyDamage(part: BasePart, damage: number)
    if not self.Parts[part] then return end

    local currentPartHealth = self.Parts[part]
    local newPartHealth = currentPartHealth - damage

    self.Parts[part] = newPartHealth
    self.Health -= damage

    if newPartHealth <= 0 then
        DetachPart(self, part)
    end

    if self.Health <= 0 and self.State ~= "Destroyed" then
        self:Destroy()
    elseif self.State == "Intact" then
        self.State = "Damaged"
    end
end

--[[
    Handles the complete destruction of the building.

    @param self Building The building instance.
]]
function BuildingImpl:Destroy()
    self.State = "Destroyed"
    print(`{self.Model.Name} has been destroyed!`)
    -- TODO: Add logic for full building collapse or removal.
end

return (BuildingImpl :: any)
