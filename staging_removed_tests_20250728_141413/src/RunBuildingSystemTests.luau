--!strict

-- Import TestEZ
local TestEZ = require(game:GetService("ReplicatedStorage").TestEZ)

-- Run all tests
local results = TestEZ.TestBootstrap:run({
    game:GetService("ServerStorage").Tests.BuildingSystem
})

-- Output results
print("\n=== BuildingSystem Test Results ===")
print(string.format("Passed: %d", #results.successes))
print(string.format("Failed: %d", #results.failures))
print("================================\n")
