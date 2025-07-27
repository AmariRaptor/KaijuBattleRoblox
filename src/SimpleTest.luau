--!strict
-- SimpleTest.luau
-- A minimal test to verify the MCP environment with strict Luau types

print("=== Starting SimpleTest ===")

-- Define types
type TestTable = {
    name: string,
    value: number
}

type TestResult = {
    success: boolean,
    message: string
}

-- Basic test function
local function runSimpleTest(): (boolean, string)
    print("Running simple test...")
    
    -- Test basic Lua functionality
    local testValue: number = 42
    if testValue ~= 42 then
        return false, "Basic math test failed"
    end
    
    -- Test table operations with type annotation
    local testTable: TestTable = {name = "test", value = 123}
    if testTable.name ~= "test" or testTable.value ~= 123 then
        return false, "Table test failed"
    end
    
    -- Test string operations
    local testString: string = "Hello, world!"
    if not testString:find("world") then
        return false, "String test failed"
    end
    
    print("✅ All simple tests passed!")
    return true, "Success!"
end

-- Run the test and return structured result
local success, message = pcall(runSimpleTest)
if not success or (type(message) ~= "string" or not message:find("Success")) then
    local errorMsg = "❌ Test failed: " .. tostring(message or "Unknown error")
    print(errorMsg)
    return {success = false, message = errorMsg}
end

print("✅ SimpleTest completed successfully!")
return {success = true, message = "All tests passed"}
