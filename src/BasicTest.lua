-- BasicTest.lua
-- A simple test with basic Lua functionality

print("=== Starting BasicTest ===")

-- Define a simple function
local function add(a, b)
    return a + b
end

-- Test the function
local result = add(2, 3)
print("2 + 3 =", result)

-- Return a simple table with test results
return {
    success = result == 5,
    message = result == 5 and "Basic math test passed!" or "Basic math test failed!"
}
