-- GlobalCheck.luau
-- A script to check available globals in the MCP environment

-- Function to safely get global variables
local function getGlobals()
    local globals = {}
    
    -- Try to get _G
    if type(_G) == "table" then
        for k, v in pairs(_G) do
            if type(k) == "string" then
                globals[k] = type(v)
            end
        end
    end
    
    -- Try to get debug table
    if type(debug) == "table" and type(debug.getregistry) == "function" then
        globals["debug.getregistry"] = true
    end
    
    return globals
end

-- Main function
local function main()
    local globals = getGlobals()
    
    -- Sort keys for consistent output
    local sortedKeys = {}
    for k in pairs(globals) do
        table.insert(sortedKeys, k)
    end
    table.sort(sortedKeys)
    
    -- Print results
    print("=== Available Globals ===")
    for _, k in ipairs(sortedKeys) do
        print(string.format("%-20s: %s", k, tostring(globals[k])))
    end
    print("=======================")
    
    return true, "Global check completed"
end

-- Run the main function
local success, result = pcall(main)
if not success then
    warn("❌ Error: " .. tostring(result))
    return false, "Error in GlobalCheck: " .. tostring(result)
end

return result
