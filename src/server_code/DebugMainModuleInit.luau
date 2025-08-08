--!strict
-- DebugMainModuleInit.luau
-- Script to debug MainModule initialization process

local function logSuccess(message: string)
    print("✅ " .. message)
end

local function logWarning(message: string)
    warn("⚠️ " .. message)
end

local function logError(message: string)
    warn("❌ " .. message)
end

print("\n=== MainModule Initialization Debugger ===\n")

-- 1. Environment Setup
print("=== Environment ===")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

print("Server: " .. tostring(RunService:IsServer()))
print("Studio: " .. tostring(RunService:IsStudio()))
print("Game ID: " .. tostring(game.GameId))
print("Place ID: " .. tostring(game.PlaceId))
print("Server Time: " .. os.date("%c", os.time()))

-- 2. Locate MainModule
print("\n=== Locating MainModule ===")
local mainModule = ServerScriptService:FindFirstChild("MainModule")

if not mainModule then
    logError("MainModule not found in ServerScriptService")
    logWarning("Available children in ServerScriptService:")
    for _, child in ipairs(ServerScriptService:GetChildren()) do
        print("   - " .. child:GetFullName() .. " (" .. child.ClassName .. ")")
    end
    return
end

logSuccess("Found MainModule: " .. mainModule:GetFullName())
print("   Class: " .. mainModule.ClassName)
print("   Source length: " .. #mainModule.Source .. " characters")

-- 3. Check if it's a ModuleScript
if not mainModule:IsA("ModuleScript") then
    logError("MainModule is not a ModuleScript (it's a " .. mainModule.ClassName .. ")")
    return
end

-- 4. Create a sandbox environment to require the module
print("\n=== Creating Sandbox Environment ===")
local sandbox = {
    game = game,
    script = mainModule,
    require = require,
    print = print,
    warn = warn,
    error = error,
    pcall = pcall,
    xpcall = xpcall,
    getfenv = getfenv,
    setfenv = setfenv,
    getmetatable = getmetatable,
    setmetatable = setmetatable,
    next = next,
    pairs = pairs,
    ipairs = ipairs,
    select = select,
    type = type,
    unpack = unpack,
    _VERSION = _VERSION,
    assert = assert,
    coroutine = coroutine,
    debug = debug,
    math = math,
    os = os,
    string = string,
    table = table,
    task = task,
    utf8 = utf8,
    bit32 = bit32,
    typeof = typeof,
    warn = warn,
    wait = task.wait,
    tick = tick,
    time = os.time,
    spawn = task.spawn,
    delay = task.delay,
    -- Add any other required globals
}

-- Set up metatable for the sandbox
local sandboxEnv = setmetatable({}, {
    __index = function(_, key)
        return sandbox[key] or _G[key]
    end,
    __newindex = function(_, key, value)
        rawset(sandbox, key, value)
    end
})

-- 5. Load the module in the sandbox
print("\n=== Loading MainModule in Sandbox ===")
local chunk, loadError = loadstring(
    "local script = ...\n" ..
    "local module = {}\n" ..
    "setmetatable(module, { __tostring = function() return 'MainModule' end })\n" ..
    mainModule.Source .. "\n" ..
    "return module",
    "@MainModule"
)

if not chunk then
    logError("Failed to load MainModule chunk:")
    warn(loadError)
    return
end

-- Set the environment for the chunk
setfenv(chunk, sandboxEnv)

-- 6. Execute the module in protected mode
print("\n=== Executing MainModule ===")
local success, module = pcall(chunk, mainModule)

if not success then
    logError("Failed to execute MainModule:")
    warn(module)
    return
end

if type(module) ~= "table" then
    logError("MainModule did not return a table, got: " .. type(module))
    return
end

logSuccess("Successfully loaded MainModule")
print("   Module type: " .. type(module))

-- 7. Check for required methods
print("\n=== Checking Required Methods ===")
local requiredMethods = {
    "init",
    "isInitialized",
    "getSystem",
    "getInitializedSystems"
}

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

-- 8. Check initialization state
print("\n=== Checking Initialization State ===")
local function checkInitialized()
    local success, result = pcall(module.isInitialized, module)
    if not success then
        logError("Error calling isInitialized():")
        warn(result)
        return false, result
    end
    return true, result
end

local wasInitialized, initState = checkInitialized()
if wasInitialized then
    print("Initialization state before init: " .. tostring(initState))
end

-- 9. Try to initialize if not already initialized
if not initState then
    print("\n=== Initializing MainModule ===")
    local initSuccess, initResult = pcall(module.init, module)
    
    if not initSuccess then
        logError("Failed to initialize MainModule:")
        warn(initResult)
    else
        logSuccess("MainModule initialized successfully")
        
        -- Check initialization state again
        local checkSuccess, checkResult = checkInitialized()
        if checkSuccess then
            print("Initialization state after init: " .. tostring(checkResult))
        end
    end
end

-- 10. Check initialized systems
print("\n=== Checking Initialized Systems ===")
local systems = {}
local getSystemsSuccess, getSystemsResult = pcall(module.getInitializedSystems, module)

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
        
        print("Found " .. systemCount .. " initialized systems")
        if systemCount > 0 then
            print("Systems:")
            for name, _ in pairs(systems) do
                print("   - " .. tostring(name))
            end
        end
    end
end

-- 11. Test getting a system
print("\n=== Testing System Retrieval ===")
local testSystemName = next(systems) or "TestSystem1"
local getSystemSuccess, system = pcall(module.getSystem, module, testSystemName)

if not getSystemSuccess then
    logError("Error calling getSystem(\"" .. testSystemName .. "\"):")
    warn(system)
else
    if system == nil then
        print("getSystem(\"" .. testSystemName .. "\"): nil (system not found)")
    else
        logSuccess("Successfully retrieved system: " .. testSystemName)
        print("   System type: " .. type(system))
    end
end

-- 12. Final Summary
print("\n=== Debug Summary ===")
print("1. Environment: " .. (RunService:IsServer() and "Server" or "Client"))
print("2. MainModule: " .. (mainModule and "✅ Found" or "❌ Missing"))
print("3. Required Methods: " .. (allMethodsFound and "✅ All found" or "❌ Some missing"))
print("4. Initialized: " .. (initState and "✅ Yes" or "❌ No"))
print("5. Systems Found: " .. (next(systems) and #systems or "0"))
print("\n=== Debugging Complete ===\n")
