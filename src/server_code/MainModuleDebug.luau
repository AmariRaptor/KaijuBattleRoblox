--!strict
-- MainModuleDebug.luau
-- Comprehensive debugging script for MainModule initialization

local function logSuccess(message: string)
    print("✅ " .. message)
end

local function logWarning(message: string)
    warn("⚠️ " .. message)
end

local function logError(message: string)
    warn("❌ " .. message)
end

print("\n=== MainModule Debugging Tool ===\n")

-- 1. Environment Check
print("=== Environment Check ===")
logSuccess("Script is running in " .. (game:GetService("RunService"):IsServer() and "Server" or "Client") .. " context")
logSuccess("Game ID: " .. tostring(game.GameId))
logSuccess("Place ID: " .. tostring(game.PlaceId))
logSuccess("Server Time: " .. os.date("%c", os.time()))

-- 2. Locate MainModule
print("\n=== Locating MainModule ===")
local sss = game:GetService("ServerScriptService")
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

-- 3. Verify MainModule Type
if not mainModule:IsA("ModuleScript") then
    logError("MainModule is not a ModuleScript (it's a " .. mainModule.ClassName .. ")")
    return
end

logSuccess("MainModule is a valid ModuleScript")

-- 4. Analyze Source Code
local source = mainModule.Source
print("\n=== Source Code Analysis ===")
print("   Source length: " .. #source .. " characters")
print("   First 100 characters: " .. string.sub(source, 1, 100) .. "...")

-- Look for common patterns
local patterns = {
    {pattern = "local%s+[%w_]+%s*=%s*%{", description = "Table initialization"},
    {pattern = "function%s+[%w_]+%s*%(", description = "Function definitions"},
    {pattern = "require%(", description = "Require statements"},
    {pattern = "init%s*=", description = "Init method definition"},
    {pattern = "isInitialized%s*=", description = "isInitialized method definition"},
    {pattern = "getSystem%s*=", description = "getSystem method definition"},
    {pattern = "getInitializedSystems%s*=", description = "getInitializedSystems method definition"}
}

print("\n=== Common Patterns ===")
for _, item in ipairs(patterns) do
    local found = string.find(source, item.pattern)
    print(string.format("   %-30s %s", item.description .. ":", found and "✅ Found" or "❌ Not found"))
end

-- 5. Attempt to Require MainModule
print("\n=== Require MainModule ===")
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

-- 6. Check for Required Methods
print("\n=== Method Verification ===")
local requiredMethods = {
    {name = "init", required = true},
    {name = "isInitialized", required = true},
    {name = "getSystem", required = true},
    {name = "getInitializedSystems", required = true}
}

local allMethodsFound = true
for _, method in ipairs(requiredMethods) do
    local exists = type(module[method.name]) == "function"
    print(string.format("   %-20s %s", method.name .. ":", exists and "✅ Found" or "❌ Missing"))
    if not exists and method.required then
        allMethodsFound = false
    end
end

if allMethodsFound then
    logSuccess("All required methods found")
else
    logError("Some required methods are missing")
end

-- 7. Check Initialization State
print("\n=== Initialization State ===")
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

-- 8. Attempt Initialization if Needed
if not isInitialized then
    print("\n=== Initialization Attempt ===")
    local initSuccess, initResult = pcall(function()
        return module:init()
    end)
    
    if not initSuccess then
        logError("MainModule:init() failed:")
        warn(initResult)
    else
        logSuccess("MainModule:init() completed successfully")
        
        -- Re-check initialization state
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

-- 9. Check Initialized Systems
print("\n=== Initialized Systems ===")
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

-- 10. Test System Retrieval
print("\n=== System Retrieval Test ===")
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
        logSuccess("getSystem(\"" .. testSystemName .. "\"): Success")
        print("   System type: " .. type(system))
    end
end

-- 11. Final Status
print("\n=== Debugging Complete ===")
print("\n=== Summary ===")
print("1. Environment: " .. (game:GetService("RunService"):IsServer() and "Server" or "Client"))
print("2. MainModule: " .. (mainModule and "✅ Found" or "❌ Missing"))
print("3. Required Methods: " .. (allMethodsFound and "✅ All found" or "❌ Some missing"))
print("4. Initialized: " .. (isInitialized and "✅ Yes" or "❌ No"))
print("5. Systems Found: " .. (next(systems) and #systems or "0"))
print("\n=== End of Debug Report ===\n")
