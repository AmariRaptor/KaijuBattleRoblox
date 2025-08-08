--!strict
-- Script to directly inspect MainModule using MCP

print("=== Inspecting MainModule with MCP ===\n")

-- Function to get MainModule info
local function getMainModuleInfo()
    -- Get ServerScriptService
    local sss = game:GetService("ServerScriptService")
    
    -- Find MainModule
    local mainModule = sss:FindFirstChild("MainModule")
    if not mainModule then
        return "❌ MainModule not found in ServerScriptService"
    end
    
    -- Check if it's a ModuleScript
    if not mainModule:IsA("ModuleScript") then
        return string.format("❌ MainModule is not a ModuleScript (it's a %s)", mainModule.ClassName)
    end
    
    -- Get source preview
    local source = mainModule.Source
    local sourcePreview = string.sub(source, 1, 200) .. (string.len(source) > 200 and "..." or "")
    
    -- Try to require
    local success, result = pcall(require, mainModule)
    local requireResult
    if not success then
        requireResult = "❌ Require failed: " .. tostring(result)
    else
        requireResult = "✅ Require succeeded. Type: " .. type(result)
    end
    
    -- Format the result
    local info = {
        "=== MainModule Info ===",
        "Name: " .. mainModule.Name,
        "Class: " .. mainModule.ClassName,
        "Source length: " .. string.len(source) .. " characters",
        "Source preview: " .. sourcePreview,
        "",
        requireResult
    }
    
    -- If require succeeded, check for methods
    if success then
        table.insert(info, "\n=== Methods ===")
        local methods = {}
        for k, v in pairs(result) do
            if type(v) == "function" then
                table.insert(methods, "- " .. k)
            end
        end
        
        if #methods > 0 then
            table.sort(methods)
            for _, method in ipairs(methods) do
                table.insert(info, method)
            end
        else
            table.insert(info, "No methods found")
        end
        
        -- Check initialization
        if type(result.isInitialized) == "function" then
            local initStatus = result:isInitialized()
            table.insert(info, "\n=== Initialization Status ===")
            table.insert(info, "isInitialized(): " .. tostring(initStatus))
            
            -- Try to initialize if not already initialized
            if not initStatus and type(result.init) == "function" then
                local initSuccess, initResult = pcall(result.init, result)
                table.insert(info, "\n=== Initialization Attempt ===")
                if initSuccess then
                    table.insert(info, "✅ init() completed successfully")
                    table.insert(info, "New isInitialized(): " .. tostring(result:isInitialized()))
                else
                    table.insert(info, "❌ init() failed: " .. tostring(initResult))
                end
            end
        end
    end
    
    return table.concat(info, "\n")
end

-- Run the inspection
local success, result = pcall(getMainModuleInfo)
if not success then
    warn("❌ Error during inspection:")
    warn(result)
else
    print(result)
end

print("\n=== Inspection Complete ===\n")
