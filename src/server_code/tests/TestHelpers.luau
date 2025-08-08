--!strict
-- TestHelpers.luau
-- Shared utilities for testing

type Dictionary = {[any]: any}

global type TestHelpers = {
    createMockPlayer: () -> Player,
    createMockSystem: (name: string, dependencies: {string}?) -> Dictionary,
    mockRequire: (module: ModuleScript, mockReturns: Dictionary) -> () -> ()
}

local TestHelpers = {}

-- Create a mock player for testing
function TestHelpers.createMockPlayer()
    local player = Instance.new("Player")
    player.Name = "TestPlayer" .. tostring(math.random(1000, 9999))
    player.UserId = math.random(10000, 99999)
    return player
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
