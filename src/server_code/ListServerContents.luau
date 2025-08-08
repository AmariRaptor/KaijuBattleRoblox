-- ListServerContents.luau
-- A simple script to list contents of ServerScriptService

local function listContents()
    print("=== Contents of ServerScriptService ===")
    
    -- Try to get ServerScriptService
    local success, serverScriptService = pcall(game.GetService, game, "ServerScriptService")
    if not success or not serverScriptService then
        print("❌ Could not access ServerScriptService")
        return false
    end
    
    -- List all children
    local children = serverScriptService:GetChildren()
    if #children == 0 then
        print("ℹ️ ServerScriptService is empty")
        return true
    end
    
    -- Print info about each child
    for _, child in ipairs(children) do
        print(string.format("- %s (%s)", child.Name, child.ClassName))
    end
    
    print("====================================")
    return true
end

-- Run the function
local success, result = pcall(listContents)
if not success then
    warn("❌ Error: " .. tostring(result))
    return false, "Error listing server contents: " .. tostring(result)
end

return result
