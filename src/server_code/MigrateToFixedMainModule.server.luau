--!strict
-- Migration script to replace MainModule with FixedMainModule

local ServerScriptService = game:GetService("ServerScriptService")

print("\n=== Migrating to FixedMainModule ===\n")

-- 1. Find the old MainModule
local oldMainModule = ServerScriptService:FindFirstChild("MainModule")
local oldMainModuleExists = oldMainModule ~= nil

if oldMainModuleExists then
    print("✅ Found existing MainModule")
    
    -- Create a backup of the old MainModule
    local backup = oldMainModule:Clone()
    backup.Name = "MainModule_Backup_" .. os.date("%Y%m%d_%H%M%S")
    backup.Parent = ServerScriptService
    print("✅ Created backup at:", backup:GetFullName())
    
    -- Remove the old MainModule
    oldMainModule:Destroy()
    print("✅ Removed old MainModule")
else
    print("ℹ️ No existing MainModule found, proceeding with fresh installation")
end

-- 2. Create the new MainModule
print("\nCreating new MainModule...")
local newMainModule = Instance.new("ModuleScript")
newMainModule.Name = "MainModule"
newMainModule.Source = [[--!strict

-- Fixed MainModule with proper state management
-- This is a wrapper that creates and initializes a new FixedMainModule instance

local ServerScriptService = game:GetService("ServerScriptService")

-- Require the FixedMainModule
local FixedMainModule = require(script.Parent:WaitForChild("FixedMainModule"))

-- Create a single instance
local instance = FixedMainModule.new()

-- Initialize immediately
local success, result = pcall(instance.init, instance)
if not success then
    warn("❌ Failed to initialize FixedMainModule:")
    warn(result)
else
    print("✅ FixedMainModule initialized successfully")
end

-- Return the instance for other scripts to use
return instance
]]

-- 3. Add the new MainModule to ServerScriptService
newMainModule.Parent = ServerScriptService
print("✅ Added new MainModule to ServerScriptService")

-- 4. Ensure FixedMainModule is in the right location
local fixedModule = script.Parent:FindFirstChild("FixedMainModule")
if not fixedModule then
    warn("❌ FixedMainModule not found in ServerScriptService")
    return
end

-- 5. Print instructions for manual verification
print("\n=== Migration Complete ===")
print("✅ Successfully migrated to FixedMainModule")
print("\nNext steps:")
print("1. Test the game to ensure everything works as expected")
print("2. If everything works, you can safely remove the backup at:")
print("   " .. (backup and backup:GetFullName() or "[backup not created]"))
print("\n=== Migration Finished ===\n")
