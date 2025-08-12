--!strict
-- NPCHealthBar.server.luau
-- Simple NPC health bar system: manages NPC health states and optional BillboardGui visuals.

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local NPCHealthBar = {}
NPCHealthBar.__index = NPCHealthBar

local states: { [string]: any } = {}

local function getKey(npc)
	return tostring(npc)
end

function NPCHealthBar:init(): boolean
	states = {}
	return true
end

function NPCHealthBar:registerNPC(npc, maxHealth: number)
	assert(maxHealth and type(maxHealth) == "number", "maxHealth required")
	local key = getKey(npc)
	local state = {
		model = npc,
		maxHealth = maxHealth,
		health = maxHealth,
		gui = nil,
	}
	states[key] = state

	-- attempt to create a simple BillboardGui visual if the environment allows
	pcall(function()
		local primary = npc and npc.PrimaryPart
		if primary then
			local billboard = Instance.new("BillboardGui")
			billboard.Name = "NPCHealthBar"
			billboard.Adornee = primary
			billboard.AlwaysOnTop = true
			billboard.Size = UDim2.new(0, 120, 0, 16)
			billboard.StudsOffset = Vector3.new(0, 3, 0)

			local bg = Instance.new("Frame")
			bg.Name = "Background"
			bg.Size = UDim2.new(1, 0, 1, 0)
			bg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
			bg.BorderSizePixel = 0
			bg.Parent = billboard

			local bar = Instance.new("Frame")
			bar.Name = "Bar"
			bar.Size = UDim2.new(1, 0, 1, 0)
			bar.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
			bar.BorderSizePixel = 0
			bar.Parent = bg

			billboard.Parent = npc
			state.gui = billboard
		end
	end)

	return state
end

function NPCHealthBar:getState(npc)
	return states[getKey(npc)]
end

function NPCHealthBar:getHealthPercentage(npc)
	local s = self:getState(npc)
	if not s then return nil end
	if s.maxHealth <= 0 then return 0 end
	return math.clamp(s.health / s.maxHealth, 0, 1)
end

function NPCHealthBar:updateHealth(npc, newHealth)
	local s = self:getState(npc)
	if not s then return nil end
	s.health = math.clamp(newHealth, 0, s.maxHealth)
	local pct = self:getHealthPercentage(npc)
	pcall(function()
		if s.gui and s.gui:FindFirstChild("Background") and s.gui.Background:FindFirstChild("Bar") then
			s.gui.Background.Bar.Size = UDim2.new(pct, 0, 1, 0)
			if pct < 0.3 then
				s.gui.Background.Bar.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
			elseif pct < 0.7 then
				s.gui.Background.Bar.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
			else
				s.gui.Background.Bar.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
			end
		end
	end)
	return s.health
end

function NPCHealthBar:applyDamage(npc, amount)
	if not amount or type(amount) ~= "number" then return nil end
	local s = self:getState(npc)
	if not s then return nil end
	local new = math.max(0, s.health - amount)
	self:updateHealth(npc, new)
	return new
end

function NPCHealthBar:destroyNPC(npc)
	local key = getKey(npc)
	local s = states[key]
	if not s then return end
	pcall(function()
		if s.gui and s.gui.Parent then s.gui:Destroy() end
	end)
	states[key] = nil
end

return NPCHealthBar