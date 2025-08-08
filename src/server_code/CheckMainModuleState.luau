--!strict
-- Script to check the current state of MainModule in the game

print("=== Checking MainModule State ===\n")

-- 1. Get ServerScriptService
local success, sss = pcall(function()
    return game:GetService("ServerScriptService")
end)

if not success then
    warn("❌ Failed to get ServerScriptService:", sss)
    return
end

print("✅ Successfully got ServerScriptService")

-- 2. List all children of ServerScriptService
print("\n=== ServerScriptService Children ===")
success, result = pcall(function()
    local children = {}
    for _, child in ipairs(sss:GetChildren()) do
        table.insert(children, {
            name = child.Name,
            className = child.ClassName,
            isModule = child:IsA("ModuleScript"),
            isScript = child:IsA("Script"),
            sourceLength = child:IsA("ModuleScript") and #child.Source or 0
        })
    end
    table.sort(children, function(a, b) return a.name < b.name end)
    return children
end)

if success and type(result) == "table" then
    print(string.format("Found %d children in ServerScriptService:", #result))
    for _, child in ipairs(result) do
        local typeStr = child.isModule and "ModuleScript" or (child.isScript and "Script" or child.className)
        print(string.format("  - %s (%s, %d chars)", child.name, typeStr, child.sourceLength))
    end
else
    warn("❌ Failed to list children:", result)
end

-- 3. Check for MainModule
print("\n=== Looking for MainModule ===")
success, result = pcall(function()
    local mainModule = sss:FindFirstChild("MainModule")
    if not mainModule then return nil end
    
    return {
        name = mainModule.Name,
        className = mainModule.ClassName,
        isModuleScript = mainModule:IsA("ModuleScript"),
        sourceLength = mainModule:IsA("ModuleScript") and #mainModule.Source or 0,
        sourcePreview = mainModule:IsA("ModuleScript") and 
            string.sub(mainModule.Source, 1, 100) .. (#mainModule.Source > 100 and "..." or "") or ""
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

-- 4. Try to require MainModule if it's a ModuleScript
if result.isModuleScript then
    print("\n=== Attempting to require MainModule ===")
    success, result = pcall(function()
        local mainModule = sss:FindFirstChild("MainModule")
        if not mainModule then return nil, "MainModule not found" end
        
        local success, module = pcall(require, mainModule)
        if not success then return nil, module end
        
        return {
            type = type(module),
            hasInit = type(module.init) == "function",
            isInitialized = type(module.isInitialized) == "function" and module:isInitialized() or nil,
            methods = {}
        }
    end)
    
    if not success or not result then
        warn("❌ Failed to require MainModule:", result)
    else
        print("✅ Successfully required MainModule")
        print("   Type: " .. result.type)
        print("   Has init method: " .. tostring(result.hasInit))
        if result.isInitialized ~= nil then
            print("   isInitialized: " .. tostring(result.isInitialized))
        end
    end
end

print("\n=== MainModule State Check Complete ===\n")
