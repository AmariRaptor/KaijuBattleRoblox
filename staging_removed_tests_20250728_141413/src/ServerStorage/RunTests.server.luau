--!strict
-- Test runner script for TestEZ

-- Get TestEZ modules
local TestEZ = {
    TestBootstrap = require(game:GetService("ServerScriptService").TestEZ.TestBootstrap),
    TextReporter = require(game:GetService("ServerScriptService").TestEZ.Reporters.TextReporter)
}

-- Enable strict mode for better error detection
local _ = {
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    ServerScriptService = game:GetService("ServerScriptService")
}

local ServerStorage = game:GetService("ServerStorage")
local TestService = game:GetService("TestService")

-- Configure test reporter
local DEFAULT_OPTIONS = {
    testNamePattern = nil, -- Run all tests by default
    showTimingInfo = true,
    testNameSuffix = "",
    extraEnvironment = {}
}

-- Find all test files in the tests directory
local function findTestFiles()
    local testFiles = {}
    local testsFolder = ServerStorage:FindFirstChild("Tests")
    
    if not testsFolder then
        warn("❌ Tests folder not found in ServerStorage")
        return testFiles
    end
    
    print("🔍 Searching for test files in:", testsFolder:GetFullName())
    
    -- Find all test files recursively
    local function scan(folder)
        for _, child in ipairs(folder:GetDescendants()) do
            if child:IsA("ModuleScript") and child.Name:match("%.spec$") then
                table.insert(testFiles, child)
                print("   ✓ Found test file:", child:GetFullName())
            end
        end
    end
    
    scan(testsFolder)
    return testFiles
end

-- Run all tests
local function runTests()
    print("\n🚀 Starting test runner...")
    print("📦 TestEZ Version: ", TestEZ.TestBootstrap.VERSION)
    print("📁 Test Directory: ServerStorage/Tests\n")
    
    local testFiles = findTestFiles()
    
    if #testFiles == 0 then
        warn("❌ No test files found!")
        return false
    end
    
    local testModules = {}
    
    -- Load all test modules
    for _, moduleScript in ipairs(testFiles) do
        local success, testModule = pcall(require, moduleScript)
        if success then
            if type(testModule) == "function" then
                table.insert(testModules, testModule)
            else
                warn(string.format("⚠️  Test module %s does not return a function", moduleScript:GetFullName()))
            end
        else
            warn(string.format("❌ Failed to load test module %s: %s", moduleScript:GetFullName(), tostring(testModule)))
        end
    end
    
    if #testModules == 0 then
        warn("❌ No valid test modules found!")
        return false
    end
    
    print(string.format("\n🔍 Running %d test modules...\n", #testModules))
    
    -- Run tests with TestEZ
    local success, results = pcall(function()
        TestEZ.TestBootstrap.run(testModules, {
            testNamePattern = DEFAULT_OPTIONS.testNamePattern,
            showTimingInfo = DEFAULT_OPTIONS.showTimingInfo,
            testNameSuffix = DEFAULT_OPTIONS.testNameSuffix,
            extraEnvironment = DEFAULT_OPTIONS.extraEnvironment
        })
        return true
    end)
    
    if not success then
        warn("❌ Error running tests:", results)
        return false
    end
    
    print("\n✅ Tests completed!")
    return true
end

-- Run tests when server starts
local function initialize()
    -- Run tests immediately when the script runs
    local success, result = pcall(runTests)
    
    if not success then
        warn("❌ Error initializing test runner:", result)
    end
    
    -- Also provide a way to run tests remotely if needed
    TestService:SetMessage("RunTests", function()
        return runTests()
    end)
    
    print("\n✨ Test runner initialized! Use TestService:Message('RunTests') to run tests again.")
end

-- Initialize the test runner
local initSuccess, initErr = pcall(initialize)
if not initSuccess then
    warn("❌ Failed to initialize test runner:", initErr)
end

-- Clean up when server shuts down
game:BindToClose(function()
    print("\n🛑 Server shutting down...")
end)

return {
    runTests = runTests
}
