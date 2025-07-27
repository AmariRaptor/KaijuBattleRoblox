--!strict
-- Test runner for CharacterSystem tests

local TestService = game:GetService("TestService")

print("=== Starting CharacterSystem Tests ===\n")

-- Mock classes for testing
local MockClass = {}
MockClass.__index = MockClass

function MockClass.new(className: string)
    local self = setmetatable({}, MockClass)
    self.ClassName = className
    return self
end

-- Mock Instance methods
local function mockInstance(instance: any)
    instance.FindFirstChild = function(_, name: string)
        return nil
    end
    
    instance.FindFirstChildOfClass = function(_, className: string)
        return nil
    end
    
    instance.IsA = function(_, className: string)
        return instance.ClassName == className
    end
    
    return instance
end

-- Create a test character with the given class
local function createTestCharacter(className: string, expectedHealth: number): boolean
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
    
    -- Add humanoid
    local humanoid = mockInstance(MockClass.new("Humanoid"))
    humanoid.MaxHealth = 100
    humanoid.Health = 100
    humanoid.Parent = character
    
    -- Link player to character
    local playerRef = mockInstance(MockClass.new("ObjectValue"))
    playerRef.Name = "Player"
    playerRef.Value = player
    playerRef.Parent = character
    
    -- Mock the CharacterSystem
    local CharacterSystem = {
        CLASS_ATTRIBUTES = {
            Kaiju = { MaxHealth = 500 },
            Guardian = { MaxHealth = 200 },
            Engineer = { MaxHealth = 150 }
        },
        
        onCharacterAdded = function(self, char: any): boolean
            local playerObj = char:FindFirstChild("Player")
            if not playerObj then return false end
            
            local humanoidObj = char:FindFirstChildOfClass("Humanoid")
            if not humanoidObj then return false end
            
            local playerClass = playerObj:FindFirstChild("PlayerClass")
            if not playerClass or not playerClass:IsA("StringValue") then 
                return false 
            end
            
            local attributes = self.CLASS_ATTRIBUTES[playerClass.Value]
            if not attributes then return false end
            
            humanoidObj.MaxHealth = attributes.MaxHealth
            humanoidObj.Health = attributes.MaxHealth
            return true
        end
    }
    
    -- Run the test
    local success = CharacterSystem:onCharacterAdded(character)
    
    if success then
        if humanoid.MaxHealth == expectedHealth and humanoid.Health == expectedHealth then
            print(string.format("✅ %s: Health set correctly to %d", className, expectedHealth))
            return true
        else
            print(string.format("❌ %s: Expected health %d, got %d/%d", 
                className, expectedHealth, humanoid.Health, humanoid.MaxHealth))
            return false
        end
    else
        print("❌", className, "setup failed")
        return false
    end
end

-- Run all tests
local function runAllTests()
    local testCases = {
        {className = "Kaiju", expectedHealth = 500},
        {className = "Guardian", expectedHealth = 200},
        {className = "Engineer", expectedHealth = 150}
    }
    
    local passed = 0
    local failed = 0
    
    for _, testCase in ipairs(testCases) do
        if createTestCharacter(testCase.className, testCase.expectedHealth) then
            passed = passed + 1
        else
            failed = failed + 1
        end
    end
    
    -- Test invalid class
    print("\nTesting invalid class...")
    if not createTestCharacter("InvalidClass", 100) then
        print("✅ Invalid class handling passed")
        passed = passed + 1
    else
        print("❌ Invalid class handling failed")
        failed = failed + 1
    end
    
    -- Print summary
    print("\n=== Test Summary ===")
    print(string.format("Total: %d", passed + failed))
    print(string.format("✅ Passed: %d", passed))
    print(string.format("❌ Failed: %d", failed))
    
    return failed == 0
end

-- Run the tests
local success, result = pcall(runAllTests)

if not success then
    warn("Test execution failed:", result)
    return false
end

return result
