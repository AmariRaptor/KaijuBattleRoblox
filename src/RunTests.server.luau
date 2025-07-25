--!strict
-- Test runner script for TestEZ

-- Get TestEZ modules
local TestEZ = {
    TestBootstrap = require(game:GetService("ServerScriptService").TestEZ.TestBootstrap),
    TextReporter = require(game:GetService("ServerScriptService").TestEZ.Reporters.TextReporter)
}

-- Find all test files in the tests directory
local function findTestFiles()
    local testFiles = {}
    local testsFolder = game:GetService("ServerStorage"):FindFirstChild("Tests")
    
    if not testsFolder then
        warn("Tests folder not found in ServerStorage")
        return testFiles
    end
    
    -- Find all test files recursively
    local function scan(folder)
        for _, child in ipairs(folder:GetChildren()) do
            if child:IsA("ModuleScript") and child.Name:match("%.spec$") then
                table.insert(testFiles, child)
            elseif child:IsA("Folder") then
                scan(child)
            end
        end
    end
    
    scan(testsFolder)
    return testFiles
end

-- Run all tests
local function runTests()
    print("🚀 Running tests...\n")
    
    local testFiles = findTestFiles()
    
    if #testFiles == 0 then
        warn("No test files found!")
        return
    end
    
    local testModules = {}
    
    for _, moduleScript in ipairs(testFiles) do
        local success, testModule = pcall(require, moduleScript)
        if success then
            table.insert(testModules, {
                method = testModule,
                path = {moduleScript.Name},
                pathStringForSorting = moduleScript:GetFullName()
            })
        else
            warn("Failed to load test module", moduleScript:GetFullName(), "\n", testModule)
        end
    end
    
    if #testModules == 0 then
        warn("No valid test modules found!")
        return
    end
    
    -- Run tests with TextReporter
    local success, results = pcall(function()
        return TestEZ.TestBootstrap:run(testModules, TestEZ.TextReporter, {
            testNamePattern = nil, -- Run all tests
            showTimingInfo = true,
            extraEnvironment = {}
        })
    end)
    
    if not success then
        warn("Error running tests:", results)
    else
        print("\n✅ Tests completed!")
    end
    
    return results
end

-- Run tests when the script runs
return runTests()
