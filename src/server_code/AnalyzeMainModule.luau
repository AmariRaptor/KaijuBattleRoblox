--!strict
-- Script to analyze MainModule initialization issues

print("=== Analyzing MainModule Initialization ===\n")

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

-- 4. Print source code info
local source = mainModule.Source
print("\n=== MainModule Source Analysis ===")
print("   Source length: " .. #source .. " characters")

-- Check for common issues in the source code
local commonIssues = {
    {pattern = "local%s+[%w_]+%s*=%s*%{", description = "Table initialization"},
    {pattern = "function%s+[%w_]+%s*%(", description = "Function definitions"},
    {pattern = "require%(", description = "Require statements"},
    {pattern = "init%s*%=", description = "Init method definition"},
    {pattern = "isInitialized%s*%=", description = "isInitialized method definition"},
    {pattern = "getSystem%s*%=", description = "getSystem method definition"},
    {pattern = "getInitializedSystems%s*%=", description = "getInitializedSystems method definition"}
}

print("\n=== Checking for Common Patterns ===")
for _, issue in ipairs(commonIssues) do
    local found = string.find(source, issue.pattern)
    print(string.format("   %-30s %s", issue.description .. ":", found and "✅ Found" or "❌ Not found"))
end

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
    print("✅ All required methods found")
else
    warn("❌ Some required methods are missing")
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

-- 10. Analysis Summary
print("\n=== Analysis Summary ===")
print("1. MainModule is present and is a ModuleScript")
print("2. Source code analysis completed")
print("3. Required methods: " .. (allMethodsFound and "✅ All found" or "❌ Some missing"))
print("4. Initialization state: " .. (isInitialized and "✅ Initialized" or "❌ Not initialized"))
print("5. Initialized systems: " .. (next(systems) and tostring(#systems) or "None"))

print("\n=== Analysis Complete ===\n")
