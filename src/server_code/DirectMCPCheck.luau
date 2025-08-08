--!strict
-- Script to directly check MainModule using MCP's run_code

print("=== Direct MCP Check of MainModule ===\n")

-- Function to run code in Roblox Studio context
local function runInStudio(code: string): (boolean, any)
    -- This function will be replaced by MCP's run_code
    return pcall(loadstring(code))
end

-- 1. Check if we can access ServerScriptService
local success, sss = runInStudio([[return game:GetService("ServerScriptService")]])

if not success then
    warn("❌ Failed to get ServerScriptService:", sss)
    return
end

print("✅ Successfully got ServerScriptService")

-- 2. List all children of ServerScriptService
print("\n=== ServerScriptService Children ===")
success, result = runInStudio([[
    local children = {}
    for _, child in ipairs(game:GetService("ServerScriptService"):GetChildren()) do
        table.insert(children, child.Name .. " (" .. child.ClassName .. ")")
    end
    table.sort(children)
    return children
]])

if success and type(result) == "table" then
    for _, childInfo in ipairs(result) do
        print("  - " .. childInfo)
    end
else
    warn("❌ Failed to list children:", result)
end

-- 3. Check for MainModule
print("\n=== Checking for MainModule ===")
success, result = runInStudio([[
    local mainModule = game:GetService("ServerScriptService"):FindFirstChild("MainModule")
    if not mainModule then return nil end
    return {
        name = mainModule.Name,
        className = mainModule.ClassName,
        isModuleScript = mainModule:IsA("ModuleScript"),
        sourceLength = #mainModule.Source,
        sourcePreview = string.sub(mainModule.Source, 1, 200)
    }
]])

if not success or not result then
    warn("❌ MainModule not found or error accessing it:", result)
    return
end

print("✅ Found MainModule:")
print("   Class: " .. result.className)
print("   Is ModuleScript: " .. tostring(result.isModuleScript))
print("   Source length: " .. result.sourceLength .. " characters")
print("   Source preview: " .. result.sourcePreview)

-- 4. Try to require MainModule
if not result.isModuleScript then
    warn("❌ MainModule is not a ModuleScript, cannot require it")
    return
end

print("\n=== Attempting to require MainModule ===")
success, result = runInStudio([[
    local mainModule = game:GetService("ServerScriptService"):FindFirstChild("MainModule")
    if not mainModule then return nil, "MainModule not found" end
    
    local success, module = pcall(require, mainModule)
    if not success then return nil, module end
    
    local methods = {}
    for k, v in pairs(module) do
        if type(v) == "function" then
            table.insert(methods, k)
        end
    end
    table.sort(methods)
    
    local initStatus = nil
    if type(module.isInitialized) == "function" then
        initStatus = module:isInitialized()
    end
    
    return {
        type = type(module),
        methods = methods,
        isInitialized = initStatus,
        hasInit = type(module.init) == "function"
    }
]])

if not success then
    warn("❌ Error requiring MainModule:", result)
    return
end

if not result then
    warn("❌ Failed to require MainModule: Unknown error")
    return
end

print("✅ Successfully required MainModule")
print("   Type: " .. result.type)
print("   Methods: " .. table.concat(result.methods, ", "))
print("   Has init method: " .. tostring(result.hasInit))
print("   isInitialized: " .. tostring(result.isInitialized))

-- 5. Try to initialize if possible
if result.hasInit and result.isInitialized ~= nil and not result.isInitialized then
    print("\n=== Attempting to initialize MainModule ===")
    success, result = runInStudio([[
        local mainModule = game:GetService("ServerScriptService"):FindFirstChild("MainModule")
        if not mainModule then return nil, "MainModule not found" end
        
        local success, module = pcall(require, mainModule)
        if not success then return nil, "Require failed: " .. tostring(module) end
        
        if type(module.init) ~= "function" then
            return nil, "No init function found"
        end
        
        local success, result = pcall(module.init, module)
        if not success then return nil, "Init failed: " .. tostring(result) end
        
        return {
            success = true,
            isInitialized = type(module.isInitialized) == "function" and module:isInitialized() or nil,
            initResult = result
        }
    ]])
    
    if not success or not result then
        warn("❌ Error during initialization:", result)
    else
        print("✅ Initialization result:")
        print("   Success: " .. tostring(result.success))
        if result.isInitialized ~= nil then
            print("   isInitialized: " .. tostring(result.isInitialized))
        end
        if result.initResult ~= nil then
            print("   init() returned: " .. tostring(result.initResult))
        end
    end
end

print("\n=== Direct MCP Check Complete ===\n")
