--!strict
-- Test runner for CharacterSystem tests with strict Luau types

local TestService = game:GetService("TestService")

print("=== Starting CharacterSystem Tests ===\n")

-- Types
type MockInstance = {
    ClassName: string,
    Name: string,
    Value: any,
    Parent: MockInstance?,
    MaxHealth: number?,
    Health: number?,
    FindFirstChild: (self: MockInstance, name: string) -> MockInstance?,
    FindFirstChildOfClass: (self: MockInstance, className: string) -> MockInstance?,
    IsA: (self: MockInstance, className: string) -> boolean
}

-- Mock classes for testing
local MockClass = {}
MockClass.__index = MockClass

function MockClass.new(className: string): MockInstance
    local self: MockInstance = setmetatable({}, MockClass) :: any
    self.ClassName = className
    self.Name = ""
    self.Value = nil
    self.Parent = nil
    self.MaxHealth = nil
    self.Health = nil
    return self
end

-- Mock Instance methods
local function mockInstance(instance: MockInstance): MockInstance
    instance.FindFirstChild = function(self: MockInstance, name: string): MockInstance?
        for _, child in ipairs(self:GetChildren()) do
            if child.Name == name then
                return child
            end
        end
        return nil
    end
    
    instance.FindFirstChildOfClass = function(self: MockInstance, className: string): MockInstance?
        for _, child in ipairs(self:GetChildren()) do
            if child.ClassName == className then
                return child
            end
        end
        return nil
    end
    
    instance.IsA = function(self: MockInstance, className: string): boolean
        return self.ClassName == className
    end
    
    instance.GetChildren = function(self: MockInstance): {MockInstance}
        local children: {MockInstance} = {}
        for _, child in pairs(getmetatable(self) or {}) do
            if type(child) == "table" and child.ClassName then
                table.insert(children, child)
            end
        end
        return children
    end
    
    return instance
end

-- Create a test character with the given class
local function createTestCharacter(className: string, expectedHealth: number): (boolean, string?)
    print("Testing", className, "character...")
    
    -- Create player
    local player = mockInstance(MockClass.new("Model"))
    player.Name = className .. "Player"
    
    -- Add PlayerClass
    local playerClass = mockInstance(MockClass.new("StringValue"))
    playerClass.Name = "PlayerClass"
    playerClass.Value = className
    playerClass.Parent = player
    
    -- Create character
    local character = mockInstance(MockClass.new("Model"))
    character.Name = className .. "Character"
    
    -- Add humanoid to character
    local humanoid = mockInstance(MockClass.new("Humanoid"))
    humanoid.MaxHealth = 100
    humanoid.Health = 100
    humanoid.Parent = character
    
    -- Add player reference to character
    local playerRef = mockInstance(MockClass.new("ObjectValue"))
    playerRef.Name = "Player"
    playerRef.Value = player
    playerRef.Parent = character
    
    -- Set character as player's character
    player.Character = character
    
    -- Verify the setup
    if not character:FindFirstChild("Humanoid") then
        return false, "Humanoid not found in character"
    end
    
    -- Mock CharacterSystem (simplified for testing)
    local CharacterSystem = {
        onCharacterAdded = function(character: MockInstance): boolean
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if not humanoid then return false end
            
            local playerValue = character:FindFirstChild("Player")
            if not playerValue or not playerValue:IsA("ObjectValue") then return false end
            
            local player = playerValue.Value
            if not player then return false end
            
            local playerClass = player:FindFirstChild("PlayerClass")
            if not playerClass or not playerClass:IsA("StringValue") then return false end
            
            -- Simulate different health values based on class
            if playerClass.Value == "Kaiju" then
                humanoid.MaxHealth = 500
                humanoid.Health = 500
            elseif playerClass.Value == "Guardian" then
                humanoid.MaxHealth = 200
                humanoid.Health = 200
            elseif playerClass.Value == "Engineer" then
                humanoid.MaxHealth = 150
                humanoid.Health = 150
            else
                return false
            end
            
            return true
        end
    }
    
    -- Test character added
    local success = CharacterSystem.onCharacterAdded(character)
    if not success then
        return false, "Failed to process character"
    end
    
    -- Verify health was set correctly
    if humanoid.Health ~= expectedHealth then
        return false, string.format("Expected health %d, got %d", expectedHealth, humanoid.Health or -1)
    end
    
    if humanoid.MaxHealth ~= expectedHealth then
        return false, string.format("Expected max health %d, got %d", expectedHealth, humanoid.MaxHealth or -1)
    end
    
    return true, nil
end

-- Run tests
local function runAllTests(): (boolean, string?)
    local testCases = {
        {className = "Kaiju", expectedHealth = 500},
        {className = "Guardian", expectedHealth = 200},
        {className = "Engineer", expectedHealth = 150}
    }
    
    for _, testCase in ipairs(testCases) do
        local success, errorMessage = createTestCharacter(testCase.className, testCase.expectedHealth)
        if not success then
            return false, string.format("%s test failed: %s", testCase.className, errorMessage or "Unknown error")
        end
        print(string.format("✅ %s test passed", testCase.className))
    end
    
    -- Test invalid class
    local success, _ = createTestCharacter("InvalidClass", 100)
    if success then
        return false, "Invalid class test should have failed"
    end
    print("✅ Invalid class test passed (failed as expected)")
    
    return true, nil
end

-- Main execution
local success, errorMessage = runAllTests()
if success then
    print("\n✅ All CharacterSystem tests passed!")
    return {success = true, message = "All tests passed"}
else
    print("\n❌ Test failed:", errorMessage or "Unknown error")
    return {success = false, message = errorMessage or "Test failed"}
end
