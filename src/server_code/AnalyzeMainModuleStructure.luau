--!strict
-- AnalyzeMainModuleStructure.luau
-- Script to analyze MainModule structure and implementation

local function logSuccess(message: string)
    print("✅ " .. message)
end

local function logWarning(message: string)
    warn("⚠️ " .. message)
end

local function logError(message: string)
    warn("❌ " .. message)
end

print("\n=== MainModule Structure Analysis ===\n")

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

-- 2. Verify it's a ModuleScript
if not mainModule:IsA("ModuleScript") then
    logError("MainModule is not a ModuleScript (it's a " .. mainModule.ClassName .. ")")
    return
end

-- 3. Get the source code
local source = mainModule.Source
print("\n=== Source Code Summary ===")
print("   Source length: " .. #source .. " characters")
print("   Number of lines: " .. select(2, string.gsub(source, "\n", "")) + 1)

-- 4. Parse the source code into lines
local lines = {}
for line in string.gmatch(source .. "\n", "(.-)\r?\n") do
    table.insert(lines, line)
end

-- 5. Analyze module structure
print("\n=== Module Structure ===")

-- Find the module table declaration
local moduleTableName = nil
for i, line in ipairs(lines) do
    local match = string.match(line, "local%s+([%w_]+)%s*=%s*%{")
    if match then
        moduleTableName = match
        logSuccess("Found module table: " .. moduleTableName)
        print("   Line " .. i .. ": " .. line:gsub("^%s+", ""):gsub("%s+$", ""))
        break
    end
end

-- Check for required methods
print("\n=== Required Methods ===")
local requiredMethods = {
    "init",
    "isInitialized",
    "getSystem",
    "getInitializedSystems"
}

local methodImplementations = {}
for _, method in ipairs(requiredMethods) do
    local found = false
    for i, line in ipairs(lines) do
        if string.find(line, "function%s+" .. (moduleTableName and (moduleTableName .. "%:") or "") .. method .. "%s*%(") then
            table.insert(methodImplementations, {
                name = method,
                line = i,
                code = line:gsub("^%s+", ""):gsub("%s+$", "")
            })
            found = true
            break
        end
    end
    
    if found then
        logSuccess("Found method: " .. method)
    else
        logError("Missing method: " .. method)
    end
end

-- Print method implementations
print("\n=== Method Implementations ===")
for _, method in ipairs(methodImplementations) do
    print(string.format("   %-20s Line %-4d %s", 
        method.name .. ":", 
        method.line, 
        method.code
    ))
end

-- 6. Check for module return
print("\n=== Module Return ===")
local returnFound = false
for i, line in ipairs(lines) do
    if string.find(line, "return%s+" .. (moduleTableName or "")) then
        logSuccess("Found module return statement")
        print("   Line " .. i .. ": " .. line:gsub("^%s+", ""):gsub("%s+$", ""))
        returnFound = true
        break
    end
end

if not returnFound then
    logError("Could not find module return statement")
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
    for i, line in ipairs(lines) do
        if string.find(line, issue.pattern) then
            foundIssues = true
            logWarning("Potential issue found: " .. issue.description)
            print("   Line " .. i .. ": " .. line:gsub("^%s+", ""):gsub("%s+$", ""))
        end
    end
end

if not foundIssues then
    logSuccess("No obvious issues found in the source code")
end

-- 8. Check for requires
print("\n=== Required Modules ===")
local requiresFound = false
for i, line in ipairs(lines) do
    local requireMatch = string.match(line, "require%([^)]+%)")
    if requireMatch then
        requiresFound = true
        print("   Line " .. i .. ": " .. line:gsub("^%s+", ""):gsub("%s+$", ""))
    end
end

if not requiresFound then
    logWarning("No require statements found in the module")
end

-- 9. Check for module initialization
print("\n=== Initialization Check ===")
local initFound = false
for i, line in ipairs(lines) do
    if string.find(line, "function%s+" .. (moduleTableName and (moduleTableName .. "%:") or "") .. "init%s*%(") then
        initFound = true
        logSuccess("Found init method")
        print("   Line " .. i .. ": " .. line:gsub("^%s+", ""):gsub("%s+$", ""))
        
        -- Print the next few lines for context
        for j = i + 1, math.min(i + 5, #lines) do
            print("   " .. j .. ": " .. lines[j]:gsub("^%s+", ""):gsub("%s+$", ""))
        end
        break
    end
end

if not initFound then
    logError("Could not find init method in the module")
end

print("\n=== Analysis Complete ===\n")
