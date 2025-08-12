--!strict
-- TestHelpers.luau
-- Shared utilities for testing, Studio-friendly (avoids creating Player Instances when not permitted)

type Dictionary = {[any]: any}

global type TestHelpers = {
    createMockPlayer: () -> (Player | { [any]: any }),
    createMockSystem: (name: string, dependencies: {string}?) -> Dictionary,
    mockRequire: (module: ModuleScript, mockReturns: Dictionary) -> () -> ()
}

local Players = game:GetService("Players")
local TestHelpers = {}

-- Internal mocks registry used when real Player Instances cannot be created
local _mockPlayers = {}
local _patchedGetPlayers = false
local _originalGetPlayers = Players.GetPlayers

local function patchGetPlayers()
    if _patchedGetPlayers then return end
    _patchedGetPlayers = true

    Players.GetPlayers = function(self)
        local ok, realPlayers = pcall(_originalGetPlayers, self)
        if not ok or type(realPlayers) ~= "table" then
            realPlayers = {}
        end

        local merged = {}
        for _, p in ipairs(realPlayers) do table.insert(merged, p) end
        for _, p in ipairs(_mockPlayers) do table.insert(merged, p) end
        return merged
    end
end

-- Create a mock player for testing.
-- Prefers a real Player instance when the environment allows it; otherwise returns a lightweight table
-- that implements the minimal API expected by systems under test (IsA, FindFirstChild, FindFirstChildOfClass).
function TestHelpers.createMockPlayer()
    -- Try to create a real Player instance (may be disallowed in some Studio test contexts)
    local ok, player = pcall(function() return Instance.new("Player") end)
    if ok and player then
        player.Name = "TestPlayer" .. tostring(math.random(1000, 9999))
        player.UserId = math.random(10000, 99999)
        return player
    end

    -- Fallback: create a lightweight mock object
    local id = math.random(10000, 99999)
    local mock = {
        Name = "MockPlayer" .. tostring(id),
        UserId = id,
        Character = nil,
    }

    function mock:IsA(className: string)
        return className == "Player"
    end

    function mock:FindFirstChild(name: string)
        return rawget(self, name)
    end

    function mock:FindFirstChildOfClass(className: string)
        if className == "Humanoid" and self.Character and type(self.Character.FindFirstChildOfClass) == "function" then
            return self.Character:FindFirstChildOfClass("Humanoid")
        end
        return nil
    end

    table.insert(_mockPlayers, mock)
    patchGetPlayers()

    return mock
end

-- Create a mock system with the specified name and optional dependencies
function TestHelpers.createMockSystem(name: string, dependencies: {string}?): Dictionary
    dependencies = dependencies or {}
    
    local system = {
        name = name,
        dependencies = dependencies,
        initialized = false,
        started = false,
        
        init = function(self)
            self.initialized = true
            return true
        end,
        
        start = function(self)
            self.started = true
            return true
        end,
        
        -- For testing error cases
        failOnInit = function(self)
            return false, "Initialization failed for " .. self.name
        end,
        
        failOnStart = function(self)
            return false, "Start failed for " .. self.name
        end
    }
    
    return system
end

-- Mock the require function for a specific module
function TestHelpers.mockRequire(module: ModuleScript, mockReturns: Dictionary): () -> ()
    local originalRequire = require
    local originalSource = module.Source
    
    -- Create a mock module with the specified returns
    local mockModule = setmetatable({}, {
        __index = function(_, k)
            return mockReturns[k]
        end
    })
    
    -- Override require for this module
    local function mockFn(mod: ModuleScript)
        if mod == module then
            return mockModule
        end
        return originalRequire(mod)
    end
    
    -- Apply the mock
    _G.require = mockFn
    
    -- Return a function to restore the original require
    return function()
        _G.require = originalRequire
    end
end

return TestHelpers
