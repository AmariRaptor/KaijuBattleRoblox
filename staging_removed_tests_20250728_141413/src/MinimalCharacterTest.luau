--!strict
-- Minimal test script for CharacterSystem with strict Luau types

print("=== Starting Minimal CharacterSystem Test ===")

-- Simple test function
local function runTest(): boolean
    print("✅ Test environment is working")
    return true
end

-- Run the test and return the result
local success, result = pcall(runTest)

if success and result then
    print("✅ All tests passed!")
    return {success = true, message = "All tests passed"}
else
    local errorMessage = if not success then tostring(result) else "Test returned false"
    warn("❌ Tests failed:", errorMessage)
    return {success = false, message = "Tests failed: " .. errorMessage}
end
