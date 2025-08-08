--!strict
-- Script to examine MainModule source code and initialization

print("=== Examining MainModule Source ===\n")

-- 1. Get ServerScriptService
local sss = game:GetService("ServerScriptService")
print("✅ ServerScriptService obtained")

-- 2. Find MainModule
local mainModule = sss:FindFirstChild("MainModule")
if not mainModule then
    warn("❌ MainModule not found in ServerScriptService")
    print("   Available children in ServerScriptService:")
    for _, child in ipairs(sss:GetChildren()) do
        print("   - " .. child:GetFullName() .. " (" .. child.ClassName .. ")")
    end
    return
end

print("✅ Found MainModule: " .. mainModule:GetFullName())
print("   Class: " .. mainModule.ClassName)

-- 3. Check if it's a ModuleScript
if not mainModule:IsA("ModuleScript") then
    warn("❌ MainModule is not a ModuleScript (it's a " .. mainModule.ClassName .. ")")
    return
end

print("✅ MainModule is a ModuleScript")

-- 4. Print source code
local source = mainModule.Source
print("\n=== MainModule Source Code ===")
print("   Source length: " .. #source .. " characters")
print("   First 500 characters:")
print("   " .. string.rep("-", 78))
print(source:sub(1, 500) .. (#source > 500 and "..." or ""))
print("   " .. string.rep("-", 78))

-- 5. Try to require the module
print("\n=== Attempting to require MainModule ===")
local success, module = pcall(function()
    return require(mainModule)
end)

if not success then
    warn("❌ Failed to require MainModule:")
    warn(module)
    return
end

print("✅ Successfully required MainModule")
print("   Module type: " .. type(module))

-- 6. Check for required methods
print("\n=== Checking for Required Methods ===")
local requiredMethods = {"init", "isInitialized", "getSystem", "getInitializedSystems"}
local allMethodsFound = true

for _, method in ipairs(requiredMethods) do
    if type(module[method]) ~= "function" then
        warn("❌ Missing required method: " .. method)
        allMethodsFound = false
    else
        print("✅ Found method: " .. method)
    end
end

if allMethodsFound then
    print("✅ All required methods found")
end

-- 7. Check initialization state
print("\n=== Checking Initialization State ===")
local isInitialized = false
local initCheckSuccess, initCheckResult = pcall(function()
    return module:isInitialized()
end)

if not initCheckSuccess then
    warn("❌ Error calling isInitialized():")
    warn(initCheckResult)
else
    isInitialized = initCheckResult
    print("   isInitialized(): " .. tostring(isInitialized))
end

-- 8. If not initialized, try to initialize
if not isInitialized then
    print("\n=== Attempting to Initialize MainModule ===")
    local initSuccess, initResult = pcall(function()
        return module:init()
    end)
    
    if not initSuccess then
        warn("❌ MainModule:init() failed:")
        warn(initResult)
    else
        print("✅ MainModule:init() completed successfully")
        
        -- Check initialization state again
        local checkSuccess, checkResult = pcall(function()
            return module:isInitialized()
        end)
        
        if checkSuccess then
            print("   isInitialized() after init: " .. tostring(checkResult))
        else
            warn("   ❌ Error checking isInitialized() after init:")
            warn("   " .. tostring(checkResult))
        end
    end
end

-- 9. Check initialized systems
print("\n=== Checking Initialized Systems ===")
local systems = {}
local getSystemsSuccess, getSystemsResult = pcall(function()
    return module:getInitializedSystems()
end)

if not getSystemsSuccess then
    warn("❌ Error calling getInitializedSystems():")
    warn(getSystemsResult)
else
    if type(getSystemsResult) ~= "table" then
        warn("❌ getInitializedSystems() did not return a table, got: " .. type(getSystemsResult))
    else
        systems = getSystemsResult
        local systemCount = 0
        for _ in pairs(systems) do systemCount += 1 end
        
        print("   Found " .. systemCount .. " initialized systems")
        if systemCount > 0 then
            print("   Systems:")
            for name, _ in pairs(systems) do
                print("   - " .. tostring(name))
            end
        end
    end
end

print("\n=== Source Examination Complete ===\n")
