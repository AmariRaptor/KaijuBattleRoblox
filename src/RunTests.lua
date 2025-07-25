--!strict
-- Test runner script for TestEZ

local TestService = game:GetService("TestService")
local ServerScriptService = game:GetService("ServerScriptService")
local TestEZ = {
    TestBootstrap = require(ServerScriptService.TestEZ.TestBootstrap),
    TestEnum = require(ServerScriptService.TestEZ.TestEnum),
    TextReporter = require(ServerScriptService.TestEZ.Reporters.TextReporter),
}

-- Find all test files in the tests directory
local function findTestFiles()
    local testFiles = {}
    
    local function scanDirectory(directory)
        for _, child in ipairs(directory:GetChildren()) do
            if child:IsA("ModuleScript") and child.Name:match("%.spec$") then
                table.insert(testFiles, child)
            elseif child:IsA("Folder") then
                scanDirectory(child)
            end
        end
    end
    
    local testsFolder = script.Parent.tests
    if testsFolder then
        scanDirectory(testsFolder)
    end
    
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
        table.insert(testModules, {
            method = require(moduleScript),
            path = {moduleScript.Name},
            pathStringForSorting = moduleScript:GetFullName()
        })
    end
    
    -- Run tests with TextReporter
    local results = TestEZ.TestBootstrap:run(testModules, TestEZ.TextReporter, {
        testNamePattern = nil, -- Run all tests
        showTimingInfo = true,
        extraEnvironment = {}
    })
    
    print("\n✅ Tests completed!")
    return results
end

-- Run tests when the script is required
return runTests()
