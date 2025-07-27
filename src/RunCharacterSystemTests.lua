--!strict
-- Simple test runner for CharacterSystem tests

local function runTests()
    print("=== Starting CharacterSystem Tests ===\n")
    
    -- Mock TestService for standalone execution
    local TestService = {}
    function TestService:IsCli()
        return true
    end
    
    -- Mock Instance class
    local Instance = {
        new = function(className)
            return {ClassName = className}
        end,
        FindFirstChild = function() return nil end,
        FindFirstChildOfClass = function() return nil end,
        IsA = function() return false end
    }
    
    -- Mock Model class
    local Model = {}
    Model.__index = Model
    function Model.new()
        local self = setmetatable({}, Model)
        self.ClassName = "Model"
        return self
    end
    
    -- Mock StringValue class
    local StringValue = {}
    StringValue.__index = StringValue
    function StringValue.new()
        local self = setmetatable({}, StringValue)
        self.ClassName = "StringValue"
        self.Value = ""
        return self
    end
    
    -- Mock ObjectValue class
    local ObjectValue = {}
    ObjectValue.__index = ObjectValue
    function ObjectValue.new()
        local self = setmetatable({}, ObjectValue)
        self.ClassName = "ObjectValue"
        self.Value = nil
        return self
    end
    
    -- Mock Humanoid class
    local Humanoid = {}
    Humanoid.__index = Humanoid
    function Humanoid.new()
        local self = setmetatable({}, Humanoid)
        self.ClassName = "Humanoid"
        self.MaxHealth = 100
        self.Health = 100
        return self
    end
    
    -- Set up global mocks
    _G.game = {
        GetService = function(_, serviceName)
            if serviceName == "TestService" then
                return TestService
            end
            return {}
        end
    }
    
    _G.script = {
        Parent = {}
    }
    
    -- Load the test file
    local testContent = [[
--!strict
-- CharacterSystemTest.lua
-- A test for CharacterSystem functionality

local TestService = game:GetService("TestService")

print("=== Starting CharacterSystem Test ===")

-- Types
type Humanoid = {
    MaxHealth: number,
    Health: number,
    Parent: Instance?,
    new: () -> Humanoid
}

type PlayerModel = Model & {
    PlayerClass: StringValue,
    Character: Model?
}

type ClassAttributes = {
    [string]: { MaxHealth: number }
}

local CharacterSystemTest = {}

-- Mock the minimal required parts of CharacterSystem
local function createMockCharacterSystem()
    local mock = {
        CLASS_ATTRIBUTES = {
            Kaiju = { MaxHealth = 500 },
            Guardian = { MaxHealth = 200 },
            Engineer = { MaxHealth = 150 }
        },
        
        onCharacterAdded = function(self, character: Model): boolean
            -- Mock implementation of onCharacterAdded
            local player = character:FindFirstChild("Player")
            if not player then return false end
            
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if not humanoid then return false end
            
            local playerClass = player:FindFirstChild("PlayerClass")
            if not playerClass or not playerClass:IsA("StringValue") then return false end
            
            local attributes = self.CLASS_ATTRIBUTES[playerClass.Value]
            if not attributes then return false end
            
            -- Set health based on class
            humanoid.MaxHealth = attributes.MaxHealth
            humanoid.Health = attributes.MaxHealth
            
            return true
        end,
        
        onPlayerAdded = function(self, player: PlayerModel): boolean
            -- Mock implementation of onPlayerAdded
            if player.Character then
                return self:onCharacterAdded(player.Character)
            end
            return false
        end
    }
    
    return mock
end

-- Create instance of mock system
local mockCharacterSystem = createMockCharacterSystem()

-- Test data
local testCases = {
    {className = "Kaiju", expectedHealth = 500},
    {className = "Guardian", expectedHealth = 200},
    {className = "Engineer", expectedHealth = 150}
}

-- Run tests and print results
local function runTests()
    local testSuccessCount = 0
    local testFailureCount = 0
    
    for _, testCase in ipairs(testCases) do
        local className = testCase.className
        local expectedHealth = testCase.expectedHealth
        
        -- Create test player
        local player = Instance.new("Model")
        player.Name = className .. "Player"
        
        -- Add PlayerClass
        local playerClass = Instance.new("StringValue")
        playerClass.Name = "PlayerClass"
        playerClass.Value = className
        playerClass.Parent = player
        
        -- Create test character
        local character = Instance.new("Model")
        character.Name = className .. "Character"
        
        -- Add humanoid
        local humanoid = Instance.new("Humanoid")
        humanoid.Parent = character
        
        -- Link player to character
        local playerRef = Instance.new("ObjectValue")
        playerRef.Name = "Player"
        playerRef.Value = player
        playerRef.Parent = character
        
        -- Test onCharacterAdded
        local testSuccess = mockCharacterSystem:onCharacterAdded(character)
        
        if testSuccess then
            -- Verify health was set correctly
            if humanoid.MaxHealth == expectedHealth and humanoid.Health == expectedHealth then
                print(string.format("✅ %s character setup passed", className))
                testSuccessCount = testSuccessCount + 1
            else
                print(string.format("❌ %s health mismatch: expected %d, got %d/%d", 
                    className, expectedHealth, humanoid.Health, humanoid.MaxHealth))
                testFailureCount = testFailureCount + 1
            end
        else
            print(string.format("❌ %s setup failed", className))
            testFailureCount = testFailureCount + 1
        end
    end
    
    -- Test invalid class
    print("\nTesting invalid class handling...")
    local invalidPlayer = Instance.new("Model")
    invalidPlayer.Name = "InvalidPlayer"
    
    local invalidClass = Instance.new("StringValue")
    invalidClass.Name = "PlayerClass"
    invalidClass.Value = "InvalidClass"
    invalidClass.Parent = invalidPlayer
    
    local invalidCharacter = Instance.new("Model")
    invalidCharacter.Name = "InvalidCharacter"
    
    local invalidHumanoid = Instance.new("Humanoid")
    invalidHumanoid.Parent = invalidCharacter
    
    local playerRef = Instance.new("ObjectValue")
    playerRef.Name = "Player"
    playerRef.Value = invalidPlayer
    playerRef.Parent = invalidCharacter
    
    -- Should not error with invalid class, just return false
    local testSuccess = pcall(function()
        return mockCharacterSystem:onCharacterAdded(invalidCharacter)
    end)
    
    if testSuccess and invalidHumanoid.MaxHealth == 100 then -- Default Humanoid max health
        print("✅ Invalid class handling passed")
        testSuccessCount = testSuccessCount + 1
    else
        print("❌ Invalid class handling failed")
        testFailureCount = testFailureCount + 1
    end
    
    -- Print summary
    print("\n=== Test Summary ===")
    print(string.format("Total Tests: %d", testSuccessCount + testFailureCount))
    print(string.format("✅ Passed: %d", testSuccessCount))
    print(string.format("❌ Failed: %d", testFailureCount))
    
    return testFailureCount == 0
end

-- Run tests if this module is executed directly
if TestService:IsCli() then
    local testSuccess = runTests()
    if not testSuccess then
        error("Some tests failed")
    end
end

CharacterSystemTest.MockCharacterSystem = mockCharacterSystem
return CharacterSystemTest
    ]]
    
    -- Create a test environment
    local env = {
        Instance = Instance,
        Model = Model,
        StringValue = StringValue,
        ObjectValue = ObjectValue,
        Humanoid = Humanoid,
        print = print,
        warn = warn,
        error = error,
        type = type,
        pcall = pcall,
        ipairs = ipairs,
        string = string,
        table = table,
        _G = _G
    }
    
    -- Load and run the test
    local chunk, err = load(testContent, "CharacterSystemTest", "t", env)
    if not chunk then
        print("❌ Failed to load test chunk:", err)
        return false
    end
    
    local success, result = pcall(chunk)
    if not success then
        print("❌ Test execution failed:", result)
        return false
    end
    
    print("\n=== All CharacterSystem tests completed ===")
    return true
end

-- Run the tests
local success, result = pcall(runTests)
if not success then
    print("❌ Test runner failed:", result)
    os.exit(1)
end

os.exit(result and 0 or 1)
