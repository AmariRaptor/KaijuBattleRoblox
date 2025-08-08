--!strict
-- ExamineMainModuleCode.luau
-- Script to directly examine the MainModule source code

local function logSuccess(message: string)
    print("✅ " .. message)
end

local function logWarning(message: string)
    warn("⚠️ " .. message)
end

local function logError(message: string)
    warn("❌ " .. message)
end

print("\n=== MainModule Source Code Examination ===\n")

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

-- 2. Verify it's a ModuleScript
if not mainModule:IsA("ModuleScript") then
    logError("MainModule is not a ModuleScript (it's a " .. mainModule.ClassName .. ")")
    return
end

-- 3. Get and analyze the source code
local source = mainModule.Source
logSuccess("Found MainModule source code (" .. #source .. " characters)")

-- 4. Print the full source code with line numbers
print("\n=== MainModule Source Code ===")
local lines = {}
for line in string.gmatch(source .. "\n", "(.-)\r?\n") do
    table.insert(lines, line)
end

-- Print first 200 lines or all lines if less than 200
local maxLines = math.min(200, #lines)
for i = 1, maxLines do
    print(string.format("%4d: %s", i, lines[i]))
end

if #lines > 200 then
    print("... (truncated, " .. (#lines - 200) .. " more lines)")
end

-- 5. Look for specific patterns
print("\n=== Key Code Patterns ===")

local patterns = {
    {pattern = "local%s+[%w_]+%s*=%s*%{", description = "Table initialization"},
    {pattern = "function%s+[%w_]+%s*%(", description = "Function definitions"},
    {pattern = "require%(", description = "Require statements"},
    {pattern = "init%s*=", description = "Init method definition"},
    {pattern = "isInitialized%s*=", description = "isInitialized method definition"},
    {pattern = "getSystem%s*=", description = "getSystem method definition"},
    {pattern = "getInitializedSystems%s*=", description = "getInitializedSystems method definition"},
    {pattern = "return%s+[%w%p%s]+", description = "Module return statement"}
}

for _, item in ipairs(patterns) do
    local found = string.find(source, item.pattern)
    print(string.format("   %-30s %s", item.description .. ":", found and "✅ Found" or "❌ Not found"))
    
    -- If found, show context
    if found then
        local startPos = math.max(1, found - 30)
        local endPos = math.min(#source, found + 50)
        local context = string.sub(source, startPos, endPos)
        print("      Context: " .. string.gsub(context, "\n", " "))
    end
end

-- 6. Check for module return
local returnPattern = "return%s+([%w_]+)"
local moduleVar = string.match(source, returnPattern)
if moduleVar then
    logSuccess("Module returns: " .. moduleVar)
else
    logWarning("Could not identify module return statement")
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
        local startPos = math.max(1, found - 30)
        local endPos = math.min(#source, found + 50)
        local context = string.sub(source, startPos, endPos)
        print("   Context: " .. string.gsub(context, "\n", " "))
    end
end

if not foundIssues then
    logSuccess("No obvious issues found in the source code")
end

print("\n=== Source Code Examination Complete ===\n")
