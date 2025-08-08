--!strict
-- TestGameLoop.luau
-- Test script to verify the EnhancedMainModule's game loop functionality

local RunService = game:GetService("RunService")

-- Load the enhanced MainModule
local success, MainModule = pcall(function()
    return require(script.Parent.EnhancedMainModule)
end)

if not success then
    warn("❌ Failed to load EnhancedMainModule:")
    warn(MainModule)
    return
end

print("✅ Successfully loaded EnhancedMainModule")

-- Configure logger to show debug messages
MainModule.logger:setLevel(MainModule.logger.levels.DEBUG)

-- Create a test system with game loop functionality
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
    if self.running then return end
    
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
    if not self.running then return end
    
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
    local frameTime = currentTime - self.lastUpdateTime
    
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
    local registered = MainModule:registerSystem("TestGameSystem", testSystem)
    
    if not registered then
        warn("❌ Failed to register TestGameSystem")
        return false
    end
    
    -- Initialize the MainModule
    local initSuccess, initError = MainModule:init()
    if not initSuccess then
        warn("❌ MainModule initialization failed:", initError)
        return false
    end
    
    -- Start the MainModule (which should start our game system)
    local startSuccess, startError = MainModule:start()
    if not startSuccess then
        warn("❌ Failed to start MainModule:", startError)
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
