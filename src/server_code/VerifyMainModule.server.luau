--!strict
-- Verification script to ensure MainModule is working correctly

local ServerScriptService = game:GetService("ServerScriptService")

print("\n=== Verifying MainModule ===\n")

-- 1. Check if MainModule exists
local mainModule = ServerScriptService:FindFirstChild("MainModule")
if not mainModule or not mainModule:IsA("ModuleScript") then
    warn("❌ MainModule not found in ServerScriptService")
    return
end

print("✅ Found MainModule in ServerScriptService")

-- 2. Check if FixedMainModule exists
local fixedModule = ServerScriptService:FindFirstChild("FixedMainModule")
if not fixedModule or not fixedModule:IsA("ModuleScript") then
    warn("❌ FixedMainModule not found in ServerScriptService")
    return
end

print("✅ Found FixedMainModule in ServerScriptService")

-- 3. Check MainModule's source
local source = mainModule.Source
if not source:find("FixedMainModule", 1, true) then
    warn("⚠️ MainModule doesn't appear to be using FixedMainModule")
    print("MainModule source starts with:", source:sub(1, 100) .. "...")
else
    print("✅ MainModule is correctly using FixedMainModule")
end

-- 4. Try to require MainModule
local success, module = pcall(require, mainModule)
if not success then
    warn("❌ Failed to require MainModule:")
    warn(module)
    return
end

print("✅ Successfully required MainModule")

-- 5. Check if MainModule is initialized
if type(module.isInitialized) ~= "function" then
    warn("❌ MainModule doesn't have isInitialized method")
    return
end

print("✅ MainModule has isInitialized method")

-- 6. Check initialization state
local isInitialized = module:isInitialized()
print("MainModule isInitialized():", isInitialized and "✅ Yes" or "❌ No")

-- 7. Get initialized systems
if type(module.getInitializedSystems) ~= "function" then
    warn("❌ MainModule doesn't have getInitializedSystems method")
    return
end

local systems = module:getInitializedSystems()
print("\n=== Initialized Systems ===")
if next(systems) == nil then
    warn("⚠️ No systems were initialized!")
else
    print("✅ Successfully initialized systems:")
    for name, _ in pairs(systems) do
        print("  - " .. name)
    end
end

-- 8. Check for backup modules
print("\n=== Backup Check ===")
local hasBackups = false
for _, child in ipairs(ServerScriptService:GetChildren()) do
    if child.Name:find("MainModule_Backup_", 1, true) == 1 then
        print("⚠️ Found backup module:", child.Name)
        hasBackups = true
    end
end

if not hasBackups then
    print("✅ No backup modules found")
end

print("\n=== Verification Complete ===\n")

-- 9. Print next steps
print("NEXT STEPS:")
print("1. Test the game to ensure all systems are functioning correctly")
print("2. If everything works, you can safely remove any backup modules")
print("3. The backup modules can be identified by the 'MainModule_Backup_' prefix")
print("\n=== End of Verification ===\n")
