--!strict
-- MigrateToEnhancedMainModule.luau
-- Script to migrate from the old MainModule to the enhanced version

local ServerScriptService = game:GetService("ServerScriptService")

print("\n=== Starting MainModule Migration ===\n")

-- 1. Backup the original MainModule
local function backupMainModule()
    local mainModule = ServerScriptService:FindFirstChild("MainModule")
    if not mainModule then
        warn("❌ MainModule not found in ServerScriptService")
        return false
    end
    
    -- Create a backup
    local backup = mainModule:Clone()
    backup.Name = "MainModule_Backup_" .. os.date("%Y%m%d_%H%M%S")
    backup.Parent = ServerScriptService
    
    print("✅ Created backup:", backup:GetFullName())
    return true
end

-- 2. Replace MainModule with EnhancedMainModule
local function replaceMainModule()
    local enhancedModule = ServerScriptService:FindFirstChild("EnhancedMainModule")
    if not enhancedModule then
        warn("❌ EnhancedMainModule not found in ServerScriptService")
        return false
    end
    
    -- Remove existing MainModule if it exists
    local oldModule = ServerScriptService:FindFirstChild("MainModule")
    if oldModule then
        oldModule:Destroy()
    end
    
    -- Create new MainModule from EnhancedMainModule
    local newMainModule = enhancedModule:Clone()
    newMainModule.Name = "MainModule"
    newMainModule.Parent = ServerScriptService
    
    print("✅ Successfully replaced MainModule with enhanced version")
    return true
end

-- 3. Verify the migration
local function verifyMigration()
    local mainModule = ServerScriptService:FindFirstChild("MainModule")
    if not mainModule or not mainModule:IsA("ModuleScript") then
        warn("❌ Verification failed: MainModule not found or is not a ModuleScript")
        return false
    end
    
    -- Try to require the module
    local success, module = pcall(require, mainModule)
    if not success then
        warn("❌ Verification failed: Could not require MainModule")
        warn(module)
        return false
    end
    
    -- Check for required methods
    local requiredMethods = {"init", "isInitialized", "getSystem", "getInitializedSystems"}
    for _, method in ipairs(requiredMethods) do
        if type(module[method]) ~= "function" then
            warn(string.format("❌ Verification failed: Missing required method '%s'", method))
            return false
        end
    end
    
    print("✅ Verification successful: MainModule is valid")
    return true
end

-- 4. Main migration function
local function migrate()
    print("🚀 Starting migration to enhanced MainModule...\n")
    
    -- Step 1: Create backup
    print("1. Creating backup of current MainModule...")
    if not backupMainModule() then
        warn("❌ Migration aborted: Could not create backup")
        return false
    end
    
    -- Step 2: Replace MainModule
    print("\n2. Replacing MainModule with enhanced version...")
    if not replaceMainModule() then
        warn("❌ Migration aborted: Could not replace MainModule")
        return false
    end
    
    -- Step 3: Verify migration
    print("\n3. Verifying migration...")
    if not verifyMigration() then
        warn("❌ Migration completed with verification errors")
        return false
    end
    
    print("\n🎉 Migration completed successfully!")
    return true
end

-- Run the migration
local success, result = pcall(migrate)
if not success then
    warn("❌ Migration failed with error:")
    warn(result)
end

return success and result
