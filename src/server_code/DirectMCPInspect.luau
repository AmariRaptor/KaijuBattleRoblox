--!strict
-- Script to directly inspect ServerScriptService and MainModule using MCP

print("=== Direct MCP Inspection ===\n")

-- 1. Check ServerScriptService contents
print("1. Listing ServerScriptService contents...")
local success, result = pcall(function()
    local sss = game:GetService("ServerScriptService")
    local children = {}
    for _, child in ipairs(sss:GetChildren()) do
        table.insert(children, {
            name = child.Name,
            className = child.ClassName,
            isModule = child:IsA("ModuleScript"),
            isScript = child:IsA("Script")
        })
    end
    return children
end)

if success and type(result) == "table" then
    print("✅ Found " .. #result .. " children in ServerScriptService:")
    for _, child in ipairs(result) do
        local typeStr = child.isModule and "ModuleScript" or (child.isScript and "Script" or child.className)
        print(string.format("   - %s (%s)", child.name, typeStr))
    end
else
    warn("❌ Failed to list ServerScriptService contents:", result)
end

-- 2. Look for MainModule
print("\n2. Looking for MainModule...")
success, result = pcall(function()
    local mainModule = game:GetService("ServerScriptService"):FindFirstChild("MainModule")
    if not mainModule then return nil, "MainModule not found" end
    
    return {
        name = mainModule.Name,
        className = mainModule.ClassName,
        isModuleScript = mainModule:IsA("ModuleScript"),
        sourceLength = #mainModule.Source,
        sourcePreview = string.sub(mainModule.Source, 1, 200)
    }
end)

if not success or not result then
    warn("❌ MainModule not found or error accessing it:", result)
    return
end

print("✅ Found MainModule:")
print("   Class: " .. result.className)
print("   Is ModuleScript: " .. tostring(result.isModuleScript))
print("   Source length: " .. result.sourceLength .. " characters")
print("   Source preview: " .. result.sourcePreview)

-- 3. Try to require MainModule if it's a ModuleScript
if result.isModuleScript then
    print("\n3. Attempting to require MainModule...")
    success, result = pcall(function()
        local mainModule = game:GetService("ServerScriptService"):FindFirstChild("MainModule")
        if not mainModule then return nil, "MainModule not found" end
        
        local success, module = pcall(require, mainModule)
        if not success then return nil, module end
        
        return {
            type = type(module),
            hasInit = type(module.init) == "function",
            methods = {}
        }
    end)
    
    if not success or not result then
        warn("❌ Failed to require MainModule:", result)
    else
        print("✅ Successfully required MainModule")
        print("   Type: " .. result.type)
        print("   Has init method: " .. tostring(result.hasInit))
    end
end

print("\n=== Direct MCP Inspection Complete ===\n")
