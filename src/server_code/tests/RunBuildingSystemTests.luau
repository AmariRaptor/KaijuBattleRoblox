--!strict

local TestEZ = require(game:GetService("ReplicatedStorage").TestEZ)

-- Import the test suite
local testModulePath = script.Parent.Tests.Systems.BuildingSystem
local tests = {}

-- Load the test suite with error handling
local loadSuccess, testModule = pcall(function()
    return require(testModulePath)
end)

if not loadSuccess then
    warn("Failed to load test module:", testModule)
    return false
end

tests.BuildingSystem = testModule

-- Run the tests and output results to the console
local runSuccess, message = pcall(function()
    print("\n=== Running BuildingSystem Tests ===\n")
    TestEZ.TestBootstrap:run(tests, TestEZ.Reporters.TextReporter)
end)

if not runSuccess then
    warn("Test runner encountered an error:")
    warn(message)
    return false
end

return true
