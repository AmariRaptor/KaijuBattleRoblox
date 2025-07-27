--!strict
-- CharacterSystemTest.lua
-- A test for CharacterSystem functionality using mock objects

-- Import TestEZ for better test reporting
local TestEZ = require(script.Parent.Parent.Packages.Dev.TestEZ)

-- Mock instance system
local MockInstance = {}
MockInstance.__index = MockInstance

function MockInstance.new(className: string, name: string?)
    local self = {
        ClassName = className,
        Name = name or className,
        _children = {},
        _parent = nil,
        _properties = {}
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
    { className = "Kaiju", expectedHealth = 500 },
    { className = "Guardian", expectedHealth = 200 },
    { className = "Engineer", expectedHealth = 150 }
}

-- Run tests
local successCount = 0
local failureCount = 0

for _, testCase in ipairs(testCases) do
    local className = testCase.className
    local expectedHealth = testCase.expectedHealth
    
    print(string.format("\nTesting %s character setup...", className))
    
    -- Create mock player and character
    local player = Instance.new("Model")
    player.Name = "TestPlayer"
    
    local playerClass = Instance.new("StringValue")
    playerClass.Name = "PlayerClass"
    playerClass.Value = className
    playerClass.Parent = player
    
    local character = Instance.new("Model")
    character.Name = "TestCharacter"
    
    local humanoid = Instance.new("Humanoid")
    humanoid.Parent = character
    
    -- Add player reference to character
    local playerRef = Instance.new("ObjectValue")
    playerRef.Name = "Player"
    playerRef.Value = player
    playerRef.Parent = character
    
    -- Test onCharacterAdded
    local success = MockCharacterSystem.onCharacterAdded(character)
    
    if success then
        -- Verify health was set correctly
        if humanoid.MaxHealth == expectedHealth and humanoid.Health == expectedHealth then
            print(string.format("✅ %s character setup passed", className))
            successCount = successCount + 1
        else
            print(string.format("❌ %s health mismatch: expected %d, got %d/%d", 
                className, expectedHealth, humanoid.Health, humanoid.MaxHealth))
            failureCount = failureCount + 1
        end
    else
        print(string.format("❌ %s setup failed", className))
        failureCount = failureCount + 1
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
local success = pcall(function()
    return MockCharacterSystem.onCharacterAdded(invalidCharacter)
end)

if success and invalidHumanoid.MaxHealth == 100 then -- Default Humanoid max health
    print("✅ Invalid class handling passed")
    successCount = successCount + 1
else
    print("❌ Invalid class handling failed")
    failureCount = failureCount + 1
end

-- Print summary
print("\n=== Test Summary ===")
print(string.format("Total Tests: %d", successCount + failureCount))
print(string.format("✅ Passed: %d", successCount))
print(string.format("❌ Failed: %d", failureCount))

-- Run tests and print results
local function runTests()
    local testSuccessCount = 0
    local testFailureCount = 0
    
    for _, testCase in ipairs(testCases) do
        local className = testCase.className
        local expectedHealth = testCase.expectedHealth
        
        print(string.format("\nTesting %s character setup...", className))
        
        -- Create mock player and character
        local player = Instance.new("Model")
        player.Name = "TestPlayer"
        
        local playerClass = Instance.new("StringValue")
        playerClass.Name = "PlayerClass"
        playerClass.Value = className
        playerClass.Parent = player
        
        local character = Instance.new("Model")
        character.Name = "TestCharacter"
        
        local humanoid = Instance.new("Humanoid")
        humanoid.Parent = character
        
        -- Add player reference to character
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
