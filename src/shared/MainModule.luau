--!strict
-- MainModule.luau
-- Main module containing shared configurations and utilities

local MainModule = {}

-- System configurations
export type SystemConfig = {
    debug: boolean,
    maxPlayers: number,
    defaultSettings: {
        volume: number,
        difficulty: string,
    }
}

-- Default configuration
local config: SystemConfig = {
    debug = true,
    maxPlayers = 10,
    defaultSettings = {
        volume = 0.7,
        difficulty = "normal",
    }
}

-- System state
local state = {
    initialized = false,
    systems = {},
    eventHandlers = {}
}

-- Initialize the main module
function MainModule.init(): (boolean, string?)
    if state.initialized then
        return false, "MainModule already initialized"
    end
    
    state.initialized = true
    
    if config.debug then
        print("🔧 MainModule initialized")
    end
    
    return true
end

-- Get configuration value
function MainModule.getConfig(): SystemConfig
    return table.clone(config)
end

-- Update configuration
function MainModule.updateConfig(updates: {[string]: any}): (boolean, string?)
    -- Validate updates
    for key, _ in pairs(updates) do
        if config[key] == nil then
            return false, `Invalid config key: {key}`
        end
    end
    
    -- Apply updates
    for key, value in pairs(updates) do
        if type(config[key]) == "table" and type(value) == "table" then
            -- Merge tables
            for k, v in pairs(value) do
                config[key][k] = v
            end
        else
            config[key] = value
        end
    end
    
    return true
end

-- Register a system
function MainModule.registerSystem(systemName: string, system: any): boolean
    if state.systems[systemName] then
        warn(`[MainModule] System '{systemName}' is already registered`)
        return false
    end
    
    state.systems[systemName] = system
    
    if config.debug then
        print(`[MainModule] Registered system: {systemName}`)
    end
    
    return true
end

-- Get a registered system
function MainModule.getSystem(systemName: string): any?
    return state.systems[systemName]
end

-- Register an event handler
function MainModule.on(eventName: string, handler: (...any) -> ()): () -> ()
    if not state.eventHandlers[eventName] then
        state.eventHandlers[eventName] = {}
    end
    
    local id = tostring({}):sub(8) -- Generate unique ID
    state.eventHandlers[eventName][id] = handler
    
    -- Return unregister function
    return function()
        if state.eventHandlers[eventName] then
            state.eventHandlers[eventName][id] = nil
        end
    end
end

-- Emit an event
function MainModule.emit(eventName: string, ...)
    local handlers = state.eventHandlers[eventName] or {}
    for _, handler in pairs(handlers) do
        task.spawn(handler, ...)
    end
end

-- Initialize the module
local success, err = MainModule.init()
if not success and err then
    warn(`[MainModule] Failed to initialize: {err}`)
end

return MainModule
