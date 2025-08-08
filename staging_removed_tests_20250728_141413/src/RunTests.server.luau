--!strict
-- Test runner script for TestEZ

-- Services
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Get TestEZ modules
local TestEZ = {
    TestBootstrap = require(ReplicatedStorage.TestEZ.TestBootstrap),
    TextReporter = require(ReplicatedStorage.TestEZ.Reporters.TextReporter)
}

-- Find all test files in the tests directory
local function findTestFiles()
    local testFiles = {}
    local testsFolder = ServerScriptService:FindFirstChild("Tests")
    
    if not testsFolder then
        warn("❌ Tests folder not found in ServerStorage")
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

-- Convert a test module to TestEZ format
local function convertToTestEZ(moduleScript)
    local success, testModule = pcall(require, moduleScript)
    if not success then
        warn(string.format("❌ Failed to load test module %s: %s", moduleScript:GetFullName(), tostring(testModule)))
        return nil
    end
    
    -- Handle different test module formats
    if type(testModule) == "function" then
        -- Simple test function
        return {
            [moduleScript.Name] = testModule
        }
    elseif type(testModule) == "table" then
        -- Table with test functions
        local tests = {}
        for name, test in pairs(testModule) do
            if type(test) == "function" then
                tests[name] = test
            end
        end
        return tests
    else
        warn(string.format("❌ Invalid test module format in %s: expected function or table, got %s", 
            moduleScript:GetFullName(), type(testModule)))
        return nil
    end
end

-- Run all tests
local function runTests()
    print("🚀 Running tests...\n")
    
    local testFiles = findTestFiles()
    print(string.format("📋 Found %d test files", #testFiles))
    
    if #testFiles == 0 then
        warn("❌ No test files found!")
        return
    end
    
    -- Run tests for each file
    for _, moduleScript in ipairs(testFiles) do
        print(string.format("\n🔍 Running tests in %s", moduleScript:GetFullName()))
        
        local testModule = convertToTestEZ(moduleScript)
        if not testModule then
            warn(string.format("❌ Skipping tests in %s due to errors", moduleScript:GetFullName()))
            goto continue
        end
        
        -- Create a test container module
        local testContainer = Instance.new("ModuleScript")
        testContainer.Name = moduleScript.Name
        testContainer.Source = [[
            --!strict
            return {
                ]] .. moduleScript.Name .. [[ = function()
                    local testModule = require(]] .. tostring(moduleScript:GetFullName()) .. [[)
                    return testModule
                end
            }
        ]]
        testContainer.Parent = ServerScriptService
        
        -- Run tests with TestBootstrap
        local success, results = pcall(function()
            return TestEZ.TestBootstrap:run({
                testContainer
            }, TestEZ.TextReporter)
        end)
        
        -- Clean up
        testContainer:Destroy()
        
        if not success then
            warn(string.format("❌ Error running tests in %s: %s", moduleScript:GetFullName(), tostring(results)))
        end
        
        ::continue::
    end
    
    print("\n✅ All tests completed!")
end

-- Run tests when the script runs
return runTests()
