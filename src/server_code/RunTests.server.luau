--!strict
-- RunTests.server.luau
-- Test runner for server-side tests

local TestEZ = require(script.Parent.Packages.TestEZ)

-- List all test files to run
local testLocations = {
    script.Parent.tests.MainModule.spec,
    script.Parent.tests.BuildingSystem.spec,
    -- Add more test files here as they're created
}

-- Run all tests
local results = TestEZ.TestBootstrap:run(
    testLocations,
    TestEZ.Reporters.TextReporterQuiet
)

-- Exit with appropriate status code
if results.failureCount > 0 then
    warn(string.format("\n❌ %d test(s) failed", results.failureCount))
else
    print(string.format("\n✅ All %d tests passed", results.successCount))
end

return results
