--!strict
-- InspectMainModuleSource.luau
-- Script to thoroughly examine MainModule source code

local function logSuccess(message: string)
    print("✅ " .. message)
end

local function logWarning(message: string)
    warn("⚠️ " .. message)
end

local function logError(message: string)
    warn("❌ " .. message)
end

print("\n=== MainModule Source Code Inspection ===\n")

-- 1. Locate MainModule
local sss = game:GetService("ServerScriptService")
local mainModule = sss:FindFirstChild("MainModule")

if not mainModule then
    logError("MainModule not found in ServerScriptService")
    logWarning("Available children in ServerScriptService:")
    for _, child in ipairs(sss:GetChildren()) do
        print("   - " .. child:GetFullName() .. " (" .. child.ClassName .. ")")
    end
    return
end

logSuccess("Found MainModule: " .. mainModule:GetFullName())
print("   Class: " .. mainModule.ClassName)
print("   Source length: " .. #mainModule.Source .. " characters")

-- 2. Verify it's a ModuleScript
if not mainModule:IsA("ModuleScript") then
    logError("MainModule is not a ModuleScript (it's a " .. mainModule.ClassName .. ")")
    return
end

-- 3. Get the source code
local source = mainModule.Source

-- 4. Print the first 500 characters of source
print("\n=== Source Code Preview ===")
print(string.sub(source, 1, 500) .. (#source > 500 and "..." or ""))

-- 5. Look for module pattern
print("\n=== Module Pattern Analysis ===")
local modulePatterns = {
    {pattern = "local%s+[%w_]+%s*=%s*%{", description = "Table initialization"},
    {pattern = "function%s+[%w_]+%s*%:", description = "Method definition"},
    {pattern = "function%s+[%w_]+%s*%(", description = "Function definition"},
    {pattern = "require%(", description = "Require statement"},
    {pattern = "return%s+[%w_]+", description = "Module return"}
}

for _, item in ipairs(modulePatterns) do
    local found = string.find(source, item.pattern)
    print(string.format("   %-25s %s", item.description .. ":", found and "✅ Found" or "❌ Not found"))
end

-- 6. Look for required methods
print("\n=== Required Methods ===")
local requiredMethods = {
    {name = "init", pattern = "function%s+[%w_]*%.?init%s*%("},
    {name = "isInitialized", pattern = "function%s+[%w_]*%.?isInitialized%s*%("},
    {name = "getSystem", pattern = "function%s+[%w_]*%.?getSystem%s*%("},
    {name = "getInitializedSystems", pattern = "function%s+[%w_]*%.?getInitializedSystems%s*%("}
}

for _, method in ipairs(requiredMethods) do
    local found = string.find(source, method.pattern)
    print(string.format("   %-20s %s", method.name .. ":", found and "✅ Found" or "❌ Missing"))
    
    -- If found, print the function signature
    if found then
        local startLine = 1
        for line in string.gmatch(source, "(.-)\r?\n") do
            if string.find(line, method.pattern) then
                print("      " .. line:gsub("^%s+", ""):gsub("%s+$", ""))
                break
            end
            startLine = startLine + 1
        end
    end
end

-- 7. Look for potential issues
print("\n=== Potential Issues ===")
local potentialIssues = {
    {pattern = "while%s+true", description = "Infinite loop"},
    {pattern = "wait%(", description = "Blocking wait"},
    {pattern = "while%s*%(", description = "While loop"},
    {pattern = "spawn%(", description = "Spawn function"},
    {pattern = "delay%(", description = "Delay function"},
    {pattern = "coroutine%.resume%(", description = "Coroutine resume"},
    {pattern = "pcall%(", description = "Protected call"},
    {pattern = "xpcall%(", description = "Extended protected call"}
}

local foundIssues = false
for _, issue in ipairs(potentialIssues) do
    local found = string.find(source, issue.pattern)
    if found then
        foundIssues = true
        logWarning("Potential issue found: " .. issue.description)
        
        -- Find the line number
        local lineNum = 1
        local linePos = 1
        for line in string.gmatch(source, "(.-)\r?\n") do
            if string.find(line, issue.pattern) then
                print("   Line " .. lineNum .. ": " .. line:gsub("^%s+", ""):gsub("%s+$", ""))
            end
            lineNum = lineNum + 1
        end
    end
end

if not foundIssues then
    logSuccess("No obvious issues found in the source code")
end

-- 8. Check for module return
print("\n=== Module Return ===")
local returnMatch = string.match(source, "return%s+([%w_]+)")
if returnMatch then
    logSuccess("Module returns: " .. returnMatch)
else
    logError("Could not identify module return statement")
end

-- 9. Check for requires
print("\n=== Required Modules ===")
for requireStmt in string.gmatch(source, "require%([^)]+\))%") do
    print("   " .. requireStmt)
end

print("\n=== Source Code Inspection Complete ===\n")
