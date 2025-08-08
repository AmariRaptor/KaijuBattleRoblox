--!strict
-- VerificationTest.luau - A minimal test to verify MCP test execution

local function runTest()
    -- This is a simple test that should always pass
    return "✅ Verification test passed successfully"
end

-- Execute the test and return the results
local success, result = pcall(runTest)
if success then
    return result
else
    return "❌ Test execution failed: " .. tostring(result)
end
