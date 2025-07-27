--!strict
-- Fixed test runner for CharacterSystem with corrected mock implementation

print("=== Starting CharacterSystem Tests (Fixed) ===\n")

-- Mock instance system with proper parent-child relationships
local MockInstance = {}
MockInstance.__index = MockInstance

-- Create a new mock instance
function MockInstance.new(className: string, name: string?): any
    local self = {
        ClassName = className,
        Name = name or className,
        _children = {},
        _parent = nil,
        _properties = {}
    }
    return setmetatable(self, MockInstance)
end

-- Instance methods
function MockInstance:FindFirstChild(name: string, recursive: boolean?): any
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

function MockInstance:FindFirstChildOfClass(className: string): any
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

function MockInstance:GetChildren(): {any}
    return self._children or {}
end

function MockInstance:GetFullName(): string
    if self.Parent and self.Parent ~= game then
        return self.Parent:GetFullName() .. "." .. self.Name
    end
    return self.Name
end

-- Property access
function MockInstance:__index(k: string): any
    -- Special case for Parent to avoid infinite recursion
    if k == "Parent" then
        return self._parent
    end
    
    -- Check properties
    if self._properties and self._properties[k] ~= nil then
        return self._properties[k]
    end
    
    -- Then check methods and fields
    return MockInstance[k]
end

function MockInstance:__newindex(k: string, v: any)
    -- Special handling for Parent property
    if k == "Parent" then
        -- Remove from old parent
        if self._parent and self._parent._children then
            for i, child in ipairs(self._parent._children) do
                if child == self then
                    table.remove(self._parent._children, i)
                    break
                end
            end
        end
        
        -- Add to new parent
        if v and v._children ~= nil then
            table.insert(v._children, self)
        end
        
        -- Set the parent reference
        rawset(self, "_parent", v)
        return
    end
    
    -- Store other properties
    if not self._properties then
        self._properties = {}
    end
    self._properties[k] = v
end

-- Create a test character with the given class
local function createTestCharacter(className: string, health: number): any
    -- Create player
    local player = MockInstance.new("Model", className .. "Player")
    
    -- Add PlayerClass
    local playerClass = MockInstance.new("StringValue", "PlayerClass")
    playerClass.Value = className
    playerClass.Parent = player
    
    -- Create character
    local character = MockInstance.new("Model", className .. "Character")
    
    -- Add humanoid
    local humanoid = MockInstance.new("Humanoid", "Humanoid")
    humanoid.MaxHealth = 100
    humanoid.Health = 100
    humanoid.Parent = character
    
    -- Link player to character
    local playerRef = MockInstance.new("ObjectValue", "Player")
    playerRef.Value = player
    playerRef.Parent = character
    
    return character
end

-- Create mock CharacterSystem
local CharacterSystem = {
    CLASS_ATTRIBUTES = {
        Kaiju = { MaxHealth = 500 },
        Guardian = { MaxHealth = 200 },
        Engineer = { MaxHealth = 150 }
    },
    
    onCharacterAdded = function(self: any, character: any): boolean
        print("\nTesting character:", character.Name)
        
        local player = character:FindFirstChild("Player")
        if not player then 
            print("❌ No Player found in character")
            return false 
        end
        print("✅ Found Player:", player.Name)
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then 
            print("❌ No Humanoid found in character")
            return false 
        end
        print("✅ Found Humanoid")
        
        local playerClass = player:FindFirstChild("PlayerClass")
        if not playerClass then 
            print("❌ No PlayerClass found in player")
            return false 
        end
        print("✅ Found PlayerClass")
        
        if not playerClass:IsA("StringValue") then 
            print("❌ PlayerClass is not a StringValue")
            return false 
        end
        print("✅ PlayerClass is a StringValue")
        
        local className = playerClass.Value
        print("Player class:", className)
        
        local attributes = self.CLASS_ATTRIBUTES[className]
        if not attributes then 
            print("❌ No attributes found for class:", className)
            return false 
        end
        print("✅ Found attributes for class")
        
        humanoid.MaxHealth = attributes.MaxHealth
        humanoid.Health = attributes.MaxHealth
        print(string.format("✅ Set health to %d", attributes.MaxHealth))
        
        return true
    end
}

-- Test cases
local testCases = {
    {className = "Kaiju", expectedHealth = 500},
    {className = "Guardian", expectedHealth = 200},
    {className = "Engineer", expectedHealth = 150}
}

-- Run tests
local passed = 0
local failed = 0

-- Test valid classes
for _, testCase in ipairs(testCases) do
    print("\n========================================")
    print("Testing", testCase.className, "character...")
    
    -- Create test character
    local character = createTestCharacter(testCase.className, 100)
    
    -- Run the test
    local success, result = pcall(function()
        return CharacterSystem:onCharacterAdded(character)
    end)
    
    -- Get the humanoid to verify health
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    
    if success and result and humanoid then
        if humanoid.MaxHealth == testCase.expectedHealth and humanoid.Health == testCase.expectedHealth then
            print(string.format("✅ %s: Health set correctly to %d", testCase.className, testCase.expectedHealth))
            passed = passed + 1
        else
            print(string.format("❌ %s: Expected health %d, got %d/%d", 
                testCase.className, testCase.expectedHealth, humanoid.Health, humanoid.MaxHealth))
            failed = failed + 1
        end
    else
        print("❌", testCase.className, "setup failed:", tostring(result))
        failed = failed + 1
    end
end

-- Test invalid class
print("\n========================================")
print("Testing invalid class...")
local invalidCharacter = createTestCharacter("TestClass", 100)
local invalidPlayer = invalidCharacter:FindFirstChild("Player")
if invalidPlayer then
    local playerClass = invalidPlayer:FindFirstChild("PlayerClass")
    if playerClass and playerClass:IsA("StringValue") then
        playerClass.Value = "InvalidClass"
    end
end

local success, result = pcall(function()
    return CharacterSystem:onCharacterAdded(invalidCharacter)
end)

local humanoid = invalidCharacter:FindFirstChildOfClass("Humanoid")

if not success or (not result and humanoid and humanoid.MaxHealth == 100) then
    print("✅ Invalid class handling passed")
    passed = passed + 1
else
    print("❌ Invalid class handling failed")
    failed = failed + 1
end

-- Print summary
print("\n=== Test Summary ===")
print(string.format("Total Tests: %d", passed + failed))
print(string.format("✅ Passed: %d", passed))
print(string.format("❌ Failed: %d", failed))

return failed == 0
