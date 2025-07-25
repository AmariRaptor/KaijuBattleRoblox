-- TestRunner.lua
-- A test runner that discovers and runs all tests in the game

print("=== Starting Test Runner ===\n")

-- List of all test modules to run
local TEST_MODULES = {
    "SimpleReturnTest",
    "ClassSystemDirectTest",
    "KaijuSystemDirectTest",
    "BuildingSystemDirectTest"
}

-- Track test results
local testResults = {
    total = 0,
    passed = 0,
    failed = 0,
    errors = 0,
    details = {}
}

-- Function to run a single test module
local function runTestModule(moduleName)
    local success, result = pcall(function()
        return require(game:GetService('ServerScriptService')[moduleName])
    end)
    
    local testResult = {
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
            testResult.message = testResult.success and "Test passed" or "Test failed"
            
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
print("=== Running Tests ===\n")

for _, moduleName in ipairs(TEST_MODULES) do
    print(string.format("Running test: %s", moduleName))
    local result = runTestModule(moduleName)
    print(string.format("  %s: %s\n", result.success and "✅ PASS" or "❌ FAIL", result.message))
end

-- Print summary
print("\n=== Test Summary ===")
print(string.format("Total: %d", testResults.total))
print(string.format("✅ Passed: %d", testResults.passed))
print(string.format("❌ Failed: %d", testResults.failed))
if testResults.errors > 0 then
    print(string.format("⚠️ Errors: %d", testResults.errors))
end

-- Print detailed results
if testResults.failed > 0 or testResults.errors > 0 then
    print("\n=== Failed Tests ===")
    for _, result in ipairs(testResults.details) do
        if not result.success then
            print(string.format("%s: %s", result.name, result.message))
        end
    end
end

-- Return overall result
local overallSuccess = testResults.failed == 0 and testResults.errors == 0
return {
    success = overallSuccess,
    message = string.format("Test run completed. %d passed, %d failed, %d errors", 
        testResults.passed, testResults.failed, testResults.errors)
}
