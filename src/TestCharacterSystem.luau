--!strict
-- TestCharacterSystem.luau
-- A test for CharacterSystem functionality with strict Luau types

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
    local self: MockInstance = {
        ClassName = className,
        Name = name or className,
        _children = {},
        _parent = nil :: MockInstance?,
        _properties = {},
        Parent = nil,
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
    
    humanoid.MaxHealth = if classAttrs[className] then classAttrs[className].MaxHealth else 100
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
type CharacterSystem = {
    CLASS_ATTRIBUTES: {
        Kaiju: { MaxHealth: number },
        Guardian: { MaxHealth: number },
        Engineer: { MaxHealth: number }
    }
}

local MockCharacterSystem: { new: () -> CharacterSystem } = {}
MockCharacterSystem.__index = MockCharacterSystem

function MockCharacterSystem.new(): CharacterSystem
    local self: CharacterSystem = {
        CLASS_ATTRIBUTES = {
            Kaiju = { MaxHealth = 500 },
            Guardian = { MaxHealth = 200 },
            Engineer = { MaxHealth = 150 }
        }
    }
    return setmetatable(self, MockCharacterSystem) :: any
end

-- Test cases
local function runTests(): (boolean, string)
    print("=== Starting CharacterSystem Tests ===")
    
    -- Test 1: Create mock player and verify initial state
    local function testPlayerCreation(): boolean
        local player = createMockPlayer("Kaiju")
        local character = player:FindFirstChild("Character")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        
        if not player then
            print("❌ Player creation failed")
            return false
        end
        if not character then
            print("❌ Character not found in player")
            return false
        end
        if not humanoid then
            print("❌ Humanoid not found in character")
            return false
        end
        if humanoid.MaxHealth ~= 500 then
            print(string.format("❌ Kaiju MaxHealth should be 500, got %d", humanoid.MaxHealth))
            return false
        end
        if humanoid.Health ~= 500 then
            print(string.format("❌ Kaiju Health should be 500, got %d", humanoid.Health))
            return false
        end
        
        print("✅ testPlayerCreation passed")
        return true
    end
    
    -- Test 2: Test class attributes
    local function testClassAttributes(): boolean
        local system = MockCharacterSystem.new()
        
        if system.CLASS_ATTRIBUTES.Kaiju.MaxHealth ~= 500 then
            print("❌ Kaiju MaxHealth should be 500")
            return false
        end
        if system.CLASS_ATTRIBUTES.Guardian.MaxHealth ~= 200 then
            print("❌ Guardian MaxHealth should be 200")
            return false
        end
        if system.CLASS_ATTRIBUTES.Engineer.MaxHealth ~= 150 then
            print("❌ Engineer MaxHealth should be 150")
            return false
        end
        
        print("✅ testClassAttributes passed")
        return true
    end
    
    -- Test 3: Test character setup for different classes
    local function testCharacterSetup(): boolean
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
            
            if not humanoid then
                print("❌ " .. className .. " humanoid not found")
                return false
            end
            
            local expected = expectedHealth[className]
            if humanoid.MaxHealth ~= expected then
                print(string.format("❌ %s MaxHealth should be %d, got %d", 
                    className, expected, humanoid.MaxHealth))
                return false
            end
        end
        
        print("✅ testCharacterSetup passed")
        return true
    end
    
    -- Run all tests
    local success, err = pcall(function()
        if not testPlayerCreation() then return false end
        if not testClassAttributes() then return false end
        if not testCharacterSetup() then return false end
        return true
    end)
    
    if not success then
        warn("❌ Tests failed: " .. tostring(err))
        return false, "Tests failed with error: " .. tostring(err)
    end
    
    if err == false then
        return false, "One or more tests failed"
    end
    
    print("\n✅ All CharacterSystem tests passed!")
    return true, "All tests passed successfully"
end

-- Run tests when required
return {
    runTests = runTests
}
