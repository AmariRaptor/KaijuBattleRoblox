--!strict
-- RunAllTests.luau
-- Enhanced test runner for executing all test files in the project

type TestResult = {
    name: string,
    success: boolean,
    message: string,
    duration: number,
    error: string?
}

type TestFile = {
    name: string,
    path: string,
    instance: ModuleScript?
}

local TestService = game:GetService("TestService")
local ServerStorage = game:GetService("ServerStorage")

local function formatDuration(seconds: number): string
    return string.format("%.3fs", seconds)
end

local function runTest(testFile: TestFile): TestResult
    local startTime = os.clock()
    local result: TestResult = {
        name = testFile.name,
        success = false,
        message = "",
        duration = 0,
        error = nil
    }
    
    -- Load the test module
    local success, testFunction = pcall(require, testFile.instance :: ModuleScript)
    
    if not success then
        result.success = false
        result.error = string.format("Failed to load test: %s", tostring(testFunction))
        result.duration = os.clock() - startTime
        return result
    end
    
    -- Verify the test module returns a function
    if type(testFunction) ~= "function" then
        result.success = false
        result.error = "Test module did not return a function"
        result.duration = os.clock() - startTime
        return result
    end
    
    -- Run the test function
    local testSuccess, testResult = pcall(testFunction)
    result.duration = os.clock() - startTime
    
    if not testSuccess then
        result.success = false
        result.error = tostring(testResult)
    else
        result.success = true
        result.message = tostring(testResult or "Test completed")
    end
    
    return result
end

local function findTestFiles(): {TestFile}
    local testFiles: {TestFile} = {}
    
    -- Define test file patterns to look for
    local testPatterns = {
        "%.spec%.luau$",
        "%Test%.luau$",
        "Test%w+%.luau$"
    }
    
    -- Function to check if a filename matches any test pattern
    local function isTestFile(name: string): boolean
        for _, pattern in ipairs(testPatterns) do
            if name:match(pattern) then
                return true
            end
        end
        return false
    end
    
    -- Recursively find test files in a folder
    local function scanFolder(folder: Instance, path: string)
        for _, child in ipairs(folder:GetChildren()) do
            local childPath = path .. "/" .. child.Name
            
            if child:IsA("Folder") then
                scanFolder(child, childPath)
            elseif child:IsA("ModuleScript") and isTestFile(child.Name) then
                table.insert(testFiles, {
                    name = child.Name,
                    path = childPath,
                    instance = child
                })
            end
        end
    end
    
    -- Start scanning from ServerStorage
    scanFolder(ServerStorage, "ServerStorage")
    
    return testFiles
end

local function runTests()
    print("\n=== Starting Test Runner ===\n")
    
    -- Find all test files
    local testFiles = findTestFiles()
    
    if #testFiles == 0 then
        print("❌ No test files found in ServerStorage")
        return "No test files found"
    end
    
    -- Sort tests by path for consistent execution order
    table.sort(testFiles, function(a, b)
        return a.path < b.path
    end)
    
    print(string.format("Found %d test files:\n", #testFiles))
    
    -- Run tests and collect results
    local results: {TestResult} = {}
    local totalPassed = 0
    local totalFailed = 0
    local totalTime = 0
    
    for _, testFile in ipairs(testFiles) do
        print(string.format("Running %s...", testFile.path))
        local result = runTest(testFile)
        totalTime += result.duration
        
        if result.success then
            totalPassed += 1
            print(string.format("✅ [PASS] %s (%s) - %s", 
                testFile.name, 
                formatDuration(result.duration),
                result.message
            ))
        else
            totalFailed += 1
            print(string.format("❌ [FAIL] %s (%s) - %s", 
                testFile.name, 
                formatDuration(result.duration),
                result.error or "Test failed"
            ))
        end
        
        table.insert(results, result)
    end
    
    -- Print summary
    print("\n=== Test Summary ===")
    print(string.format("Total: %d, Passed: %d, Failed: %d, Time: %s\n",
        #results,
        totalPassed,
        totalFailed,
        formatDuration(totalTime)
    ))
    
    -- Print detailed failure messages
    if totalFailed > 0 then
        print("Failed Tests:")
        for _, result in ipairs(results) do
            if not result.success then
                print(string.format("\n❌ %s", result.name))
                print(string.format("   Error: %s", result.error or "Unknown error"))
            end
        end
    end
    
    return string.format("Tests completed: %d passed, %d failed", totalPassed, totalFailed)
end

-- Run the tests and return the results
return runTests()
