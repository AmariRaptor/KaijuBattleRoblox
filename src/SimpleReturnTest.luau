--!strict
-- SimpleReturnTest.luau
-- A test that directly returns a success message with strict Luau types

print("=== Starting SimpleReturnTest ===")

-- Define return type
type TestResult = {
    success: boolean,
    message: string
}

-- Directly return a success message
local result: TestResult = {
    success = true,
    message = "Simple return test passed!"
}

print("✅", result.message)
return result
