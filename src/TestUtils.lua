-- TestUtils.lua
-- A utility module for writing tests

local TestUtils = {}

-- Assertion functions
function TestUtils.assertEquals(actual, expected, message)
    message = message or string.format("Expected %s to equal %s", tostring(actual), tostring(expected))
    if actual ~= expected then
        return false, message
    end
    return true
end

function TestUtils.assertNotEquals(actual, unexpected, message)
    message = message or string.format("Expected %s to not equal %s", tostring(actual), tostring(unexpected))
    if actual == unexpected then
        return false, message
    end
    return true
end

function TestUtils.assertTrue(condition, message)
    message = message or string.format("Expected condition to be true, got %s", tostring(condition))
    if not condition then
        return false, message
    end
    return true
end

function TestUtils.assertFalse(condition, message)
    return TestUtils.assertTrue(not condition, message or string.format("Expected condition to be false, got %s", tostring(condition)))
end

-- Mock objects
function TestUtils.createMockPlayer(name)
    return {
        Name = name or "TestPlayer",
        Character = nil,
        CharacterAdded = {
            Connect = function(_, callback)
                task.spawn(function()
                    if not game:GetService("Players"):FindFirstChild(name or "TestPlayer") then
                        local player = Instance.new("Player")
                        player.Name = name or "TestPlayer"
                        player.Parent = game:GetService("Players")
                    end
                    if callback then callback({Name = "TestCharacter"}) end
                end)
                return { Disconnect = function() end }
            end
        }
    }
end

-- Test runner utilities
function TestUtils.runTest(testFn, testName)
    testName = testName or "Unnamed Test"
    print(string.format("\n=== Running test: %s ===", testName))
    
    local success, result = pcall(testFn)
    
    if not success then
        print(string.format("❌ %s failed with error: %s", testName, tostring(result)))
        return false, "Test error: " .. tostring(result)
    end
    
    if type(result) == "table" and result.success ~= nil then
        if result.success then
            print(string.format("✅ %s passed: %s", testName, result.message or ""))
        else
            print(string.format("❌ %s failed: %s", testName, result.message or ""))
        end
        return result.success, result.message
    else
        local success = result ~= false and result ~= nil
        print(string.format("%s %s: %s", success and "✅" or "❌", testName, success and "Passed" or "Failed"))
        return success, success and "Test passed" or "Test failed"
    end
end

return TestUtils
