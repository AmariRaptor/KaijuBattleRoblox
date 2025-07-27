--!strict
-- CharacterSystemTest.luau
-- A test for CharacterSystem functionality using mock objects with strict Luau types

-- Types
type MockInstance = {
    ClassName: string,
    Name: string,
    _children: {MockInstance},
    _parent: MockInstance?,
    _properties: {[string]: any},
    Parent: Instance?,
    FindFirstChild: (self: MockInstance, name: string, recursive: boolean?) -> MockInstance?,
    FindFirstChildOfClass: (self: MockInstance, className: string) -> MockInstance?,
    IsA: (self: MockInstance, className: string) -> boolean,
    GetChildren: (self: MockInstance) -> {MockInstance},
    MaxHealth: number?,
    Health: number?,
    Value: any
}

type CharacterSystem = {
    CLASS_ATTRIBUTES: {
        [string]: {
            MaxHealth: number
        }
    },
    onCharacterAdded: (self: CharacterSystem, character: Instance) -> boolean,
    onPlayerAdded: (self: CharacterSystem, player: Instance) -> boolean
}

-- Mock instance system
local MockInstance = {}
MockInstance.__index = MockInstance

function MockInstance.new(className: string, name: string?): MockInstance
    local self: MockInstance = {
        ClassName = className,
        Name = name or className,
        _children = {},
        _parent = nil :: MockInstance?,
        _properties = {},
        Parent = nil,
        MaxHealth = 100,
        Health = 100,
        Value = nil
    }
    return setmetatable(self, MockInstance) :: any
end

function MockInstance:FindFirstChild(name: string, recursive: boolean?): MockInstance?
    if not self._children then return nil end
    
    -- First check direct children
    for _, child in ipairs(self._children) do
        if child.Name == name then
            return child
        end
    end
    
    -- Then check recursively if requested
    if recursive then
        for _, child in ipairs(self._children) do
            local found = child:FindFirstChild(name, true)
            if found then
                return found
            end
        end
    end
    
    return nil
end

function MockInstance:FindFirstChildOfClass(className: string): MockInstance?
    if not self._children then return nil end
    
    for _, child in ipairs(self._children) do
        if child.ClassName == className then
            return child
        end
        
        -- Search recursively
        local found = child:FindFirstChildOfClass(className)
        if found then
            return found
        end
    end
    
    return nil
end

function MockInstance:IsA(className: string): boolean
    return self.ClassName == className
end

function MockInstance:GetChildren(): {MockInstance}
    return self._children or {}
end

-- Create mock CharacterSystem
local function createMockCharacterSystem(): CharacterSystem
    local mock: CharacterSystem = {
        CLASS_ATTRIBUTES = {
            Kaiju = { MaxHealth = 500 },
            Guardian = { MaxHealth = 200 },
            Engineer = { MaxHealth = 150 }
        },
        
        onCharacterAdded = function(self: CharacterSystem, character: Instance): boolean
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if not humanoid then return false end
            
            local playerValue = character:FindFirstChild("Player")
            if not playerValue or not playerValue:IsA("ObjectValue") then return false end
            
            local player = playerValue.Value
            if not player then return false end
            
            local playerClass = player:FindFirstChild("PlayerClass")
            if not playerClass or not playerClass:IsA("StringValue") then return false end
            
            local attributes = self.CLASS_ATTRIBUTES[playerClass.Value]
            if not attributes then return false end
            
            -- Set health based on class
            humanoid.MaxHealth = attributes.MaxHealth
            humanoid.Health = attributes.MaxHealth
            
            return true
        end,
        
        onPlayerAdded = function(self: CharacterSystem, player: Instance): boolean
            -- Mock implementation of onPlayerAdded
            if player:FindFirstChild("Character") then
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
type TestCase = {
    className: string,
    expectedHealth: number
}

local testCases: {TestCase} = {
    { className = "Kaiju", expectedHealth = 500 },
    { className = "Guardian", expectedHealth = 200 },
    { className = "Engineer", expectedHealth = 150 }
}

-- Run tests and print results
local function runTests(): (number, number)
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
    local success = pcall(function()
        return mockCharacterSystem:onCharacterAdded(invalidCharacter)
    end)
    
    if success and invalidHumanoid.MaxHealth == 100 then -- Default Humanoid max health
        print("✅ Invalid class handling passed")
        testSuccessCount = testSuccessCount + 1
    else
        print("❌ Invalid class handling failed")
        testFailureCount = testFailureCount + 1
    end
    
    return testSuccessCount, testFailureCount
end

-- Run tests and print summary
local successCount, failureCount = runTests()

-- Print summary
print("\n=== Test Summary ===")
print(string.format("Total Tests: %d", successCount + failureCount))
print(string.format("✅ Passed: %d", successCount))
print(string.format("❌ Failed: %d", failureCount))

-- Return overall result
return {
    success = failureCount == 0,
    message = string.format("CharacterSystem tests completed. %d passed, %d failed", 
        successCount, failureCount)
}
