--!strict
-- RunCoverageDemo.server.luau
-- Script to run the coverage demo test in Roblox Studio using TestEZ

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _ServerStorage = game:GetService("ServerStorage")
local _TestService = game:GetService("TestService") -- Used for future test execution

print("🔍 Starting Coverage Demo Test...")

-- Load TestEZ modules from ReplicatedStorage with timeouts
local function safeWaitForChild(parent: Instance, name: string, timeout: number?): Instance?
    local child = parent:FindFirstChild(name)
    if child then return child end
    
    if timeout then
        return parent:WaitForChild(name, timeout)
    end
    return parent:WaitForChild(name)
end

-- Load TestEZ with error handling
local function safeRequire(module: Instance): any?
    local success, result = pcall(require, module)
    if not success then
        warn(`❌ Failed to load {module:GetFullName()}: {result}`)
        return nil
    end
    return result
end

-- Get TestEZ folder with timeout
local TestEZ = safeWaitForChild(ReplicatedStorage, "TestEZ", 5)
if not TestEZ then
    error("❌ TestEZ not found in ReplicatedStorage. Please ensure it's properly mapped in Rojo.")
end

-- Load TestEZ components
local testBootstrapModule = safeWaitForChild(TestEZ, "TestBootstrap", 5)
local _TestBootstrap = testBootstrapModule and safeRequire(testBootstrapModule)

local reportersFolder = safeWaitForChild(TestEZ, "Reporters", 5)
local textReporterModule = reportersFolder and safeWaitForChild(reportersFolder, "TextReporter", 5)
local _TextReporter = textReporterModule and safeRequire(textReporterModule)

-- Debugging the reporter
print("--- DEBUGGING ---")
print("TextReporter type: ", type(_TextReporter))
if type(_TextReporter) == "table" then
	print("TextReporter.report type: ", type(_TextReporter.report))
end
print("--- END DEBUGGING ---")

-- Verify TestEZ is loaded
if not (_TestBootstrap and _TextReporter) then
    error("❌ Failed to load required TestEZ modules. Please check the TestEZ installation.")
end

-- Find all test files
local function findTestFiles()
    local testFiles = {}
    local function scan(folder)
        for _, child in ipairs(folder:GetDescendants()) do
            if child:IsA("ModuleScript") and child.Name:match("%.spec$") then
                table.insert(testFiles, child)
            end
        end
    end
    
    -- Look for test files in ServerStorage/Tests
    local testsFolder = _ServerStorage:FindFirstChild("Tests")
    if testsFolder then
        scan(testsFolder)
    end
    
    -- Also check for our specific coverage demo test
    local coverageDemoTest = _ServerStorage:FindFirstChild("Tests/coverage_demo.spec")
    if coverageDemoTest and coverageDemoTest:IsA("ModuleScript") then
        table.insert(testFiles, coverageDemoTest)
    end
    
    return testFiles
end

-- Run the tests
local function runTests()
    print("\n🔍 Discovering test files...")
    local testFiles = findTestFiles()
    
    if #testFiles == 0 then
        warn("❌ No test files found!")
        return false
    end
    
    print("\n📋 Found " .. #testFiles .. " test files:")
    for _, testFile in ipairs(testFiles) do
        print("   ✓ " .. testFile:GetFullName())
    end
    
    print("\n🚀 Running tests individually...\n")
    
    local allTestsPassed = true

    for _, testFile in ipairs(testFiles) do
        print("--- Running test: " .. testFile:GetFullName() .. " ---")
        local success, results = pcall(function() 
            return _TestBootstrap:run({testFile}, _TextReporter, { showTimingInfo = false })
        end)

        if not success then
            warn("❌ Error running test file: " .. testFile:GetFullName())
            warn(results)
            allTestsPassed = false
        elseif type(results) == "table" and results.failureCount > 0 then
            allTestsPassed = false
            print("--- Test failed: " .. testFile:GetFullName() .. " ---")
        else
            print("--- Test passed: " .. testFile:GetFullName() .. " ---")
        end
    end
    
    return allTestsPassed
end

-- Start the test execution
local testsPassed = runTests()

-- Print final status
print("\n" .. (testsPassed and "✅ All tests completed successfully!" or "❌ Some tests failed!"))
return testsPassed
