--!strict
-- BasicTest.luau
-- A simple test with basic Luau functionality

type TestResult = {
    success: boolean,
    message: string
}

print("=== Starting BasicTest ===")

-- Define a simple function with type annotations
local function add(a: number, b: number): number
    return a + b
end

-- Test the function
local result: number = add(2, 3)
print("2 + 3 =", result)

-- Return a typed table with test results
local testResult: TestResult = {
    success = result == 5,
    message = if result == 5 then "Basic math test passed!" else "Basic math test failed!"
}

return testResult
