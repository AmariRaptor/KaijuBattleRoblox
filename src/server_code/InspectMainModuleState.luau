--!strict
-- Script to inspect the MainModule's state and initialization process

print("=== Inspecting MainModule State ===\n")

-- Function to safely get a property from a table
local function safeGet(t: any, key: string): (boolean, any)
    local success, value = pcall(function()
        return t[key]
    end)
    return success, value
end

-- 1. Get ServerScriptService
local sss = game:GetService("ServerScriptService")

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

-- 4. Print source code info
local source = mainModule.Source
print("\n=== MainModule Source Info ===")
print("   Source length: " .. #source .. " characters")
print("   First 200 characters: " .. string.sub(source, 1, 200) .. (string.len(source) > 200 and "..." or ""))

-- 5. Try to require the module
print("\n=== Attempting to require MainModule ===")
local success, module = pcall(require, mainModule)

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
    local exists, value = safeGet(module, method)
    if not exists or type(value) ~= "function" then
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
local initSuccess, initResult = pcall(function()
    return module:isInitialized()
end)

if not initSuccess then
    warn("❌ Error calling isInitialized():")
    warn(initResult)
else
    isInitialized = initResult
    print("   isInitialized(): " .. tostring(isInitialized))
end

-- 8. If not initialized, try to initialize
if not isInitialized then
    print("\n=== Attempting to Initialize MainModule ===")
    local initSuccess, initResult = pcall(module.init, module)
    
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

-- 10. Test getting a system
print("\n=== Testing getSystem() ===")
local testSystemName = next(systems) or "TestSystem1"
local getSystemSuccess, system = pcall(function()
    return module:getSystem(testSystemName)
end)

if not getSystemSuccess then
    warn("❌ Error calling getSystem(\"" .. testSystemName .. "\"):")
    warn(system)
else
    if system == nil then
        print("   getSystem(\"" .. testSystemName .. "\"): nil (system not found)")
    else
        print("   getSystem(\"" .. testSystemName .. "\"): Found system")
        print("   System type: " .. type(system))
    end
end

print("\n=== MainModule Inspection Complete ===\n")
