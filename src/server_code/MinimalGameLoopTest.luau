--!strict
-- MinimalGameLoopTest.luau
-- A minimal test script to verify game loop functionality in Roblox Studio

local RunService = game:GetService("RunService")

print("🚀 Starting Minimal Game Loop Test...")

-- Game state
local running = true
local updateCount = 0
local lastUpdateTime = os.clock()
local testDuration = 5 -- seconds
local startTime = os.clock()

-- Game loop function
local function update(deltaTime: number)
    updateCount += 1
    local currentTime = os.clock()
    local frameTime = currentTime - lastUpdateTime
    lastUpdateTime = currentTime
    
    -- Log every ~second (assuming 60 FPS)
    if updateCount % 60 == 0 then
        print(string.format("🕒 Update #%d | FPS: %.1f | Time: %.1fs", 
            updateCount, 
            1 / frameTime,
            currentTime - startTime
        ))
    end
end

-- Connect to Heartbeat for the game loop
local connection = RunService.Heartbeat:Connect(function(deltaTime)
    update(deltaTime)
    
    -- Stop after the test duration
    if os.clock() - startTime >= testDuration then
        running = false
        connection:Disconnect()
    end
end)

print("✅ Game loop started! Running for", testDuration, "seconds...")

-- Keep the script alive
while running do
    RunService.Heartbeat:Wait()
end

-- Print final stats
local totalTime = os.clock() - startTime
local avgFPS = updateCount / totalTime

print("\n=== Test Complete ===")
print(string.format("Total Updates: %d", updateCount))
print(string.format("Test Duration: %.2f seconds", totalTime))
print(string.format("Average FPS: %.1f", avgFPS))
print("✅ Test completed successfully!")
