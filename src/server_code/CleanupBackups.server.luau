--!strict
-- Script to clean up backup MainModule files

local ServerScriptService = game:GetService("ServerScriptService")

print("\n=== Cleaning Up Backups ===\n")

-- 1. Find all backup modules
local backups = {}
for _, child in ipairs(ServerScriptService:GetChildren()) do
    if child.Name:find("MainModule_Backup_", 1, true) == 1 and child:IsA("ModuleScript") then
        table.insert(backups, child)
    end
end

-- 2. If no backups found, we're done
if #backups == 0 then
    print("✅ No backup modules found to clean up")
    return
end

-- 3. List found backups
print(string.format("Found %d backup module(s):", #backups))
for _, backup in ipairs(backups) do
    print("  - " .. backup.Name .. " (Created: " .. backup.Name:match("Backup_(.+)$") or "unknown" .. ")")
end

-- 4. Verify MainModule exists and is working
local mainModule = ServerScriptService:FindFirstChild("MainModule")
if not mainModule or not mainModule:IsA("ModuleScript") then
    warn("❌ MainModule not found! Aborting cleanup to prevent data loss")
    return
end

-- 5. Try to require MainModule to verify it works
local success, module = pcall(require, mainModule)
if not success then
    warn("❌ MainModule failed to load! Aborting cleanup to prevent data loss")
    warn("Error:", module)
    return
end

-- 6. Check if MainModule is initialized
if type(module.isInitialized) ~= "function" or not module:isInitialized() then
    warn("❌ MainModule is not properly initialized! Aborting cleanup")
    return
end

-- 7. All checks passed, remove backups
print("\n✅ All checks passed. Removing backup modules...")
local removedCount = 0
for _, backup in ipairs(backups) do
    print("  - Removing " .. backup.Name)
    backup:Destroy()
    removedCount += 1
end

-- 8. Print completion message
print("\n=== Cleanup Complete ===")
print(string.format("✅ Removed %d backup module(s)", removedCount))
print("\nThe MainModule has been successfully migrated and backups have been cleaned up.")
print("The game is now running with the fixed MainModule implementation.")
