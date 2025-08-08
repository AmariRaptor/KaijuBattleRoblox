--!strict
-- TestMainModule.lua
-- Place this in ServerScriptService and run in Roblox Studio

local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

print("=== Starting MainModule Test ===\n")

-- Function to format output
local function logSuccess(message: string)
    print("✅ " .. message)
end

local function logWarning(message: string)
    warn("⚠️ " .. message)
end

local function logError(message: string)
    warn("❌ " .. message)
end

-- Wait for MainModule to be available
logSuccess("Looking for MainModule in ServerScriptService...")
local mainModule = ServerScriptService:WaitForChild("MainModule", 10)

if not mainModule then
    logError("MainModule not found in ServerScriptService")
    logWarning("Available children in ServerScriptService:")
    for _, child in ipairs(ServerScriptService:GetChildren()) do
        print("   - " .. child:GetFullName() .. " (" .. child.ClassName .. ")")
    end
    return
end

logSuccess("Found MainModule: " .. mainModule:GetFullName())
logSuccess("Class: " .. mainModule.ClassName)

-- Verify it's a ModuleScript
if not mainModule:IsA("ModuleScript") then
    logError("MainModule is not a ModuleScript (it's a " .. mainModule.ClassName .. ")")
    return
end

-- Try to require the module
logSuccess("Attempting to require MainModule...")
local success, module = pcall(require, mainModule)

if not success then
    logError("Failed to require MainModule:")
    warn(module)
    return
end

logSuccess("Successfully required MainModule")
print("Module type:", type(module))

-- Check for required methods
local requiredMethods = {
    "init",
    "isInitialized",
    "getSystem",
    "getInitializedSystems"
}

print("\n=== Checking Required Methods ===")
local allMethodsFound = true
for _, method in ipairs(requiredMethods) do
    if type(module[method]) ~= "function" then
        logError("Missing required method: " .. method)
        allMethodsFound = false
    else
        logSuccess("Found method: " .. method)
    end
end

if allMethodsFound then
    logSuccess("All required methods found")
end

-- Check initialization state
local function checkInitialized()
    local success, result = pcall(function()
        return module:isInitialized()
    end)
    if not success then
        logError("Error checking isInitialized(): " .. tostring(result))
        return false, result
    end
    return true, result
end

print("\n=== Checking Initialization State ===")
local wasInitialized, initState = checkInitialized()
if wasInitialized then
    print("Initialization state before init: " .. tostring(initState))
end

-- Try to initialize if not already initialized
if not initState then
    print("\n=== Initializing MainModule ===")
    local initSuccess, initResult = pcall(function()
        return module:init()
    end)

    if not initSuccess then
        logError("Init failed:")
        warn(initResult)
    else
        logSuccess("Init completed successfully")
        
        -- Check initialization state again
        local checkSuccess, checkResult = checkInitialized()
        if checkSuccess then
            print("Initialization state after init: " .. tostring(checkResult))
        end
        
        -- Check systems
        print("\n=== Checking Initialized Systems ===")
        local systemsSuccess, systems = pcall(function()
            return module:getInitializedSystems()
        end)
        
        if not systemsSuccess then
            logError("Failed to get systems:")
            warn(systems)
        else
            if type(systems) ~= "table" then
                logError("Expected table from getInitializedSystems(), got: " .. type(systems))
            else
                local count = 0
                print("\nInitialized Systems:")
                print("--------------------")
                for name, _ in pairs(systems) do
                    count += 1
                    print(count .. ". " .. tostring(name))
                end
                if count == 0 then
                    logWarning("No systems were initialized")
                else
                    logSuccess(string.format("Found %d initialized system(s)", count))
                end
            end
        end
    end
end

-- Additional debug information
print("\n=== Additional Debug Information ===")
print("Game ID:", game.GameId)
print("Place ID:", game.PlaceId)
print("Server Type:", RunService:IsServer() and "Server" or "Client")
print("Run Mode:", RunService:IsStudio() and "Studio" or "Live")
print("Tick:", tick())

print("\n=== Test Complete ===\n")
