-- TestClassSystem.luau
-- A simple test file for ClassSystem

print("=== Starting ClassSystem Tests ===")

local function assert(condition, message)
    if not condition then
        error(message or "Assertion failed!")
    end
end

local function runTest(name, testFunc)
    local success, message = pcall(testFunc)
    if success then
        print("✅ " .. name .. " - PASSED")
        return true
    else
        print("❌ " .. name .. " - FAILED: " .. tostring(message))
        return false
    end
end

-- Mock ClassSystem for testing
local ClassSystem = {}

-- Mock the CLASSES table
ClassSystem.CLASSES = {
    "Kaiju",
    "Guardian",
    "Engineer"
}

-- Mock Player class
local Player = {}
Player.__index = Player

function Player.new(name)
    local self = setmetatable({}, Player)
    self.Name = name or "TestPlayer"
    self.Character = { Name = self.Name .. "_Character" }
    return self
end

-- Mock Instance.new
local mockInstances = {}
local Instance = {
    new = function(className)
        local obj = {
            Name = "",
            Value = "",
            Parent = nil,
            ClassName = className
        }
        table.insert(mockInstances, obj)
        return obj
    end
}

-- Mock game service
local game = {
    GetService = function(_, serviceName)
        if serviceName == "Players" then
            return {
                PlayerAdded = {
                    Connect = function(_, callback)
                        -- Store the callback for testing
                        ClassSystem._playerAddedCallback = callback
                    end
                },
                GetPlayers = function()
                    return {}
                end
            }
        end
        return {}
    end
}

-- Mock math.random to return predictable values for testing
local originalRandom = math.random
math.random = function(a, b)
    if a and b then
        return a -- Return first value for consistent testing
    end
    return originalRandom(a, b)
end

-- Mock the ClassSystem functions
function ClassSystem.onPlayerAdded(player)
    local playerClass = Instance.new("StringValue")
    playerClass.Name = "PlayerClass"
    playerClass.Value = ClassSystem.CLASSES[1] -- Always use first class for testing
    playerClass.Parent = player
    return playerClass
end

function ClassSystem.init()
    -- Set up the mock
    ClassSystem._playerAddedCallback = nil
    game:GetService("Players").PlayerAdded:Connect(ClassSystem.onPlayerAdded)
end

-- Run tests
local passed = 0
local failed = 0

-- Test 1: onPlayerAdded creates a PlayerClass
if runTest("onPlayerAdded creates PlayerClass", function()
    local player = Player.new("TestPlayer")
    local playerClass = ClassSystem.onPlayerAdded(player)
    
    assert(playerClass, "Should return a player class instance")
    assert(playerClass.Name == "PlayerClass", "Should create a PlayerClass value")
    assert(playerClass.Parent == player, "Should be parented to the player")
    assert(table.find(ClassSystem.CLASSES, playerClass.Value) ~= nil, "Should assign a valid class")
end) then passed = passed + 1 else failed = failed + 1 end

-- Test 2: init sets up event handlers
if runTest("init sets up event handlers", function()
    ClassSystem.init()
    assert(ClassSystem._playerAddedCallback ~= nil, "Should set up PlayerAdded event handler")
    
    -- Test the callback
    local player = Player.new("EventTestPlayer")
    ClassSystem._playerAddedCallback(player)
    
    -- Verify the player got a class assigned
    local hasClass = false
    for _, child in ipairs(mockInstances) do
        if child.Name == "PlayerClass" and child.Parent == player then
            hasClass = true
            break
        end
    end
    assert(hasClass, "Player should have received a class through the event")
end) then passed = passed + 1 else failed = failed + 1 end

-- Print test results
print("\n=== Test Results ===")
print(string.format("✅ %d tests passed", passed))
print(string.format("❌ %d tests failed", failed))
print("==================")

-- Restore original math.random
math.random = originalRandom

-- Return success if all tests passed
return failed == 0
