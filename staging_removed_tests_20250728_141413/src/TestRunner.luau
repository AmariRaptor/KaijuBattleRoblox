--!strict
-- TestRunner.luau
-- A test runner that discovers and runs all tests in the game with strict Luau types

print("=== Starting Test Runner ===\n")

-- Types
type TestResult = {
    success: boolean,
    message: string,
    name: string
}

type TestResults = {
    total: number,
    passed: number,
    failed: number,
    errors: number,
    details: {TestResult}
}

-- List of all test modules to run
local TEST_MODULES: {string} = {
    "SimpleReturnTest",
    "ClassSystemDirectTest",
    "KaijuSystemDirectTest",
    "BuildingSystemDirectTest",
    "CharacterSystemDirectTest"
}

-- Track test results
local testResults: TestResults = {
    total = 0,
    passed = 0,
    failed = 0,
    errors = 0,
    details = {}
}

-- Function to run a single test module
local function runTestModule(moduleName: string): TestResult
    local success, result = pcall(function()
        local moduleScript = game:GetService('ServerScriptService'):FindFirstChild(moduleName)
        if not moduleScript then
            error(string.format("Test module '%s' not found in ServerScriptService", moduleName))
        end
        return require(moduleScript :: ModuleScript)
    end)
    
    local testResult: TestResult = {
        name = moduleName,
        success = false,
        message = ""
    }
    
    if not success then
        testResult.message = "Error loading test: " .. tostring(result)
        testResults.errors = testResults.errors + 1
    else
        if type(result) == "table" and result.success ~= nil then
            testResult.success = result.success == true
            testResult.message = result.message or (testResult.success and "Test passed" or "Test failed")
            
            if testResult.success then
                testResults.passed = testResults.passed + 1
            else
                testResults.failed = testResults.failed + 1
            end
        else
            testResult.success = result ~= false and result ~= nil
            testResult.message = testResult.success and "Test passed (implicit success)" or "Test failed (implicit failure)"
            
            if testResult.success then
                testResults.passed = testResults.passed + 1
            else
                testResults.failed = testResults.failed + 1
            end
        end
    end
    
    testResults.total = testResults.total + 1
    table.insert(testResults.details, testResult)
    
    return testResult
end

-- Run all tests
local function runAllTests()
    print(string.format("Running %d test modules...\n", #TEST_MODULES))
    
    for _, moduleName in ipairs(TEST_MODULES) do
        local startTime = os.clock()
        local result = runTestModule(moduleName)
        local elapsedTime = os.clock() - startTime
        
        local status = result.success and "✅ PASS" or "❌ FAIL"
        print(string.format("%s %s (%.3fs) - %s", 
            status, 
            result.name, 
            elapsedTime,
            result.message))
    end
    
    -- Print summary
    print("\n=== Test Summary ===")
    print(string.format("Total: %d, Passed: %d, Failed: %d, Errors: %d",
        testResults.total,
        testResults.passed,
        testResults.failed,
        testResults.errors))
    
    -- Return overall success (true if all tests passed and no errors)
    local overallSuccess = testResults.failed == 0 and testResults.errors == 0
    print(overallSuccess and "\n✅ All tests passed!" or "\n❌ Some tests failed")
    
    return overallSuccess, testResults
end

-- Run the tests and return the results
local success, results = pcall(runAllTests)
if not success then
    warn("Test runner encountered an error:", results)
    return {success = false, message = "Test runner error: " .. tostring(results)}
end

-- Return the test results
return {
    success = results,
    message = string.format("Tests completed: %d total, %d passed, %d failed, %d errors",
        testResults.total,
        testResults.passed,
        testResults.failed,
        testResults.errors),
    results = testResults
}
