--!strict

-- Robust pre-loading and diagnostic script

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestEZ = ReplicatedStorage.TestEZ

print("--- Pre-loading and Patching TestEZ Modules ---")

local s_results, TestResults = pcall(function() return require(TestEZ.TestResults) end)
if not s_results then
    warn("FATAL: Failed to load TestResults: ", tostring(TestResults))
    return
end

-- Monkey-patch the missing addChild method
function TestResults:addChild(parent, planNode)
	local node = self.createNode(planNode)
	local target = parent or self
	table.insert(target.children, node)
	return node
end

local s_bootstrap, TestBootstrap = pcall(function() return require(TestEZ.TestBootstrap) end)
local s_reporter, TextReporter = pcall(function() return require(TestEZ.Reporters.TextReporter) end)

if not (s_bootstrap and s_reporter) then
    warn("FATAL: Failed to pre-load essential TestEZ modules.")
    if not s_bootstrap then warn(" -> Failed to load TestBootstrap: ", tostring(TestBootstrap)) end
    if not s_reporter then warn(" -> Failed to load TextReporter: ", tostring(TextReporter)) end
    return
end

print("--- Pre-loading complete. Running tests. ---")

-- The folder where all tests are stored
local testsRoot = game:GetService("ServerStorage").Tests

local overallSuccess = true

for _, test in ipairs(testsRoot:GetChildren()) do
	-- Ignore the runner script itself and any non-spec files
	if test:IsA("ModuleScript") and test.Name:match(".spec$") then
		print("--- Running Test: " .. test.Name .. " ---")

		local testCoroutine = coroutine.create(function()
			-- Re-require modules inside the coroutine for a clean state
			local TestBootstrap = require(TestEZ.TestBootstrap)
			local TextReporter = require(TestEZ.Reporters.TextReporter)

			local success, results = pcall(TestBootstrap.run, TestBootstrap, {test}, TextReporter)

			if not success then
				warn("  -> ERROR: Test runner failed for spec: " .. test.Name .. " with error: " .. tostring(results))
				overallSuccess = false
			elseif not results.success then
				print("  -> FAILED: " .. test.Name)
				overallSuccess = false
			else
				print("  -> PASSED: " .. test.Name)
			end
		end)

		coroutine.resume(testCoroutine)
		print("-------------------------------------")
	end
end

print("--- All test runs finished. ---")

if not overallSuccess then
    -- This is useful for CI/CD environments
    -- game:Shutdown()
end

