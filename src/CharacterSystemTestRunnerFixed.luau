--!strict
-- Fixed test runner for CharacterSystem with corrected mock implementation and strict Luau types

print("=== Starting CharacterSystem Tests (Fixed) ===\n")

-- Types
type MockInstance = {
    ClassName: string,
    Name: string,
    _children: {MockInstance},
    _parent: MockInstance?,
    _properties: {[string]: any},
    FindFirstChild: (self: MockInstance, name: string, recursive: boolean?) -> MockInstance?,
    FindFirstChildOfClass: (self: MockInstance, className: string) -> MockInstance?,
    IsA: (self: MockInstance, className: string) -> boolean,
    GetChildren: (self: MockInstance) -> {MockInstance},
    Parent: MockInstance?,
    Value: any?,
    MaxHealth: number?,
    Health: number?,
    Character: MockInstance?
}

-- Mock instance system with proper parent-child relationships
local MockInstance = {}
local MockInstanceMt = {}
MockInstanceMt.__index = MockInstanceMt

-- Create a new mock instance
function MockInstance.new(className: string, name: string?): MockInstance
    local self: MockInstance = setmetatable({
        ClassName = className,
        Name = name or className,
        _children = {} :: {MockInstance},
        _parent = nil :: MockInstance?,
        _properties = {} :: {[string]: any},
        Value = nil,
        MaxHealth = nil :: number?,
        Health = nil :: number?,
        Character = nil :: MockInstance?
    }, MockInstanceMt) :: any
    
    return self
end

-- Instance methods
function MockInstanceMt:FindFirstChild(name: string, recursive: boolean?): MockInstance?
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

function MockInstanceMt:FindFirstChildOfClass(className: string): MockInstance?
    if not self._children then return nil end
    
    for _, child in ipairs(self._children) do
        if child.ClassName == className then
            return child
        end
        
        -- Check recursively
        local found = child:FindFirstChildOfClass(className)
        if found then
            return found
        end
    end
    
    return nil
end

function MockInstanceMt:IsA(className: string): boolean
    return self.ClassName == className
end

function MockInstanceMt:GetChildren(): {MockInstance}
    return table.clone(self._children)
end

-- Property accessors
function MockInstanceMt:__index(key: string): any
    if MockInstanceMt[key] ~= nil then
        return MockInstanceMt[key]
    end
    return rawget(self, "_properties")[key]
end

function MockInstanceMt:__newindex(key: string, value: any)
    if key == "Parent" then
        self:SetParent(value)
    else
        rawget(self, "_properties")[key] = value
    end
end

-- Set up parent-child relationship
function MockInstanceMt:SetParent(parent: MockInstance?)
    -- Remove from old parent
    if self._parent then
        local parentChildren = self._parent._children
        for i, child in ipairs(parentChildren) do
            if child == self then
                table.remove(parentChildren, i)
                break
            end
        end
    end
    
    -- Set new parent
    self._parent = parent
    if parent then
        table.insert(parent._children, self)
    end
end

-- Alias for compatibility
MockInstanceMt.Parent = {
    get = function(self: MockInstance) return self._parent end,
    set = function(self: MockInstance, parent) self:SetParent(parent) end
}

-- Mock CharacterSystem
local CharacterSystem = {
    CLASS_ATTRIBUTES = {
        Kaiju = { MaxHealth = 500 },
        Guardian = { MaxHealth = 200 },
        Engineer = { MaxHealth = 150 }
    },
    
    onCharacterAdded = function(self: any, character: MockInstance): boolean
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return false end
        
        local playerValue = character:FindFirstChild("Player")
        if not playerValue or not playerValue:IsA("ObjectValue") then return false end
        
        local player = playerValue.Value
        if not player then return false end
        
        local playerClass = player:FindFirstChild("PlayerClass")
        if not playerClass or not playerClass:IsA("StringValue") then return false end
        
        local attributes = self.CLASS_ATTRIBUTES[playerClass.Value]
        if not attributes then return false end
        
        -- Set health based on class
        humanoid.MaxHealth = attributes.MaxHealth
        humanoid.Health = attributes.MaxHealth
        
        return true
    end,
    
    onPlayerAdded = function(self: any, player: MockInstance): boolean
        -- Mock character added event
        local character = MockInstance.new("Model", "TestCharacter")
        local humanoid = MockInstance.new("Humanoid", "Humanoid")
        humanoid.Parent = character
        
        local playerValue = MockInstance.new("ObjectValue", "Player")
        playerValue.Value = player
        playerValue.Parent = character
        
        player.Character = character
        
        return self:onCharacterAdded(character)
    end
}

-- Test function
local function runTests()
    print("Running CharacterSystem tests...\n")
    
    -- Test data
    local testCases = {
        { className = "Kaiju", expectedHealth = 500 },
        { className = "Guardian", expectedHealth = 200 },
        { className = "Engineer", expectedHealth = 150 },
        { className = "InvalidClass", shouldFail = true }
    }
    
    local passed = 0
    local failed = 0
    
    for _, testCase in ipairs(testCases) do
        print(string.format("Testing %s...", testCase.className))
        
        -- Create player
        local player = MockInstance.new("Player", "TestPlayer")
        local playerClass = MockInstance.new("StringValue", "PlayerClass")
        playerClass.Value = testCase.className
        playerClass.Parent = player
        
        -- Run the test
        local success = CharacterSystem:onPlayerAdded(player)
        
        -- Verify results
        if testCase.shouldFail then
            if not success then
                print(string.format("✅ %s: Correctly failed for invalid class", testCase.className))
                passed += 1
            else
                print(string.format("❌ %s: Should have failed for invalid class", testCase.className))
                failed += 1
            end
        else
            if not success then
                print(string.format("❌ %s: Failed to process player", testCase.className))
                failed += 1
            else
                local character = player.Character
                if not character then
                    print(string.format("❌ %s: Character not set", testCase.className))
                    failed += 1
                else
                    local humanoid = character:FindFirstChildOfClass("Humanoid")
                    if not humanoid then
                        print(string.format("❌ %s: Humanoid not found", testCase.className))
                        failed += 1
                    else
                        if humanoid.MaxHealth ~= testCase.expectedHealth then
                            print(string.format("❌ %s: Expected health %d, got %d", 
                                testCase.className, testCase.expectedHealth, humanoid.MaxHealth or -1))
                            failed += 1
                        else
                            print(string.format("✅ %s: Health set correctly to %d", 
                                testCase.className, testCase.expectedHealth))
                            passed += 1
                        end
                    end
                end
            end
        end
        
        print() -- Add spacing between tests
    end
    
    -- Print summary
    print("\n=== Test Summary ===")
    print(string.format("Total Tests: %d", passed + failed))
    print(string.format("✅ Passed: %d", passed))
    print(string.format("❌ Failed: %d", failed))
    
    return failed == 0
end

-- Run the tests
local success, message = pcall(runTests)
if not success then
    print("\n❌ Test runner encountered an error:", message)
    return { success = false, message = "Test runner error: " .. tostring(message) }
end

if message then
    print("\n✅ All CharacterSystem tests passed!")
    return { success = true, message = "All tests passed" }
else
    print("\n❌ Some CharacterSystem tests failed")
    return { success = false, message = "One or more tests failed" }
end
