-- DirectTest.luau
-- A direct test script that doesn't rely on being in ServerScriptService

-- Function to safely get environment information
local function getEnvironmentInfo()
    local info = {}
    
    -- Basic Lua environment
    info.luaVersion = _VERSION
    
    -- Check for Roblox globals
    info.robuxGlobals = {
        game = type(game),
        workspace = type(workspace),
        script = type(script),
        require = type(require),
        print = type(print),
        warn = type(warn),
        error = type(error)
    }
    
    -- Check for common services
    info.services = {}
    local serviceNames = {"ServerScriptService", "ReplicatedStorage", "Workspace"}
    
    for _, name in ipairs(serviceNames) do
        local success, service = pcall(function()
            return game:GetService(name)
        end)
        info.services[name] = success and "✅ Available" or "❌ Not available"
    end
    
    -- Check for module loading
    info.moduleLoading = {}
    if script.Parent and script.Parent:FindFirstChild("systems") then
        local systems = script.Parent.systems:GetChildren()
        for _, module in ipairs(systems) do
            if module:IsA("ModuleScript") then
                local success, result = pcall(require, module)
                info.moduleLoading[module.Name] = success and "✅ Loaded" or "❌ Failed: " .. tostring(result)
            end
        end
    else
        info.moduleLoading = "Systems folder not found or not accessible"
    end
    
    -- Check for file system access
    info.fileSystem = {
        readfile = type(readfile) == "function" and "✅ Available" or "❌ Not available",
        writefile = type(writefile) == "function" and "✅ Available" or "❌ Not available"
    }
    
    -- Check for HTTP service
    info.httpService = "Not tested"
    local success, http = pcall(function() return game:GetService("HttpService") end)
    if success then
        info.httpService = "Available"
        -- Try a simple JSON encode
        local jsonSuccess, jsonResult = pcall(function()
            return http:JSONEncode({test = true})
        end)
        info.httpService = jsonSuccess and "✅ Available (JSON encoding works)" or "⚠️ Available but JSON encoding failed"
    end
    
    return info
end

-- Main function
local function main()
    print("=== Starting Direct Environment Test ===\n")
    
    -- Get environment info
    local success, info = pcall(getEnvironmentInfo)
    if not success then
        warn("❌ Failed to get environment info: " .. tostring(info))
        return false, "Failed to get environment info: " .. tostring(info)
    end
    
    -- Print results
    print("🔹 Lua Version: " .. tostring(info.luaVersion))
    print("\n🔹 Roblox Globals:")
    for name, typeInfo in pairs(info.robuxGlobals) do
        print("  - " .. name .. ": " .. tostring(typeInfo))
    end
    
    print("\n🔹 Services:")
    for name, status in pairs(info.services) do
        print("  - " .. name .. ": " .. tostring(status))
    end
    
    print("\n🔹 File System Access:")
    for name, status in pairs(info.fileSystem) do
        print("  - " .. name .. ": " .. tostring(status))
    end
    
    print("\n🔹 HTTP Service: " .. tostring(info.httpService))
    
    print("\n🔹 Module Loading:")
    if type(info.moduleLoading) == "table" then
        for name, status in pairs(info.moduleLoading) do
            print("  - " .. name .. ": " .. tostring(status))
        end
    else
        print("  " .. tostring(info.moduleLoading))
    end
    
    print("\n=== Environment Test Complete ===")
    return true, info
end

-- Run the test
local success, result = pcall(main)
if not success then
    warn("❌ Test failed: " .. tostring(result))
    return false, "Test failed: " .. tostring(result)
end

return result
