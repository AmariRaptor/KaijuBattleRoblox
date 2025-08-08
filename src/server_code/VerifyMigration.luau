--!strict
-- VerifyMigration.luau
-- Script to verify the MainModule migration was successful

local ServerScriptService = game:GetService("ServerScriptService")

print("\n=== Verifying MainModule Migration ===\n")

-- 1. Check if MainModule exists
local mainModule = ServerScriptService:FindFirstChild("MainModule")
if not mainModule then
    warn("❌ MainModule not found in ServerScriptService")
    return false
end

print("✅ Found MainModule:", mainModule:GetFullName())

-- 2. Check if it's the enhanced version
local source = mainModule.Source
local isEnhanced = string.find(source, "Enhanced MainModule") ~= nil
print(string.format("   Version: %s", isEnhanced and "✅ Enhanced" or "❌ Original"))

-- 3. Check for backup
local hasBackup = false
for _, child in ipairs(ServerScriptService:GetChildren()) do
    if child.Name:find("MainModule_Backup_") == 1 then
        hasBackup = true
        print("✅ Found backup:", child:GetFullName())
        break
    end
end

if not hasBackup then
    warn("⚠️ No backup found of original MainModule")
end

-- 4. Test requiring the module
print("\n=== Testing MainModule ===")
local success, module = pcall(require, mainModule)
if not success then
    warn("❌ Failed to require MainModule:")
    warn(module)
    return false
end

print("✅ Successfully required MainModule")

-- 5. Check required methods
local requiredMethods = {"init", "isInitialized", "getSystem", "getInitializedSystems"}
local allMethodsFound = true

print("\n=== Checking Required Methods ===")
for _, method in ipairs(requiredMethods) do
    local exists = type(module[method]) == "function"
    print(string.format("   %-20s %s", method .. ":", exists and "✅ Found" or "❌ Missing"))
    allMethodsFound = allMethodsFound and exists
end

if not allMethodsFound then
    warn("❌ Not all required methods were found")
    return false
end

-- 6. Test initialization
print("\n=== Testing Initialization ===")
if module:isInitialized() then
    print("✅ MainModule is already initialized")
else
    print("Initializing MainModule...")
    local initSuccess, initResult = pcall(module.init, module)
    if not initSuccess then
        warn("❌ Initialization failed:")
        warn(initResult)
        return false
    end
    
    print("✅ Initialization successful:", initResult)
end

-- 7. Check system status
print("\n=== System Status ===")
local systems = module:getInitializedSystems()
local systemCount = 0

for name, _ in pairs(systems) do
    systemCount += 1
    print(string.format("   ✅ %s", name))
end

if systemCount == 0 then
    warn("⚠️ No systems were initialized")
else
    print(string.format("✅ %d systems initialized successfully", systemCount))
end

print("\n=== Migration Verification Complete ===")
return true
