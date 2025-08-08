--!strict
-- RunBuildingSystemTests.luau
-- Test runner for BuildingSystem tests in MCP environment

local TestEZ = require(game:GetService("ReplicatedStorage").TestEZ)
local TestBootstrap = TestEZ.TestBootstrap

print("🚀 Starting BuildingSystem tests...")

-- Load the test module
local testModule = require(script.Parent.Tests.Systems.BuildingSystem)

-- Run the tests
local results = TestBootstrap:run({}, testModule)

-- Print results
print("\n📊 BuildingSystem Test Results:")
print(string.rep("-", 50))

local passed = 0
local failed = 0
local skipped = 0

-- Simple test execution since we're using a custom test format
if type(testModule) == "function" then
    -- Run the test function directly
    local success, result = pcall(testModule)
    if success then
        print("✅ All BuildingSystem tests passed!")
        passed = 1
    else
        print("❌ BuildingSystem tests failed:", result)
        failed = 1
    end
else
    -- Fallback to TestEZ if available
    for _, result in ipairs(results or {}) do
        for _, testResult in ipairs(result.results or {}) do
            if testResult.status == TestEZ.TestStatus.Success then
                passed += 1
                print("✅ " .. testResult.planNode.phrase)
            elseif testResult.status == TestEZ.TestStatus.Failure then
                failed += 1
                print("❌ " .. testResult.planNode.phrase)
                if testResult.failureTrace then
                    print("   " .. testResult.failureTrace)
                end
                if testResult.message then
                    print("   " .. testResult.message)
                end
            else
                skipped += 1
                print("⏭️ " .. testResult.planNode.phrase .. " (skipped)")
            end
        end
    end
end

print("\n📋 Summary:")
print("✅ Passed: " .. passed)
print("❌ Failed: " .. failed)
print("⏭️ Skipped: " .. skipped)
print(string.rep("-", 50))

return {
    passed = passed,
    failed = failed,
    skipped = skipped
}
