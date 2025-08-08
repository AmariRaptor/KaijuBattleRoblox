--!strict

-- This script converts a Script to a ModuleScript
local scriptName = ...
if not scriptName then
    warn("❌ Please provide a script name as an argument")
    return
end

local ServerScriptService = game:GetService("ServerScriptService")
local systemsFolder = ServerScriptService:WaitForChild("systems")

-- Find the script to convert
local scriptToConvert = systemsFolder:FindFirstChild(scriptName)
if not scriptToConvert then
    warn(string.format("❌ Script '%s' not found in systems folder", scriptName))
    return
end

if not scriptToConvert:IsA("Script") then
    warn(string.format("❌ '%s' is a %s, not a Script", scriptName, scriptToConvert.ClassName))
    return
end

print(string.format("Converting %s from Script to ModuleScript...", scriptName))

-- Create a new ModuleScript with the same properties
local moduleScript = Instance.new("ModuleScript")
moduleScript.Name = scriptToConvert.Name
moduleScript.Source = scriptToConvert.Source
moduleScript.Parent = scriptToConvert.Parent

-- Remove the old Script
scriptToConvert:Destroy()

print(string.format("✅ Successfully converted %s to a ModuleScript", scriptName))

-- Verify the conversion
local success, result = pcall(require, moduleScript)
if success then
    print(string.format("✅ Successfully required %s as a ModuleScript", scriptName))
    
    -- Check if it has an init function
    if type(result.init) == "function" then
        print("✅ Found init() function")
        
        -- Try to initialize the module
        local initSuccess, initResult = pcall(result.init, result)
        if initSuccess then
            print("✅ Module initialized successfully")
            print("Init result:", initResult)
        else
            warn("❌ Module initialization failed:")
            warn(initResult)
        end
    else
        warn("⚠️ Module does not have an init() function")
    end
else
    warn("❌ Failed to require module:")
    warn(result)
end
