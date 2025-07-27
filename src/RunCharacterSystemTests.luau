--!strict
-- Test runner for CharacterSystem using TestUtils

local TestUtils = require(script.Parent.TestUtils)

print("=== Starting CharacterSystem Tests ===\n")

-- Create test cases
local testCases = {
    {className = "Kaiju", expectedHealth = 500},
    {className = "Guardian", expectedHealth = 200},
    {className = "Engineer", expectedHealth = 150}
}

-- Create mock CharacterSystem
local CharacterSystem = TestUtils.createMockCharacterSystem()

-- Run tests
local passed = 0
local failed = 0

-- Test valid classes
for _, testCase in ipairs(testCases) do
    print("Testing", testCase.className, "character...")
    
    -- Create test character
    local character = TestUtils.createTestCharacter(testCase.className, 100)
    
    -- Run the test
    local success = CharacterSystem:onCharacterAdded(character)
    
    -- Get the humanoid to verify health
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    
    if success and humanoid then
        if humanoid.MaxHealth == testCase.expectedHealth and humanoid.Health == testCase.expectedHealth then
            print(string.format("✅ %s: Health set correctly to %d", testCase.className, testCase.expectedHealth))
            passed += 1
        else
            print(string.format("❌ %s: Expected health %d, got %d/%d", 
                testCase.className, testCase.expectedHealth, humanoid.Health, humanoid.MaxHealth))
            failed += 1
        end
    else
        print("❌", testCase.className, "setup failed")
        failed += 1
    end
end

-- Test invalid class
print("\nTesting invalid class...")
local invalidCharacter = TestUtils.createTestCharacter("InvalidClass", 100)
local invalidPlayer = invalidCharacter:FindFirstChild("Player")
if invalidPlayer then
    local playerClass = invalidPlayer:FindFirstChild("PlayerClass")
    if playerClass and playerClass:IsA("StringValue") then
        playerClass.Value = "InvalidClass"
    end
end

local success = CharacterSystem:onCharacterAdded(invalidCharacter)
local humanoid = invalidCharacter:FindFirstChildOfClass("Humanoid")

if not success and humanoid and humanoid.MaxHealth == 100 then
    print("✅ Invalid class handling passed")
    passed += 1
else
    print("❌ Invalid class handling failed")
    failed += 1
end

-- Print summary
print("\n=== Test Summary ===")
print(string.format("Total Tests: %d", passed + failed))
print(string.format("✅ Passed: %d", passed))
print(string.format("❌ Failed: %d", failed))

return failed == 0
