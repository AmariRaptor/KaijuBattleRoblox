--!strict
-- EnhancedMainModule.luau
-- Enhanced MainModule with robust error handling, dependency management, and logging

local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

-- Verify we're running on the server
if not RunService:IsServer() then
    warn("🔴 [FATAL] MainModule should only be required on the server")
    return {}
end

-- Types
type System = {
    init: (self: any) -> (boolean, string?),
    start: ((self: any) -> ())?,
    stop: ((self: any) -> ())?,
    name: string?,
    version: string?,
    dependencies: {string}?
}

type SystemStatus = {
    name: string,
    loaded: boolean,
    initialized: boolean,
    started: boolean,
    error: string?,
    dependencies: {string},
    loadTime: number?,
    initTime: number?,
    startTime: number?,
    lastError: string?
}

-- Module table
local MainModule = {
    -- State
    initialized = false,
    started = false,
    systems = {},
    systemStatus = {},
    
    -- Configuration
    config = {
        debug = true,
        strictMode = true,
        autoStart = true,
        dependencyCheck = true,
        maxInitRetries = 3,
        initRetryDelay = 1
    },
    
    -- Private state
    _private = {
        initPromise = nil,
        startPromise = nil,
        eventHandlers = {},
        systemDependencies = {},
        reverseDependencies = {}
    },
    
    -- Logger with different log levels
    logger = {
        levels = {
            TRACE = 0,
            DEBUG = 1,
            INFO = 2,
            WARN = 3,
            ERROR = 4,
            FATAL = 5
        },
        minLevel = 2, -- Default to INFO
        
        setLevel = function(self, level: number)
            self.minLevel = level
        end,
        
        log = function(self, level: number, message: string, ...)
            if level < self.minLevel then return end
            
            local levelName = "UNKNOWN"
            for name, lvl in pairs(self.levels) do
                if level == lvl then
                    levelName = name
                    break
                end
            end
            
            local formattedMessage = string.format("[%s] %s", levelName, message:format(...))
            
            if level >= self.levels.ERROR then
                warn(formattedMessage)
            else
                print(formattedMessage)
            end
        end,
        
        trace = function(self, message, ...)
            self:log(self.levels.TRACE, message, ...)
        end,
        
        debug = function(self, message, ...)
            self:log(self.levels.DEBUG, message, ...)
        end,
        
        info = function(self, message, ...)
            self:log(self.levels.INFO, message, ...)
        end,
        
        warn = function(self, message, ...)
            self:log(self.levels.WARN, message, ...)
        end,
        
        error = function(self, message, ...)
            self:log(self.levels.ERROR, message, ...)
        end,
        
        fatal = function(self, message, ...)
            self:log(self.levels.FATAL, message, ...)
        end
    }
}

-- List of systems to load (in order)
local systemsToLoad = {
    "ClassSystem",
    "CharacterSystem",
    "BuildingSystem",
    "KaijuSystem",
    "ScoringSystem"
}

-- Private functions
local function validateSystem(system: any, systemName: string): (boolean, string?)
    if type(system) ~= "table" then
        return false, "System must be a table"
    end
    
    if type(system.init) ~= "function" then
        return false, "System must implement init() function"
    end
    
    -- Optional but recommended fields
    if system.name == nil then
        system.name = systemName
    end
    
    if system.version == nil then
        system.version = "1.0.0"
    end
    
    if system.dependencies == nil then
        system.dependencies = {}
    end
    
    return true, nil
end

local function initializeSystem(self: any, systemName: string, system: System): (boolean, string?)
    local startTime = os.clock()
    local status = self.systemStatus[systemName]
    
    if status.initialized then
        return true, "Already initialized"
    end
    
    -- Check dependencies
    for _, depName in ipairs(system.dependencies or {}) do
        local depStatus = self.systemStatus[depName]
        if not depStatus or not depStatus.initialized then
            return false, string.format("Dependency not initialized: %s", depName)
        end
    end
    
    -- Initialize the system
    local success, result = xpcall(function()
        return system:init()
    end, function(err)
        return debug.traceback(tostring(err), 2)
    end)
    
    if not success then
        status.error = tostring(result)
        status.lastError = os.time()
        return false, string.format("Initialization failed: %s", tostring(result))
    end
    
    if type(result) == "boolean" and not result then
        status.error = "Initialization returned false"
        status.lastError = os.time()
        return false, "Initialization returned false"
    end
    
    status.initialized = true
    status.initTime = os.clock() - startTime
    
    return true, "Initialized successfully"
end

local function startSystem(self: any, systemName: string, system: System): (boolean, string?)
    local status = self.systemStatus[systemName]
    
    if status.started then
        return true, "Already started"
    end
    
    if not status.initialized then
        return false, "System not initialized"
    end
    
    if type(system.start) ~= "function" then
        status.started = true
        return true, "No start function, marked as started"
    end
    
    local startTime = os.clock()
    local success, result = xpcall(function()
        return system:start()
    end, function(err)
        return debug.traceback(tostring(err), 2)
    end)
    
    if not success then
        status.error = tostring(result)
        status.lastError = os.time()
        return false, string.format("Start failed: %s", tostring(result))
    end
    
    status.started = true
    status.startTime = os.clock() - startTime
    
    return true, "Started successfully"
end

-- Public methods
function MainModule:isInitialized(): boolean
    return self.initialized
end

function MainModule:isStarted(): boolean
    return self.started
end

function MainModule:getSystem(systemName: string): System?
    if not self.initialized then
        self.logger:warn("Cannot get system: MainModule not initialized")
        return nil
    end
    
    local system = self.systems[systemName]
    if not system then
        self.logger:warn("System not found: %s", systemName)
        return nil
    end
    
    return system
end

function MainModule:getSystemStatus(systemName: string): SystemStatus?
    return self.systemStatus[systemName]
end

function MainModule:getAllSystemStatuses(): {[string]: SystemStatus}
    return self.systemStatus
end

function MainModule:getInitializedSystems(): {[string]: System}
    if not self.initialized then
        self.logger:warn("Cannot get systems: MainModule not initialized")
        return {}
    end
    
    local result = {}
    for name, system in pairs(self.systems) do
        if self.systemStatus[name] and self.systemStatus[name].initialized then
            result[name] = system
        end
    end
    
    return result
end

function MainModule:verifySystems(): (boolean, {[string]: string}?)
    local errors = {}
    
    for _, systemName in ipairs(systemsToLoad) do
        local status = self.systemStatus[systemName]
        if not status or not status.initialized then
            errors[systemName] = status and status.error or "Not loaded"
        end
    end
    
    return next(errors) == nil, next(errors) ~= nil and errors or nil
end

function MainModule:init(): (boolean, string?)
    if self.initialized then
        self.logger:warn("MainModule already initialized")
        return true, "Already initialized"
    end
    
    self.logger:info("🚀 Initializing MainModule...")
    
    -- Initialize system status tracking
    for _, systemName in ipairs(systemsToLoad) do
        self.systemStatus[systemName] = {
            name = systemName,
            loaded = false,
            initialized = false,
            started = false,
            error = nil,
            dependencies = {},
            loadTime = nil,
            initTime = nil,
            startTime = nil,
            lastError = nil
        }
    end
    
    -- Load and initialize each system
    for _, systemName in ipairs(systemsToLoad) do
        local status = self.systemStatus[systemName]
        local loadStart = os.clock()
        
        self.logger:info("📦 Loading system: %s", systemName)
        
        -- Find the system script
        local systemScript = script.Parent.systems:FindFirstChild(systemName)
        if not systemScript or not systemScript:IsA("ModuleScript") then
            status.error = "System script not found"
            self.logger:error("  ❌ System script not found: %s", systemName)
            if self.config.strictMode then
                return false, string.format("System script not found: %s", systemName)
            end
            goto continue
        end
        
        -- Load the system
        local success, system = xpcall(function()
            return require(systemScript)
        end, function(err)
            return debug.traceback(tostring(err), 2)
        end)
        
        if not success then
            status.error = tostring(system)
            status.lastError = os.time()
            self.logger:error("  ❌ Failed to load system '%s': %s", systemName, tostring(system))
            if self.config.strictMode then
                return false, string.format("Failed to load system '%s': %s", systemName, tostring(system))
            end
            goto continue
        end
        
        -- Validate the system
        local valid, validationError = validateSystem(system, systemName)
        if not valid then
            status.error = validationError
            status.lastError = os.time()
            self.logger:error("  ❌ Invalid system '%s': %s", systemName, validationError or "Unknown error")
            if self.config.strictMode then
                return false, string.format("Invalid system '%s': %s", systemName, validationError or "Unknown error")
            end
            goto continue
        end
        
        -- Store the system
        self.systems[systemName] = system
        status.loaded = true
        status.loadTime = os.clock() - loadStart
        status.dependencies = system.dependencies or {}
        
        -- Track dependencies
        for _, depName in ipairs(status.dependencies) do
            self._private.systemDependencies[systemName] = self._private.systemDependencies[systemName] or {}
            table.insert(self._private.systemDependencies[systemName], depName)
            
            self._private.reverseDependencies[depName] = self._private.reverseDependencies[depName] or {}
            table.insert(self._private.reverseDependencies[depName], systemName)
        end
        
        self.logger:info("  ✅ Successfully loaded system: %s (v%s)", systemName, system.version or "1.0.0")
        
        ::continue::
    end
    
    -- Initialize systems in order
    for _, systemName in ipairs(systemsToLoad) do
        local system = self.systems[systemName]
        local status = self.systemStatus[systemName]
        
        if not system or not status.loaded then
            goto continue_init
        end
        
        self.logger:info("⚙️  Initializing system: %s", systemName)
        
        -- Initialize the system with retries
        local initSuccess, initError
        for attempt = 1, self.config.maxInitRetries do
            initSuccess, initError = initializeSystem(self, systemName, system)
            
            if initSuccess then
                self.logger:info("  ✅ Successfully initialized system: %s (%.3fs)", 
                    systemName, status.initTime or 0)
                break
            else
                status.lastError = os.time()
                status.error = tostring(initError)
                
                if attempt < self.config.maxInitRetries then
                    self.logger:warn("  ⚠️  Attempt %d/%d failed for system '%s': %s. Retrying...",
                        attempt, self.config.maxInitRetries, systemName, tostring(initError))
                    task.wait(self.config.initRetryDelay)
                else
                    self.logger:error("  ❌ Failed to initialize system '%s' after %d attempts: %s",
                        systemName, self.config.maxInitRetries, tostring(initError))
                    
                    if self.config.strictMode then
                        return false, string.format("Failed to initialize system '%s': %s", 
                            systemName, tostring(initError))
                    end
                end
            end
        end
        
        ::continue_init::
    end
    
    self.initialized = true
    
    -- Verify all systems were initialized
    local allValid, errors = self:verifySystems()
    if not allValid then
        self.logger:warn("⚠️  Not all systems initialized successfully")
        for sysName, err in pairs(errors or {}) do
            self.logger:warn("  - %s: %s", sysName, tostring(err))
        end
    end
    
    self.logger:info("🚀 MainModule initialization complete (%.3fs)", os.clock() - self._initStartTime)
    
    -- Auto-start if configured
    if self.config.autoStart then
        return self:start()
    end
    
    return true, "Initialized successfully"
end

function MainModule:start(): (boolean, string?)
    if not self.initialized then
        local success, error = self:init()
        if not success then
            return false, string.format("Initialization failed: %s", tostring(error))
        end
    end
    
    if self.started then
        self.logger:warn("MainModule already started")
        return true, "Already started"
    end
    
    self.logger:info("🚀 Starting MainModule...")
    
    -- Start systems in order
    for _, systemName in ipairs(systemsToLoad) do
        local system = self.systems[systemName]
        local status = self.systemStatus[systemName]
        
        if not system or not status.initialized or status.started then
            goto continue_start
        end
        
        -- Skip systems without a start function
        if type(system.start) ~= "function" then
            status.started = true
            goto continue_start
        end
        
        self.logger:info("▶️  Starting system: %s", systemName)
        
        local startSuccess, startError = startSystem(self, systemName, system)
        if not startSuccess then
            status.error = tostring(startError)
            status.lastError = os.time()
            self.logger:error("  ❌ Failed to start system '%s': %s", systemName, tostring(startError))
            
            if self.config.strictMode then
                return false, string.format("Failed to start system '%s': %s", 
                    systemName, tostring(startError))
            end
        else
            self.logger:info("  ✅ Successfully started system: %s (%.3fs)", 
                systemName, status.startTime or 0)
        end
        
        ::continue_start::
    end
    
    self.started = true
    self.logger:info("🚀 MainModule started successfully")
    
    return true, "Started successfully"
end

-- Return the module
return MainModule
