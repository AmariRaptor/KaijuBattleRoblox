--!strict

print("Server initialization started.")

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

-- Module interface
local MainModule = {}
MainModule.__index = MainModule

-- State
local initialized = false
local initializedSystems = {}

-- List of systems to load (SpawnSystem added)
local systemsToLoad = {
    "ClassSystem",
    "CharacterSystem",
    "BuildingSystem",
    "SpawnSystem",
    "KaijuSystem",
    "ScoringSystem",
}

-- Helper: locate systems folder (ServerScriptService/systems or script parent)
local function findSystemsFolder()
    local systemsFolder = ServerScriptService:FindFirstChild("systems")
    if systemsFolder and systemsFolder:IsA("Folder") then
        return systemsFolder
    end
    if script.Parent then
        local alt = script.Parent:FindFirstChild("systems")
        if alt and alt:IsA("Folder") then
            return alt
        end
    end
    return nil
end

-- Helper: require a ModuleScript safely
local function safeRequire(mod)
    local ok, result = pcall(require, mod)
    if not ok then
        warn("[MainModule] require failed for " .. tostring(mod and mod.Name) .. ": " .. tostring(result))
        return nil, result
    end
    return result
end

-- Initialize a single system by name
local function initializeSystem(name: string)
    print("[MainModule] Initializing system: " .. tostring(name))

    local systemsFolder = findSystemsFolder()
    if not systemsFolder then
        warn("[MainModule] systems folder not found")
        return nil, "no systems folder"
    end

    local moduleScript = systemsFolder:FindFirstChild(name)
    if not (moduleScript and moduleScript:IsA("ModuleScript")) then
        warn("[MainModule] ModuleScript not found for system: " .. tostring(name))
        return nil, "module not found"
    end

    local system, err = safeRequire(moduleScript)
    if not system then
        return nil, err
    end

    if type(system) ~= "table" then
        warn("[MainModule] System " .. tostring(name) .. " did not return a table")
        return nil, "invalid module"
    end

    if type(system.init) ~= "function" then
        warn("[MainModule] System " .. tostring(name) .. " is missing init(); adding default implementation")
        system.init = function()
            print("[MainModule] Default init for " .. tostring(name))
            return true
        end
    end

    local ok, result = pcall(function()
        return system.init(system)
    end)

    if not ok then
        warn("[MainModule] " .. tostring(name) .. ":init() failed: " .. tostring(result))
        return nil, result
    end

    if result == false then
        warn("[MainModule] " .. tostring(name) .. ":init() returned false")
        return nil, "init returned false"
    end

    initializedSystems[name] = system
    print("[MainModule] " .. tostring(name) .. " initialized successfully")
    return system
end

-- Public: initialize all systems
function MainModule:init(): boolean
    if initialized then
        warn("[MainModule] already initialized")
        return true
    end

    print("[MainModule] Starting initialization of systems...")
    local systemsFolder = findSystemsFolder()
    if not systemsFolder then
        warn("[MainModule] systems folder not found; initialization may fail")
    end

    for _, systemName in ipairs(systemsToLoad) do
        local _, err = initializeSystem(systemName)
        if err then
            warn("[MainModule] Failed to initialize " .. tostring(systemName) .. ": " .. tostring(err))
        end
    end

    initialized = true

    -- Best-effort: wire player events using CharacterSystem if available
    local charSys = initializedSystems["CharacterSystem"]
    if charSys and type(charSys.onPlayerAdded) == "function" then
        Players.PlayerAdded:Connect(function(player)
            pcall(function() charSys.onPlayerAdded(player) end)
        end)

        -- initialize existing players
        for _, player in ipairs(Players:GetPlayers()) do
            pcall(function() charSys.onPlayerAdded(player) end)
        end
    end

    print("[MainModule] Initialization complete")
    return true
end

function MainModule:getSystem(systemName: string)
    return initializedSystems[systemName]
end

function MainModule:getInitializedSystems()
    local result = {}
    for name, system in pairs(initializedSystems) do
        result[name] = system
    end
    return result
end

-- Expose initialization state so CLI/MCP inspectors can detect whether
-- the module has already been initialized.
function MainModule:isInitialized(): boolean
    return initialized
end

-- Simple entry point for executing the main module from CLI or other runners.
-- This will attempt to initialize the module (if not already), then call
-- `start()` on any initialized system that exposes that method.
function MainModule:run()
    print("[MainModule] run() invoked")

    -- Ensure initialization
    local ok, initRes = pcall(function() return self:init() end)
    if not ok then
        warn("[MainModule] run(): init errored: " .. tostring(initRes))
        return false, initRes
    end

    -- Start any systems that expose a start() function
    for name, system in pairs(initializedSystems) do
        if type(system.start) == "function" then
            local startedOk, startedRes = pcall(function() return system:start() end)
            if not startedOk then
                warn("[MainModule] Failed to start system " .. tostring(name) .. ": " .. tostring(startedRes))
            else
                print("[MainModule] Started system: " .. tostring(name))
            end
        end
    end

    print("[MainModule] run() completed. Systems started where available.")
    return true
end

return MainModule