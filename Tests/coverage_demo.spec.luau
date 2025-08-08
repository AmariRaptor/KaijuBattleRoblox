--!strict
-- coverage_demo.spec.luau
-- Demo test file to demonstrate code coverage reporting

-- A simple function to test coverage
local function addNumbers(a: number, b: number): number
    if a < 0 then
        return b - math.abs(a)
    end
    return a + b
end

-- Another function with branching logic
local function isEven(num: number): boolean
    if num % 2 == 0 then
        return true
    else
        return false
    end
end

-- Test cases
return function()
    local results = {}
    
    -- Test addNumbers with positive numbers
    do
        local result = addNumbers(2, 3)
        if result == 5 then
            table.insert(results, "✅ addNumbers(2, 3) returns 5")
        else
            table.insert(results, `❌ Expected addNumbers(2, 3) to return 5, got {result}`)
        end
    end
    
    -- Test addNumbers with negative first number
    do
        local result = addNumbers(-2, 3)
        if result == 1 then
            table.insert(results, "✅ addNumbers(-2, 3) returns 1")
        else
            table.insert(results, `❌ Expected addNumbers(-2, 3) to return 1, got {result}`)
        end
    end
    
    -- Test isEven with even number
    do
        local result = isEven(4)
        if result == true then
            table.insert(results, "✅ isEven(4) returns true")
        else
            table.insert(results, `❌ Expected isEven(4) to return true, got {result}`)
        end
    end
    
    -- Test isEven with odd number
    do
        local result = isEven(5)
        if result == false then
            table.insert(results, "✅ isEven(5) returns false")
        else
            table.insert(results, `❌ Expected isEven(5) to return false, got {result}`)
        end
    end
    
    return results
end
