--!strict
-- MinimalTest.luau
-- A minimal test script to verify basic script execution in the MCP environment

print("=== Starting Minimal Test ===")
print("If you can see this, basic script execution is working!")
print("_VERSION: " .. tostring(_VERSION))
print("typeof(game): " .. tostring(type(game)))
print("typeof(script): " .. tostring(type(script)))
print("=== Test Complete ===")

return true
