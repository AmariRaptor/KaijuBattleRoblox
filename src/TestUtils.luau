--!strict
-- Test utilities for Roblox testing

type InstanceLike = {
    Name: string,
    ClassName: string,
    Parent: InstanceLike?,
    FindFirstChild: (self: InstanceLike, name: string, recursive: boolean?) -> InstanceLike?,
    FindFirstChildOfClass: (self: InstanceLike, className: string) -> InstanceLike?,
    IsA: (self: InstanceLike, className: string) -> boolean,
    GetChildren: (self: InstanceLike) -> {InstanceLike},
    GetFullName: (self: InstanceLike) -> string,
    new: (className: string) -> InstanceLike,
    
    -- Additional properties for testing
    _children: {InstanceLike}?,
    _parent: InstanceLike?,
    _properties: {[string]: any}?
}

local TestUtils = {}

-- Create a mock Roblox instance
function TestUtils.createMockInstance(className: string, name: string): InstanceLike
    local instance: InstanceLike = {
        Name = name,
        ClassName = className,
        _children = {},
        _properties = {}
    }
    
    function instance:FindFirstChild(name: string, recursive: boolean?): InstanceLike?
        if not self._children then return nil end
        
        for _, child in ipairs(self._children) do
            if child.Name == name then
                return child
            end
            
            if recursive then
                local found = child:FindFirstChild(name, true)
                if found then
                    return found
                end
            end
        end
        
        return nil
    end
    
    function instance:FindFirstChildOfClass(className: string): InstanceLike?
        if not self._children then return nil end
        
        for _, child in ipairs(self._children) do
            if child.ClassName == className then
                return child
            end
        end
        
        return nil
    end
    
    function instance:IsA(className: string): boolean
        return self.ClassName == className
    end
    
    function instance:GetChildren(): {InstanceLike}
        return self._children or {}
    end
    
    function instance:GetFullName(): string
        if self.Parent and self.Parent ~= game then
            return self.Parent:GetFullName() .. "." .. self.Name
        end
        return self.Name
    end
    
    -- Set up metatable for property access
    return setmetatable(instance, {
        __index = function(t, k)
            -- Check properties first
            if t._properties and t._properties[k] ~= nil then
                return t._properties[k]
            end
            
            -- Then check methods and fields
            return rawget(instance, k)
        end,
        
        __newindex = function(t, k, v)
            -- Store properties in the properties table
            if not t._properties then
                t._properties = {}
            end
            t._properties[k] = v
        end
    })
end

-- Create a test character with the given class
function TestUtils.createTestCharacter(className: string, health: number): InstanceLike
    -- Create player
    local player = TestUtils.createMockInstance("Model", className .. "Player")
    
    -- Add PlayerClass
    local playerClass = TestUtils.createMockInstance("StringValue", "PlayerClass")
    playerClass.Value = className
    playerClass.Parent = player
    
    -- Create character
    local character = TestUtils.createMockInstance("Model", className .. "Character")
    
    -- Add humanoid
    local humanoid = TestUtils.createMockInstance("Humanoid", "Humanoid")
    humanoid.MaxHealth = 100
    humanoid.Health = 100
    humanoid.Parent = character
    
    -- Link player to character
    local playerRef = TestUtils.createMockInstance("ObjectValue", "Player")
    playerRef.Value = player
    playerRef.Parent = character
    
    return character
end

-- Mock the CharacterSystem for testing
function TestUtils.createMockCharacterSystem()
    return {
        CLASS_ATTRIBUTES = {
            Kaiju = { MaxHealth = 500 },
            Guardian = { MaxHealth = 200 },
            Engineer = { MaxHealth = 150 }
        },
        
        onCharacterAdded = function(self: any, character: InstanceLike): boolean
            local player = character:FindFirstChild("Player")
            if not player then return false end
            
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if not humanoid then return false end
            
            local playerClass = player:FindFirstChild("PlayerClass")
            if not playerClass or not playerClass:IsA("StringValue") then 
                return false 
            end
            
            local attributes = self.CLASS_ATTRIBUTES[playerClass.Value]
            if not attributes then return false end
            
            humanoid.MaxHealth = attributes.MaxHealth
            humanoid.Health = attributes.MaxHealth
            return true
        end,
        
        onPlayerAdded = function(self: any, player: InstanceLike): boolean
            if player.Character then
                return self:onCharacterAdded(player.Character)
            end
            return false
        end
    }
end

return TestUtils
