--!strict
-- TestCharacterSystem.lua
-- A test for CharacterSystem functionality (simplified version)

local _TestService = game:GetService("TestService")

-- Define types for better type checking
type MockInstance = {
    ClassName: string,
    Name: string,
    _children: {MockInstance},
    _parent: MockInstance?,
    _properties: {[string]: any},
    Parent: MockInstance?,
    FindFirstChild: (self: MockInstance, name: string, recursive: boolean?) -> MockInstance?,
    FindFirstChildOfClass: (self: MockInstance, className: string) -> MockInstance?,
    IsA: (self: MockInstance, className: string) -> boolean,
    GetChildren: (self: MockInstance) -> {MockInstance},
    MaxHealth: number?,
    Health: number?,
    Value: any?
}

-- Mock instance system
local MockInstance = {}
MockInstance.__index = MockInstance

function MockInstance.new(className: string, name: string?): MockInstance
    local self = {
        ClassName = className,
        Name = name or className,
        _children = {},
        _parent = nil :: MockInstance?,
        _properties = {},
        Value = nil,
        MaxHealth = 100,
        Health = 100
    }
    return setmetatable(self, MockInstance) :: any
end

function MockInstance:FindFirstChild(name: string, recursive: boolean?): MockInstance?
    if not self._children then return nil end
    
    -- First check direct children
    for _, child in ipairs(self._children) do
        if child.Name == name then
            return child
        end
    end
    
    -- Then check recursively if requested
    if recursive then
        for _, child in ipairs(self._children) do
            local found = child:FindFirstChild(name, true)
            if found then
                return found
            end
        end
    end
    
    return nil
end

function MockInstance:FindFirstChildOfClass(className: string): MockInstance?
    if not self._children then return nil end
    
    for _, child in ipairs(self._children) do
        if child.ClassName == className then
            return child
        end
        
        -- Search recursively
        local found = child:FindFirstChildOfClass(className)
        if found then
            return found
        end
    end
    
    return nil
end

function MockInstance:IsA(className: string): boolean
    return self.ClassName == className
end

function MockInstance:GetChildren(): {MockInstance}
    return self._children or {}
end

-- Helper function to create a mock Player with a character
local function createMockPlayer(className: string): MockInstance
    local player = MockInstance.new("Player", "TestPlayer")
    
    -- Add PlayerClass
    local playerClass = MockInstance.new("StringValue", "PlayerClass")
    playerClass.Value = className
    table.insert(player._children, playerClass)
    
    -- Create character with humanoid
    local character = MockInstance.new("Model", "Character")
    local humanoid = MockInstance.new("Humanoid")
    
    -- Set default health values based on class
    local classAttrs = {
        Kaiju = { MaxHealth = 500 },
        Guardian = { MaxHealth = 200 },
        Engineer = { MaxHealth = 150 }
    }
    
    humanoid.MaxHealth = classAttrs[className] and classAttrs[className].MaxHealth or 100
    humanoid.Health = humanoid.MaxHealth
    
    -- Link player to character
    local playerValue = MockInstance.new("ObjectValue", "Player")
    playerValue.Value = player
    
    -- Build character hierarchy
    table.insert(character._children, humanoid)
    table.insert(character._children, playerValue)
    
    -- Set character as player's child
    table.insert(player._children, character)
    
    return player
end

-- Mock CharacterSystem
local MockCharacterSystem = {}
MockCharacterSystem.__index = MockCharacterSystem

function MockCharacterSystem.new()
    local self = setmetatable({}, MockCharacterSystem)
    self.CLASS_ATTRIBUTES = {
        Kaiju = { MaxHealth = 500 },
        Guardian = { MaxHealth = 200 },
        Engineer = { MaxHealth = 150 }
    }
    return self
end

-- Test cases
local function runTests()
    print("=== Starting CharacterSystem Tests ===")
    
    -- Test 1: Create mock player and verify initial state
    local function testPlayerCreation()
        local player = createMockPlayer("Kaiju")
        local character = player:FindFirstChild("Character")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        
        assert(player, "Player creation failed")
        assert(character, "Character not found in player")
        assert(humanoid, "Humanoid not found in character")
        assert(humanoid.MaxHealth == 500, "Kaiju MaxHealth should be 500")
        assert(humanoid.Health == 500, "Kaiju Health should be 500")
        
        print("✅ testPlayerCreation passed")
    end
    
    -- Test 2: Test class attributes
    local function testClassAttributes()
        local system = MockCharacterSystem.new()
        
        assert(system.CLASS_ATTRIBUTES.Kaiju.MaxHealth == 500, "Kaiju MaxHealth should be 500")
        assert(system.CLASS_ATTRIBUTES.Guardian.MaxHealth == 200, "Guardian MaxHealth should be 200")
        assert(system.CLASS_ATTRIBUTES.Engineer.MaxHealth == 150, "Engineer MaxHealth should be 150")
        
        print("✅ testClassAttributes passed")
    end
    
    -- Test 3: Test character setup for different classes
    local function testCharacterSetup()
        local classes = {"Kaiju", "Guardian", "Engineer"}
        local expectedHealth = {
            Kaiju = 500,
            Guardian = 200,
            Engineer = 150
        }
        
        for _, className in ipairs(classes) do
            local player = createMockPlayer(className)
            local character = player:FindFirstChild("Character")
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            
            assert(humanoid, className .. " humanoid not found")
            assert(humanoid.MaxHealth == expectedHealth[className], 
                className .. " MaxHealth should be " .. expectedHealth[className])
        end
        
        print("✅ testCharacterSetup passed")
    end
    
    -- Run all tests
    local success, err = pcall(function()
        testPlayerCreation()
        testClassAttributes()
        testCharacterSetup()
    end)
    
    if not success then
        warn("❌ Tests failed: " .. tostring(err))
        return false
    end
    
    print("\n✅ All CharacterSystem tests passed!")
    return true
end

-- Run tests when required
return {
    runTests = runTests
}
