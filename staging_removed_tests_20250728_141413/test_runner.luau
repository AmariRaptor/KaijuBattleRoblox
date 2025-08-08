--!strict
-- test_runner.luau
-- A robust test runner for the Kaiju Battle project
-- Run with: luau test_runner.luau [options]

local TestRunner = {}

-- Coverage module
local coverage = nil
local coverageEnabled = false

-- Try to load coverage module
local function loadCoverage()
    if coverage ~= nil then return end -- Already loaded
    
    local ok, coverageModule = pcall(require, script:FindFirstChild("coverage") or "coverage")
    if ok and coverageModule then
        coverage = coverageModule
        coverageEnabled = true
        print("✅ Code coverage enabled")
    end
end

-- Initialize coverage if available
local function initCoverage()
    if not coverageEnabled then return end
    
    -- Configure coverage
    coverage.setVerbose(false) -- Set to true for debug output
    coverage.init()
    
    -- Print coverage header
    print("\n📊 Coverage tracking started")
    print("========================")
end

-- Finalize coverage and print report
local function finalizeCoverage()
    if not coverageEnabled then return end
    
    -- Generate coverage report
    local coverageData = coverage.finish()
    
    -- Print coverage summary
    if coverageData and coverageData.totalLines and coverageData.coveredLines then
        local coveragePercent = coverageData.totalLines > 0 
            and math.floor((coverageData.coveredLines / coverageData.totalLines) * 100) 
            or 0
            
        print("\n📊 Coverage Summary")
        print("==================")
        print(string.format("📈 Total Coverage: %d%% (%d/%d lines)", 
            coveragePercent, 
            coverageData.coveredLines, 
            coverageData.totalLines))
    end
end

-- Load coverage module at startup
loadCoverage()

-- Configuration
local CONFIG = {
    verbose = false,
    stopOnFailure = false,
    testPatterns = {
        "Tests/*.spec.luau",
        "Tests/**/*.spec.luau"
    },
    outputFile = "test-results.txt"
}

-- Test results tracking
local testResults = {
    total = 0,
    passed = 0,
    failed = 0,
    startTime = 0,
    endTime = 0,
    testFiles = {}
}

-- ANSI color codes for terminal output
local COLORS = {
    reset = "\27[0m",
    red = "\27[31m",
    green = "\27[32m",
    yellow = "\27[33m",
    blue = "\27[34m",
    magenta = "\27[35m",
    cyan = "\27[36m",
    white = "\27[37m",
    gray = "\27[90m"
}

-- Helper functions
local function log(message, color, indent)
    local indentStr = indent and string.rep("  ", indent) or ""
    local colorCode = COLORS[color] or ""
    local messageStr = tostring(message)
    
    if color then
        print(colorCode .. indentStr .. messageStr .. COLORS.reset)
    else
        print(indentStr .. messageStr)
    end
end

local function logVerbose(...)
    if CONFIG.verbose then
        log("[VERBOSE] " .. table.concat({...}, " "), "gray")
    end
end

local function findTestFiles()
    local testFiles = {}
    
    -- This is a simplified version - in a real implementation, you would use
    -- a filesystem library to find all files matching the patterns
    table.insert(testFiles, "Tests/KaijuSystem.simplified.spec")
    table.insert(testFiles, "Tests/CharacterSystem.fixed.spec")
    table.insert(testFiles, "Tests/ScoringSystem.simplified.spec")
    
    return testFiles
end

-- Test execution
local function executeTestFile(testFile)
    logVerbose("Loading test file: " .. testFile)
    
    local chunk, err = loadfile(testFile)
    if not chunk then
        return false, "Failed to load test file: " .. tostring(err)
    end
    
    local success, testFunc = pcall(chunk)
    if not success then
        return false, "Error in test file: " .. tostring(testFunc)
    end
    
    if type(testFunc) ~= "function" then
        return false, "Test file did not return a function"
    end
    
    local testSuccess, testResult = pcall(testFunc)
    if not testSuccess then
        return false, "Test execution failed: " .. tostring(testResult)
    end
    
    return true, testResult
end

-- Format test results
local function formatTestResults(results)
    local output = {}
    
    for _, fileResult in ipairs(results.testFiles) do
        table.insert(output, string.format("\n%s (%d tests)", fileResult.file, #fileResult.results))
        
        for _, testResult in ipairs(fileResult.results) do
            local status = testResult.passed and "✅" or "❌"
            local message = string.format("  %s %s", status, testResult.message)
            
            if testResult.error then
                message = message .. "\n      " .. testResult.error:gsub("\n", "\n      ")
            end
            
            table.insert(output, message)
        end
    end
    
    -- Add summary
    local totalTime = results.endTime - results.startTime
    table.insert(output, "\n" .. string.rep("=", 60))
    table.insert(output, "TEST SUMMARY")
    table.insert(output, string.rep("=", 60))
    table.insert(output, string.format("Total test files: %d", #results.testFiles))
    table.insert(output, string.format("Total tests: %d", results.total))
    table.insert(output, string.format("✅ Passed: %d", results.passed))
    table.insert(output, string.format("❌ Failed: %d", results.failed))
    table.insert(output, string.format("Time: %.3f seconds", totalTime))
    table.insert(output, string.rep("=", 60))
    
    return table.concat(output, "\n")
end

-- Main test runner function
function TestRunner.runTests()
    testResults.startTime = os.clock()
    
    log("\n" .. string.rep("=", 60), "cyan")
    log("🚀 STARTING TEST RUN", "cyan")
    log(string.rep("=", 60) .. "\n", "cyan")
    
    local testFiles = findTestFiles()
    
    if #testFiles == 0 then
        log("No test files found!", "yellow")
        return false
    end
    
    log(string.format("Found %d test files:", #testFiles))
    for i, file in ipairs(testFiles) do
        log(string.format("  %d. %s", i, file))
    end
    
    -- Run tests
    for _, testFile in ipairs(testFiles) do
        log("\n" .. string.rep("-", 60), "blue")
        log("RUNNING: " .. testFile, "blue")
        log(string.rep("-", 60), "blue")
        
        local fileResults = {
            file = testFile,
            results = {},
            startTime = os.clock()
        }
        
        local success, result = executeTestFile(testFile)
        
        if success then
            if type(result) == "table" then
                for _, line in ipairs(result) do
                    local passed = line:sub(1, 1) == "✅"
                    table.insert(fileResults.results, {
                        message = line,
                        passed = passed,
                        error = not passed and line or nil
                    })
                    
                    testResults.total = testResults.total + 1
                    if passed then
                        testResults.passed = testResults.passed + 1
                    else
                        testResults.failed = testResults.failed + 1
                    end
                    
                    log(line, passed and "green" or "red", 2)
                end
            else
                -- Handle non-table results
                table.insert(fileResults.results, {
                    message = tostring(result),
                    passed = true
                })
                testResults.passed = testResults.passed + 1
                testResults.total = testResults.total + 1
                log("ℹ️ " .. tostring(result), "yellow", 2)
            end
        else
            table.insert(fileResults.results, {
                message = "Test execution failed",
                passed = false,
                error = tostring(result)
            })
            testResults.failed = testResults.failed + 1
            testResults.total = testResults.total + 1
            log("❌ " .. tostring(result), "red", 2)
            
            if CONFIG.stopOnFailure then
                break
            end
        end
        
        fileResults.endTime = os.clock()
        fileResults.duration = fileResults.endTime - fileResults.startTime
        
        table.insert(testResults.testFiles, fileResults)
    end
    
    testResults.endTime = os.clock()
    
    -- Print summary
    local summary = formatTestResults(testResults)
    log("\n" .. summary)
    
    -- Write results to file
    local file = io.open(CONFIG.outputFile, "w")
    if file then
        file:write(summary)
        file:close()
        log("\nResults written to: " .. CONFIG.outputFile, "cyan")
    end
    
    return testResults.failed == 0
end

-- Command line interface
local function parseArgs(args)
    for _, arg in ipairs(args) do
        if arg == "-v" or arg == "--verbose" then
            CONFIG.verbose = true
        elseif arg == "--stop-on-failure" then
            CONFIG.stopOnFailure = true
        elseif arg:sub(1, 1) == "-" then
            log("Unknown option: " .. arg, "yellow")
            return false
        end
    end
    return true
end

-- Main execution
if not ... then
    local success = parseArgs({...})
    if not success then
        os.exit(1)
    end
    
    -- Initialize coverage
    initCoverage()
    
    -- Run tests
    local testsPassed = TestRunner.runTests()
    
    -- Finalize coverage and print report
    finalizeCoverage()
    
    -- Exit with appropriate status code
    os.exit(testsPassed and 0 or 1)
end

return TestRunner
