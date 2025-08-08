-- DirectRunTest.luau
-- A script to test direct execution in the MCP environment

-- This script is designed to be pasted directly into the MCP run_code function
-- to test basic functionality without relying on file loading

local function runTest()
    -- Test basic Lua functionality
    local tests = {
        {
            name = "String concatenation",
            test = function() return "Hello" .. " " .. "World" end,
            expected = "Hello World"
        },
        {
            name = "Table operations",
            test = function() 
                local t = {a=1, b=2}
                t.c = 3
                return t.a + t.b + t.c 
            end,
            expected = 6
        },
        {
            name = "Math operations",
            test = function() return 2 + 2 * 2 end,
            expected = 6
        },
        {
            name = "String functions",
            test = function() return string.upper("test") end,
            expected = "TEST"
        },
        {
            name = "Table library",
            test = function() 
                local t = {3, 1, 2}
                table.sort(t)
                return table.concat(t, ",") 
            end,
            expected = "1,2,3"
        },
        {
            name = "Function definition and call",
            test = function()
                local function add(a, b)
                    return a + b
                end
                return add(5, 3)
            end,
            expected = 8
        },
        {
            name = "Error handling with pcall",
            test = function()
                local success, result = pcall(function()
                    return "No error"
                end)
                return success and result or "Error"
            end,
            expected = "No error"
        }
    }
    
    -- Run tests
    local results = {}
    local passed = 0
    
    debug.output("=== Starting Direct Run Test ===\n")
    
    for i, test in ipairs(tests) do
        local success, result = pcall(test.test)
        local testPassed = success and (tostring(result) == tostring(test.expected))
        
        debug.output(string.format("%d. %-30s %s", 
            i, 
            test.name, 
            testPassed and "✅ PASS" or "❌ FAIL"))
            
        if not testPassed then
            debug.output(string.format("   Expected: %s", tostring(test.expected)))
            debug.output(string.format("   Got:      %s", tostring(result)))
        end
        
        debug.output("")
        
        if testPassed then
            passed = passed + 1
        end
    end
    
    -- Print summary
    debug.output(string.format("=== Test Results: %d/%d passed ===", passed, #tests))
    
    return passed == #tests, {
        passed = passed,
        total = #tests
    }
end

-- Run the test
local success, result = pcall(runTest)
if not success then
    debug.output("❌ Error running tests: " .. tostring(result))
    return false, "Test execution failed: " .. tostring(result)
end

return result
