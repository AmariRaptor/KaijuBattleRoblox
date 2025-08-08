--!strict
-- RunGameLoopTest.luau
-- Self-contained test script for EnhancedMainModule game loop

local RunService = game:GetService("RunService")

-- Create a mock EnhancedMainModule for testing
local EnhancedMainModule = {
    logger = {
        levels = {
            TRACE = 0,
            DEBUG = 1,
            INFO = 2,
            WARN = 3,
            ERROR = 4,
            FATAL = 5
        },
        minLevel = 1, -- DEBUG level
        
        setLevel = function(self, level)
            self.minLevel = level
        end,
        
        log = function(self, level, message, ...)
            if level < self.minLevel then return end
            
            local levelNames = {
                [self.levels.TRACE] = "TRACE",
                [self.levels.DEBUG] = "DEBUG",
                [self.levels.INFO] = "INFO",
                [self.levels.WARN] = "WARN",
                [self.levels.ERROR] = "ERROR",
                [self.levels.FATAL] = "FATAL"
            }
            
            local levelName = levelNames[level] or "UNKNOWN"
            print(string.format("[%s] %s", levelName, message:format(...)))
        end,
        
        trace = function(self, ...) self:log(self.levels.TRACE, ...) end,
        debug = function(self, ...) self:log(self.levels.DEBUG, ...) end,
        info = function(self, ...) self:log(self.levels.INFO, ...) end,
        warn = function(self, ...) self:log(self.levels.WARN, ...) end,
        error = function(self, ...) self:log(self.levels.ERROR, ...) end,
        fatal = function(self, ...) self:log(self.levels.FATAL, ...) end
    },
    
    systems = {},
    systemStatus = {},
    initialized = false,
    started = false,
    
    registerSystem = function(self, name, system)
        if self.systems[name] then
            warn(string.format("System '%s' already registered", name))
            return false
        end
        
        self.systems[name] = system
        self.systemStatus[name] = {
            name = name,
            loaded = true,
            initialized = false,
            started = false,
            error = nil
        }
        
        self.logger:debug("Registered system: %s", name)
        return true
    end,
    
    init = function(self)
        if self.initialized then
            return true, "Already initialized"
        end
        
        self.logger:info("Initializing EnhancedMainModule...")
        
        -- Initialize all registered systems
        for name, system in pairs(self.systems) do
            if system.init then
                self.logger:debug("Initializing system: %s", name)
                local success, err = system:init()
                if not success then
                    self.logger:error("Failed to initialize system %s: %s", name, tostring(err))
                    self.systemStatus[name].error = tostring(err)
                else
                    self.systemStatus[name].initialized = true
                end
            end
        end
        
        self.initialized = true
        self.logger:info("EnhancedMainModule initialized successfully")
        return true
    end,
    
    start = function(self)
        if self.started then
            return true, "Already started"
        end
        
        self.logger:info("Starting EnhancedMainModule...")
        
        -- Start all registered systems
        for name, system in pairs(self.systems) do
            if system.start and self.systemStatus[name].initialized and not self.systemStatus[name].started then
                self.logger:debug("Starting system: %s", name)
                local success, err = system:start()
                if not success then
                    self.logger:error("Failed to start system %s: %s", name, tostring(err))
                    self.systemStatus[name].error = tostring(err)
                else
                    self.systemStatus[name].started = true
                end
            end
        end
        
        self.started = true
        self.logger:info("EnhancedMainModule started successfully")
        return true
    end,
    
    getSystem = function(self, name)
        return self.systems[name]
    end
}

-- Create a test game system with a simple game loop
local TestGameSystem = {}
TestGameSystem.__index = TestGameSystem

function TestGameSystem.new()
    local self = setmetatable({
        name = "TestGameSystem",
        version = "1.0.0",
        running = false,
        updateCount = 0,
        lastUpdateTime = 0,
        updateInterval = 1/30, -- Target 30 FPS
    }, TestGameSystem)
    
    return self
end

function TestGameSystem:init()
    print("🔄 Initializing TestGameSystem...")
    self.initialized = true
    return true
end

function TestGameSystem:start()
    if self.running then return true end
    
    print("🚀 Starting TestGameSystem game loop...")
    self.running = true
    self.lastUpdateTime = os.clock()
    
    -- Start the game loop
    self.heartbeatConnection = RunService.Heartbeat:Connect(function(deltaTime)
        self:update(deltaTime)
    end)
    
    return true
end

function TestGameSystem:stop()
    if not self.running then return true end
    
    print("🛑 Stopping TestGameSystem game loop...")
    self.running = false
    
    if self.heartbeatConnection then
        self.heartbeatConnection:Disconnect()
        self.heartbeatConnection = nil
    end
    
    return true
end

function TestGameSystem:update(deltaTime: number)
    if not self.running then return end
    
    -- Simple game loop logic
    local currentTime = os.clock()
    local frameTime = currentTime - (self.lastUpdateTime > 0 and self.lastUpdateTime or currentTime)
    
    -- Only update at the target interval
    if frameTime >= self.updateInterval then
        self.updateCount += 1
        self.lastUpdateTime = currentTime
        
        -- Simulate game logic
        if self.updateCount % 30 == 0 then  -- Log every ~second at 30 FPS
            print(string.format("🕒 Update #%d | FPS: %.1f", 
                self.updateCount, 
                1 / frameTime
            ))
        end
    end
end

-- Main test function
local function runGameLoopTest()
    print("\n=== Starting Game Loop Test ===")
    
    -- Create and register the test system
    local testSystem = TestGameSystem.new()
    local registered = EnhancedMainModule:registerSystem("TestGameSystem", testSystem)
    
    if not registered then
        warn("❌ Failed to register TestGameSystem")
        return false
    end
    
    -- Initialize the EnhancedMainModule
    local initSuccess, initError = EnhancedMainModule:init()
    if not initSuccess then
        warn("❌ EnhancedMainModule initialization failed:", initError)
        return false
    end
    
    -- Start the EnhancedMainModule (which should start our game system)
    local startSuccess, startError = EnhancedMainModule:start()
    if not startSuccess then
        warn("❌ Failed to start EnhancedMainModule:", startError)
        return false
    end
    
    print("\n✅ Game loop is now running!")
    print("   - The test will run for 5 seconds")
    print("   - Press the 'Stop' button in Roblox Studio to end the test early\n")
    
    -- Let the game loop run for a while
    local testDuration = 5 -- seconds
    local startTime = os.clock()
    
    -- Keep the script alive
    while os.clock() - startTime < testDuration do
        RunService.Heartbeat:Wait()
    end
    
    -- Stop the game loop
    testSystem:stop()
    
    -- Print final stats
    local totalTime = os.clock() - startTime
    local avgFPS = testSystem.updateCount / totalTime
    
    print("\n=== Test Complete ===")
    print(string.format("Total Updates: %d", testSystem.updateCount))
    print(string.format("Test Duration: %.2f seconds", totalTime))
    print(string.format("Average FPS: %.1f", avgFPS))
    
    return true
end

-- Run the test
local success, err = pcall(runGameLoopTest)
if not success then
    warn("❌ Game loop test failed:", err)
end

return success
