-- BasicExecutionTest.luau
-- A minimal test to verify basic script execution in the MCP environment

-- Simple output
debug.output("=== Starting Basic Execution Test ===")
debug.output("If you can see this, basic script execution is working!")

debug.output("\nEnvironment Information:")
debug.output("_VERSION: " .. tostring(_VERSION))
debug.output("Current time: " .. tostring(os.time()))

debug.output("\n=== Test Complete ===")

-- Return success
return true, "Basic execution test completed successfully"
