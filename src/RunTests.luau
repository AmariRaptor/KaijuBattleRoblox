--!strict
-- Test runner script for TestEZ with strict Luau types

local TestService = game:GetService("TestService")
local ServerScriptService = game:GetService("ServerScriptService")

-- Types
type TestModule = {
    method: any,
    path: {string}
}

type TestBootstrap = {
    run: (testModules: {TestModule}, reporters: {any}) -> ()
}

type TestEZ = {
    TestBootstrap: TestBootstrap,
    TestEnum: any,
    TextReporter: any
}

-- Import TestEZ with type assertion
local TestEZ: TestEZ = {
    TestBootstrap = require(ServerScriptService.TestEZ.TestBootstrap) :: TestBootstrap,
    TestEnum = require(ServerScriptService.TestEZ.TestEnum),
    TextReporter = require(ServerScriptService.TestEZ.Reporters.TextReporter)
}

-- Find all test files in the tests directory
local function findTestFiles(): {Instance}
    local testFiles: {Instance} = {}
    
    local function scanDirectory(directory: Instance): ()
        for _, child in ipairs(directory:GetChildren()) do
            if child:IsA("ModuleScript") and child.Name:match("%.spec$") then
                table.insert(testFiles, child)
            elseif child:IsA("Folder") then
                scanDirectory(child)
            end
        end
    end
    
    local testsFolder = script.Parent:FindFirstChild("tests")
    if testsFolder then
        scanDirectory(testsFolder)
    end
    
    return testFiles
end

-- Run all tests
local function runTests(): ()
    print("🚀 Running tests...\n")
    
    local testFiles = findTestFiles()
    
    if #testFiles == 0 then
        warn("No test files found!")
        return
    end
    
    local testModules: {TestModule} = {}
    
    for _, moduleScript in ipairs(testFiles) do
        local success, module = pcall(require, moduleScript)
        if success then
            table.insert(testModules, {
                method = module,
                path = {moduleScript.Name}
            })
        else
            warn(string.format("Failed to require test module %s: %s", moduleScript:GetFullName(), tostring(module)))
        end
    end
    
    if #testModules == 0 then
        warn("No valid test modules found!")
        return
    end
    
    -- Run tests with TextReporter
    TestEZ.TestBootstrap.run(testModules, {
        TestEZ.TextReporter
    })
end

-- Run tests when required
return {
    runTests = runTests
}
