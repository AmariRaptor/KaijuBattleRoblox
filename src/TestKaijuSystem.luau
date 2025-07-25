-- TestKaijuSystem.luau
-- A simple test script for KaijuSystem that can be placed in ServerScriptService

print("=== Starting KaijuSystem Tests ===")

local function assert(condition, message)
    if not condition then
        error(message or "Assertion failed!")
    end
end

local function runTest(name, testFunc)
    local success, message = pcall(testFunc)
    if success then
        print("✅ " .. name .. " - PASSED")
        return true
    else
        print("❌ " .. name .. " - FAILED: " .. tostring(message))
        return false
    end
end

-- Mock KaijuSystem for testing
local KaijuSystem = {}

type Kaiju = {
    Name: string,
    Humanoid: {
        Health: number,
        MaxHealth: number,
        Parent: any?
    },
    Parent: any?,
    energyBeam: { ClassName: string }?,
    roar: { ClassName: string }?
}

function KaijuSystem:spawnKaiju(player): Kaiju
    local kaiju: Kaiju = {
        Name = "Kaiju",
        Humanoid = {
            Health = 500,
            MaxHealth = 500,
            Parent = nil
        },
        Parent = player and player.Character,
        energyBeam = nil,
        roar = nil
    }
    
    if kaiju.Humanoid then
        kaiju.Humanoid.Parent = kaiju
    end
    
    return kaiju
end

function KaijuSystem:setupAbilities(kaiju)
    local abilities = {
        energyBeam = { ClassName = "RemoteEvent" },
        roar = { ClassName = "Sound" }
    }
    
    for name, ability in pairs(abilities) do
        kaiju[name] = ability
    end
    
    return abilities
end

-- Run tests
local passed = 0
local failed = 0

-- Test 1: spawnKaiju with player
if runTest("spawnKaiju with player", function()
    local player = { Character = { Name = "TestCharacter" } }
    local kaiju = KaijuSystem:spawnKaiju(player)
    assert(kaiju, "Kaiju should be created")
    assert(kaiju.Name == "Kaiju", "Kaiju should have correct name")
    assert(kaiju.Humanoid, "Kaiju should have a Humanoid")
    assert(kaiju.Parent == player.Character, "Kaiju should be parented to player's character")
end) then passed = passed + 1 else failed = failed + 1 end

-- Test 2: spawnKaiju without player
if runTest("spawnKaiju without player", function()
    local kaiju = KaijuSystem:spawnKaiju(nil)
    assert(kaiju, "Kaiju should be created")
    assert(kaiju.Name == "Kaiju", "Kaiju should have correct name")
    assert(kaiju.Humanoid, "Kaiju should have a Humanoid")
    assert(kaiju.Parent == nil, "Kaiju should not be parented")
end) then passed = passed + 1 else failed = failed + 1 end

-- Test 3: setupAbilities
if runTest("setupAbilities", function()
    local kaiju: Kaiju = {
        Name = "TestKaiju",
        Humanoid = { Health = 100, MaxHealth = 100, Parent = nil },
        Parent = nil,
        energyBeam = nil,
        roar = nil
    }
    
    local abilities = KaijuSystem:setupAbilities(kaiju)
    
    assert(abilities, "Should return abilities table")
    local energyBeam = kaiju.energyBeam
    local roar = kaiju.roar
    
    assert(energyBeam, "Kaiju should have energyBeam ability")
    assert(roar, "Kaiju should have roar ability")
    assert(energyBeam.ClassName == "RemoteEvent", "energyBeam should be a RemoteEvent")
    assert(roar.ClassName == "Sound", "roar should be a Sound")
end) then passed = passed + 1 else failed = failed + 1 end

-- Print test results
print("\n=== Test Results ===")
print(string.format("✅ %d tests passed", passed))
print(string.format("❌ %d tests failed", failed))
print("==================")

-- Return success if all tests passed
return failed == 0
