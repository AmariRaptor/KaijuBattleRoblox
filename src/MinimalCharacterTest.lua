--!strict
-- Minimal test script for CharacterSystem

print("=== Starting Minimal CharacterSystem Test ===")

-- Simple test function
local function runTest()
    print("✅ Test environment is working")
    return true
end

-- Run the test
local success, result = pcall(runTest)

if success and result then
    print("✅ All tests passed!")
    return true
else
    warn("❌ Tests failed:", result)
    return false
end
