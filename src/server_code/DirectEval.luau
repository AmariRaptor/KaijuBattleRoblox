-- DirectEval.luau
-- A script to test direct evaluation in the MCP environment

-- Simple function to test basic functionality
local function testBasicFunctionality()
    -- Test basic Lua functionality
    local tests = {
        {name = "String concatenation", test = function() return "Hello" .. " " .. "World" end, expected = "Hello World"},
        {name = "Table operations", test = function() local t = {a=1,b=2}; t.c = 3; return t.a + t.b + t.c end, expected = 6},
        {name = "Math operations", test = function() return 2 + 2 * 2 end, expected = 6},
        {name = "String functions", test = function() return string.upper("test") end, expected = "TEST"},
        {name = "Table library", test = function() local t = {3,1,2}; table.sort(t); return table.concat(t, ",") end, expected = "1,2,3"}
    }
    
    local results = {}
    for _, test in ipairs(tests) do
        local success, result = pcall(test.test)
        table.insert(results, {
            name = test.name,
            success = success and (result == test.expected),
            result = tostring(result),
            expected = tostring(test.expected)
        })
    end
    
    return results
end

-- Run the tests and format the results
local function runTests()
    print("=== Running Basic Functionality Tests ===\n")
    
    local results = testBasicFunctionality()
    
    -- Print test results
    local passed = 0
    for i, result in ipairs(results) do
        local status = result.success and "✅ PASS" or "❌ FAIL"
        print(string.format("%d. %-30s %s", i, result.name, status))
        if not result.success then
            print(string.format("   Expected: %s", result.expected))
            print(string.format("   Got:      %s", result.result))
        end
        print()
        
        if result.success then
            passed = passed + 1
        end
    end
    
    -- Print summary
    print(string.format("\n=== Test Results: %d/%d passed ===", passed, #results))
    
    return passed == #results
end

-- Main execution
local success, result = pcall(runTests)
if not success then
    print("❌ Error running tests: " .. tostring(result))
    return false, "Test execution failed: " .. tostring(result)
end

return result
