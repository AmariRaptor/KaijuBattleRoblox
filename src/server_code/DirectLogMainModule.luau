--!strict
-- Script to directly log MainModule source and state using MCP run_code

print("=== Direct Log of MainModule ===\n")

-- Function to execute code in the Roblox environment
local function runInStudio(code: string): (boolean, any)
    -- This function will be replaced by MCP's run_code
    return pcall(loadstring(code))
end

-- 1. Get ServerScriptService
print("1. Getting ServerScriptService...")
local success, sss = runInStudio([[return game:GetService("ServerScriptService")]])

if not success then
    warn("❌ Failed to get ServerScriptService:", sss)
    return
end

print("✅ Successfully got ServerScriptService")

-- 2. Find MainModule
print("\n2. Looking for MainModule...")
success, result = runInStudio([[
    local sss = game:GetService("ServerScriptService")
    local mainModule = sss:FindFirstChild("MainModule")
    if not mainModule then return nil end
    
    return {
        name = mainModule.Name,
        className = mainModule.ClassName,
        isModuleScript = mainModule:IsA("ModuleScript"),
        sourceLength = #mainModule.Source,
        sourcePreview = string.sub(mainModule.Source, 1, 500)
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

-- 3. Try to require MainModule if it's a ModuleScript
if result.isModuleScript then
    print("\n3. Attempting to require MainModule...")
    success, result = runInStudio([[
        local mainModule = game:GetService("ServerScriptService"):FindFirstChild("MainModule")
        if not mainModule then return nil, "MainModule not found" end
        
        local success, module = pcall(require, mainModule)
        if not success then return nil, module end
        
        -- Get all methods
        local methods = {}
        for k, v in pairs(module) do
            if type(v) == "function" then
                table.insert(methods, k)
            end
        end
        table.sort(methods)
        
        -- Check initialization state
        local isInitialized = nil
        if type(module.isInitialized) == "function" then
            isInitialized = module:isInitialized()
        end
        
        -- Initialize if not already initialized
        local initResult = nil
        if not isInitialized and type(module.init) == "function" then
            local initSuccess, result = pcall(module.init, module)
            if initSuccess then
                initResult = "success"
                isInitialized = module:isInitialized()
            else
                initResult = "failed: " .. tostring(result)
            end
        end
        
        -- Get initialized systems
        local systems = {}
        if type(module.getInitializedSystems) == "function" then
            local success, result = pcall(module.getInitializedSystems, module)
            if success and type(result) == "table" then
                for k, _ in pairs(result) do
                    table.insert(systems, tostring(k))
                end
                table.sort(systems)
            end
        end
        
        return {
            type = type(module),
            methods = methods,
            isInitialized = isInitialized,
            hasInit = type(module.init) == "function",
            initResult = initResult,
            systems = systems
        }
    ]])
    
    if not success or not result then
        warn("❌ Failed to require MainModule:", result)
    else
        print("✅ Successfully required MainModule")
        print("   Type: " .. result.type)
        print("   Methods: " .. table.concat(result.methods, ", "))
        print("   Has init method: " .. tostring(result.hasInit))
        print("   isInitialized: " .. tostring(result.isInitialized))
        
        if result.initResult then
            print("   Init result: " .. result.initResult)
            print("   isInitialized after init: " .. tostring(result.isInitialized))
        end
        
        if #result.systems > 0 then
            print("   Initialized systems: " .. table.concat(result.systems, ", "))
        else
            print("   No systems initialized")
        end
    end
end

print("\n=== Direct Log Complete ===\n")
