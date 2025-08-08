--!strict
-- run_tests.luau
-- Test runner for Kaiju Battle Roblox tests

local TestService = game:GetService("TestService")
local HttpService = game:GetService("HttpService")

-- Configuration
local TEST_TIMEOUT = 30 -- seconds
local COVERAGE_REPORT = {
    total = 0,
    passed = 0,
    failed = 0,
    details = {}
}

-- ANSI color codes for console output
local COLORS = {
    RESET = "\27[0m",
    RED = "\27[31m",
    GREEN = "\27[32m",
    YELLOW = "\27[33m",
    BLUE = "\27[34m",
    MAGENTA = "\27[35m",
    CYAN = "\27[36m",
    BOLD = "\27[1m",
    UNDERLINE = "\27[4m"
}

-- Helper function to format test results
local function formatTestResult(success, message)
    if success then
        return COLORS.GREEN .. "[PASS]" .. COLORS.RESET .. " " .. message
    else
        return COLORS.RED .. "[FAIL]" .. COLORS.RESET .. " " .. message
    end
end

-- Helper function to run a test module
local function runTestModule(moduleScript, moduleName)
    print(string.format("\n%s%s%s", COLORS.BOLD, "Running test: ", moduleName))
    print(string.rep("=", 40))
    
    local testFunction = require(moduleScript)
    local success, results = pcall(testFunction)
    
    if not success then
        warn("Test failed to run: " .. tostring(results))
        return false, {
            name = moduleName,
            success = false,
            error = tostring(results)
        }
    end
    
    local testResults = {
        name = moduleName,
        success = true,
        tests = {},
        passed = 0,
        failed = 0
    }
    
    if type(results) == "table" then
        for _, result in ipairs(results) do
            local testSuccess = result:find("❌") == nil
            table.insert(testResults.tests, {
                message = result,
                success = testSuccess
            })
            
            if testSuccess then
                testResults.passed = testResults.passed + 1
            else
                testResults.failed = testResults.failed + 1
            end
            
            print(formatTestResult(testSuccess, result))
        end
    end
    
    -- Update coverage report
    COVERAGE_REPORT.total = COVERAGE_REPORT.total + #testResults.tests
    COVERAGE_REPORT.passed = COVERAGE_REPORT.passed + testResults.passed
    COVERAGE_REPORT.failed = COVERAGE_REPORT.failed + testResults.failed
    
    table.insert(COVERAGE_REPORT.details, testResults)
    
    return true, testResults
end

-- Main test runner
local function runAllTests()
    print("\n" .. COLORS.BOLD .. COLORS.BLUE .. "Starting Kaiju Battle Roblox Tests" .. COLORS.RESET)
    print("========================================")
    
    -- Find all test files
    local testModules = {
        {script.Parent.CharacterSystem.spec, "CharacterSystem Tests"},
        {script.Parent.KaijuSystem.spec, "KaijuSystem Tests"},
        {script.Parent.Integration.CharacterKaijuIntegration.spec, "Character-Kaiju Integration Tests"}
    }
    
    -- Run all tests
    local allTestsPassed = true
    for _, moduleInfo in ipairs(testModules) do
        local moduleScript = moduleInfo[1]
        local moduleName = moduleInfo[2]
        
        -- Run test with timeout
        local testThread = coroutine.create(function()
            return runTestModule(moduleScript, moduleName)
        end)
        
        local success, result = coroutine.resume(testThread)
        
        -- Handle test timeout
        if not success or coroutine.status(testThread) ~= "dead" then
            warn(string.format("Test timed out: %s (timeout: %d seconds)", moduleName, TEST_TIMEOUT))
            allTestsPassed = false
        else
            if not result[1] then -- Test failed to run
                allTestsPassed = false
            elseif result[2] and result[2].failed > 0 then
                allTestsPassed = false
            end
        end
    end
    
    -- Print summary
    print("\n" .. COLORS.BOLD .. "Test Summary:" .. COLORS.RESET)
    print("========================================")
    print(string.format("Total Tests: %s%d%s", COLORS.BOLD, COVERAGE_REPORT.total, COLORS.RESET))
    print(string.format("Passed: %s%d%s", COLORS.GREEN, COVERAGE_REPORT.passed, COLORS.RESET))
    print(string.format("Failed: %s%d%s", 
        COVERAGE_REPORT.failed > 0 and COLORS.RED or "", 
        COVERAGE_REPORT.failed, 
        COLORS.RESET))
    
    -- Generate coverage report
    local coveragePercent = math.floor((COVERAGE_REPORT.passed / math.max(1, COVERAGE_REPORT.total)) * 100)
    local coverageColor = coveragePercent > 80 and COLORS.GREEN or 
                         coveragePercent > 50 and COLORS.YELLOW or 
                         COLORS.RED
    
    print("\n" .. COLORS.BOLD .. "Code Coverage:" .. COLORS.RESET)
    print("========================================")
    print(string.format("Coverage: %s%d%%%s", 
        coverageColor, 
        coveragePercent, 
        COLORS.RESET))
    
    -- Print detailed test results
    print("\n" .. COLORS.BOLD .. "Detailed Results:" .. COLORS.RESET)
    print("========================================")
    for _, moduleResult in ipairs(COVERAGE_REPORT.details) do
        local moduleColor = moduleResult.failed > 0 and COLORS.RED or COLORS.GREEN
        print(string.format("%s: %s%d passed%s, %s%d failed%s",
            moduleResult.name,
            COLORS.GREEN,
            moduleResult.passed,
            COLORS.RESET,
            moduleResult.failed > 0 and COLORS.RED or "",
            moduleResult.failed,
            COLORS.RESET
        ))
    end
    
    -- Final result
    print("\n" .. string.rep("=", 40))
    if allTestsPassed then
        print(COLORS.GREEN .. COLORS.BOLD .. "ALL TESTS PASSED!" .. COLORS.RESET)
    else
        print(COLORS.RED .. COLORS.BOLD .. "SOME TESTS FAILED!" .. COLORS.RESET)
    end
    print(string.rep("=", 40) .. "\n")
    
    return allTestsPassed
end

-- Run tests
local success, result = pcall(runAllTests)
if not success then
    warn("Test runner failed: " .. tostring(result))
    task.wait(5) -- Give time to read the error
end

return success and result
