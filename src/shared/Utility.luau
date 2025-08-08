--!strict
-- Utility.luau
-- Common utility functions for the project

local Utility = {}

type Dictionary = { [string]: any }

export type Utility = {
    safeRequire: (module: Instance) -> any?,
    safeWaitForChild: (parent: Instance, name: string, timeout: number?) -> Instance?,
    getOrCreate: (parent: Instance, className: string, name: string, properties: Dictionary?) -> Instance,
    deepCopy: (original: any) -> any,
    deepEquals: (a: any, b: any) -> boolean,
    shallowCopy: (original: { [any]: any }) -> { [any]: any },
}

-- Safely require a module with error handling
function Utility.safeRequire(module: Instance): any?
    local success, result = pcall(require, module)
    if not success then
        warn(`❌ [Utility] Failed to require {module:GetFullName()}: {result}`)
        return nil
    end
    return result
end

-- Safely wait for a child with timeout
function Utility.safeWaitForChild(parent: Instance, name: string, timeout: number?): Instance?
    local child = parent:FindFirstChild(name)
    if child then
        return child
    end
    
    if timeout then
        local success, result = pcall(function()
            return parent:WaitForChild(name, timeout)
        end)
        return if success then result else nil
    end
    
    return parent:WaitForChild(name)
end

-- Get an existing instance or create a new one if it doesn't exist
function Utility.getOrCreate(parent: Instance, className: string, name: string, properties: Dictionary?): Instance
    assert(typeof(parent) == "Instance", "Parent must be an Instance")
    assert(type(className) == "string", "ClassName must be a string")
    assert(type(name) == "string", "Name must be a string")
    
    local instance = parent:FindFirstChild(name)
    if not instance then
        instance = Instance.new(className)
        instance.Name = name
        
        if properties then
            for prop, value in pairs(properties) do
                if type(prop) == "string" then
                    instance[prop] = value
                else
                    warn(string.format("Skipping invalid property type: %s", typeof(prop)))
                end
            end
        end
        
        instance.Parent = parent
    end
    
    return instance :: Instance
end

-- Create a deep copy of a table
function Utility.deepCopy(original: any): any
    if type(original) ~= "table" then
        return original
    end
    
    local copy: {[any]: any} = {}
    for k, v in pairs(original) do
        local keyCopy = if type(k) == "table" then Utility.deepCopy(k) else k
        copy[keyCopy] = Utility.deepCopy(v)
    end
    
    return copy
end

-- Check if two values are deeply equal
function Utility.deepEquals(a: any, b: any): boolean
    if a == b then
        return true
    end
    
    if type(a) ~= "table" or type(b) ~= "table" then
        return false
    end
    
    for k, v in pairs(a) do
        if not Utility.deepEquals(v, b[k]) then
            return false
        end
    end
    
    for k, v in pairs(b) do
        if a[k] == nil then
            return false
        end
    end
    
    return true
end

-- Create a shallow copy of a table
function Utility.shallowCopy(original: { [any]: any }): { [any]: any }
    local copy = {}
    for k, v in pairs(original) do
        copy[k] = v
    end
    return copy
end

return Utility
