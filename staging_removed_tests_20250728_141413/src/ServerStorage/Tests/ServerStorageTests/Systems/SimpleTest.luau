--!strict
-- SimpleTest.luau - A basic test file for MCP execution

-- Simple function to test
local function add(a: number, b: number): number
    return a + b
end

-- Test cases
local testResults = {}

-- Test 1: Basic addition
local success, result = pcall(function()
    local sum = add(2, 3)
    assert(sum == 5, "2 + 3 should equal 5")
    return true
end)

table.insert(testResults, success and "✅ Test 1: Basic addition passed" or "❌ Test 1: " .. tostring(result))

-- Test 2: String concatenation
local str1 = "Hello"
local str2 = "World"
local combined = str1 .. " " .. str2
if combined == "Hello World" then
    table.insert(testResults, "✅ Test 2: String concatenation passed")
else
    table.insert(testResults, "❌ Test 2: String concatenation failed")
end

-- Return the test results as a string
return table.concat(testResults, "\n")
