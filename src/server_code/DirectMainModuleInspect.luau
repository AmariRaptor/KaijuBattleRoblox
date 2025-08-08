--!strict
-- DirectMainModuleInspect.luau
-- This script will be run directly in Roblox Studio to inspect the MainModule

local function logSuccess(message: string)
    print("✅ " .. message)
end

local function logWarning(message: string)
    warn("⚠️ " .. message)
end

local function logError(message: string)
    warn("❌ " .. message)
end

print("\n=== Direct MainModule Inspection ===\n")

-- 1. Get ServerScriptService
local sss = game:GetService("ServerScriptService")
logSuccess("Obtained ServerScriptService")

-- 2. Find MainModule
local mainModule = sss:FindFirstChild("MainModule")
if not mainModule then
    logError("MainModule not found in ServerScriptService")
    logWarning("Available children in ServerScriptService:")
    for _, child in ipairs(sss:GetChildren()) do
        print("   - " .. child:GetFullName() .. " (" .. child.ClassName .. ")")
    end
    return
end

logSuccess("Found MainModule: " .. mainModule:GetFullName())
print("   Class: " .. mainModule.ClassName)

-- 3. Check if it's a ModuleScript
if not mainModule:IsA("ModuleScript") then
    logError("MainModule is not a ModuleScript (it's a " .. mainModule.ClassName .. ")")
    return
end

logSuccess("MainModule is a ModuleScript")

-- 4. Print source code info
local source = mainModule.Source
print("\n=== MainModule Source Info ===")
print("   Source length: " .. #source .. " characters")
print("   First 50 characters: " .. string.sub(source, 1, 50) .. "...")

-- 5. Try to require the module
print("\n=== Attempting to require MainModule ===")
local success, module = pcall(function()
    return require(mainModule)
end)

if not success then
    logError("Failed to require MainModule:")
    warn(module)
    return
end

logSuccess("Successfully required MainModule")
print("   Module type: " .. type(module))

-- 6. Check for required methods
print("\n=== Checking for Required Methods ===")
local requiredMethods = {
    init = "function",
    isInitialized = "function",
    getSystem = "function",
    getInitializedSystems = "function"
}

local allMethodsFound = true
for method, expectedType in pairs(requiredMethods) do
    local actualType = type(module[method])
    if actualType ~= expectedType then
        logError(string.format("Method '%s' has type '%s' (expected '%s')", method, actualType, expectedType))
        allMethodsFound = false
    else
        logSuccess(string.format("Method '%s' is present with correct type '%s'", method, expectedType))
    end
end

if allMethodsFound then
    logSuccess("All required methods found with correct types")
end

-- 7. Check initialization state
print("\n=== Checking Initialization State ===")
local isInitialized = false
local initCheckSuccess, initCheckResult = pcall(function()
    return module:isInitialized()
end)

if not initCheckSuccess then
    logError("Error calling isInitialized():")
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
        logError("MainModule:init() failed:")
        warn(initResult)
    else
        logSuccess("MainModule:init() completed successfully")
        
        -- Check initialization state again
        local checkSuccess, checkResult = pcall(function()
            return module:isInitialized()
        end)
        
        if checkSuccess then
            print("   isInitialized() after init: " .. tostring(checkResult))
        else
            logError("Error checking isInitialized() after init:")
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
    logError("Error calling getInitializedSystems():")
    warn(getSystemsResult)
else
    if type(getSystemsResult) ~= "table" then
        logError("getInitializedSystems() did not return a table, got: " .. type(getSystemsResult))
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
    logError("Error calling getSystem(\"" .. testSystemName .. "\"):")
    warn(system)
else
    if system == nil then
        print("   getSystem(\"" .. testSystemName .. "\"): nil (system not found)")
    else
        logSuccess("getSystem(\"" .. testSystemName .. "\"): Found system")
        print("   System type: " .. type(system))
    end
end

print("\n=== Direct Inspection Complete ===\n")
