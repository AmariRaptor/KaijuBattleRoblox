-- SimpleTest.lua
-- A minimal test to verify the MCP environment

print("=== Starting SimpleTest ===")

-- Basic test function
local function runSimpleTest()
    print("Running simple test...")
    
    -- Test basic Lua functionality
    local testValue = 42
    if testValue ~= 42 then
        return false, "Basic math test failed"
    end
    
    -- Test table operations
    local testTable = {name = "test", value = 123}
    if testTable.name ~= "test" or testTable.value ~= 123 then
        return false, "Table test failed"
    end
    
    print("✅ All simple tests passed!")
    return true, "Success!"
end

-- Run the test
local success, message = pcall(runSimpleTest)
if not success or (type(message) ~= "string" or not message:find("Success")) then
    local errorMsg = "❌ Test failed: " .. tostring(message or "Unknown error")
    print(errorMsg)
    return false, errorMsg
end

print("✅ SimpleTest completed successfully!")
return true
