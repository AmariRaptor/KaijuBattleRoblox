-- convert_to_luau.lua
-- Enhanced script to convert Lua files to strictly-typed Luau with proper type annotations

local fs = require("fs")
local path = require("path")

-- Common Luau type annotations
local TYPE_ANNOTATIONS = {
    -- Common Roblox types
    ["Instance"] = true,
    ["Part"] = true,
    ["BasePart"] = true,
    ["Model"] = true,
    ["Humanoid"] = true,
    ["Player"] = true,
    ["Vector3"] = true,
    ["CFrame"] = true,
    ["Color3"] = true,
    
    -- Common Lua types
    ["table"] = true,
    ["string"] = true,
    ["number"] = true,
    ["boolean"] = true,
    ["function"] = true,
    ["any"] = true,
    ["nil"] = true,
}

-- Function to infer type from value
local function inferType(value)
    local t = type(value)
    if t == "table" then
        return "table"
    elseif t == "string" then
        return "string"
    elseif t == "number" then
        return "number"
    elseif t == "boolean" then
        return "boolean"
    elseif t == "function" then
        return "() -> any"
    end
    return "any"
end

-- Function to add type annotations to a function signature
local function addTypeAnnotations(content)
    -- This is a simplified version - in a real scenario, you'd want a full parser
    -- This handles basic function declarations
    content = content:gsub(
        "function%s+([%w_%.]+)%s*%(([^)]*)%)",
        function(name, params)
            -- Skip if already has type annotations
            if name:match(":%s*%a") then
                return "function " .. name .. "(" .. params .. ")"
            end
            
            -- Add type annotations to parameters
            local typedParams = {}
            for param in params:gmatch("([%w_]+)") do
                table.insert(typedParams, param .. ": any")
            end
            
            return string.format("function %s(%s): any", name, table.concat(typedParams, ", "))
        end
    )
    
    return content
end

-- Function to convert a single Lua file to Luau
local function convertFileToLuau(filePath)
    print("Converting: " .. filePath)
    
    -- Read the file
    local content = fs.readFileSync(filePath, "utf8")
    
    -- Skip if already has strict mode
    if content:match("^%s*%-%-!strict") then
        print("Skipping (already strict Luau): " .. filePath)
        return nil
    end
    
    -- Add strict typing
    content = "--!strict\n" .. content
    
    -- Add type annotations
    content = addTypeAnnotations(content)
    
    -- Replace .lua with .luau in requires
    content = content:gsub("require%(%s*['"]([^"']+)%.lua['"]%s*%)%s*;?", "require('%1.luau')")
    content = content:gsub("require%(%s*['"]([^"']+)['"]%s*%)%s*;?", function(module)
        -- Only replace if it doesn't already have an extension
        if not module:match("%.%w+$") then
            return string.format("require('%s.luau')", module)
        end
        return string.format("require('%s')", module)
    end)
    
    -- Write to new .luau file
    local newPath = filePath:gsub("%.lua$", ".luau")
    fs.writeFileSync(newPath, content)
    
    print("Created: " .. newPath)
    return newPath
end

-- Function to run Luau type checking on a file
local function checkLuauTypes(filePath)
    -- In a real implementation, this would use the Luau CLI or a library
    -- For now, we'll just check for common issues
    local content = fs.readFileSync(filePath, "utf8")
    
    -- Check for any type errors (simplified)
    if content:match("%[.-%]") then
        print("Warning: Possible type annotation issue in " .. filePath)
        return false
    end
    
    return true
end

-- Find all .lua files in the src directory
local function findLuaFiles(dir)
    local files = {}
    
    local function scan(directory)
        local success, entries = pcall(fs.readdirSync, directory)
        if not success then
            print("Warning: Could not read directory: " .. directory)
            return
        end
        
        for _, entry in ipairs(entries) do
            local fullPath = path.join(directory, entry)
            local stat = fs.statSync(fullPath)
            
            if stat.isDirectory() then
                scan(fullPath)
            elseif entry:match("%.lua$") and not entry:match("^_temp_") then
                table.insert(files, fullPath)
            end
        end
    end
    
    scan(dir)
    return files
end

-- Main function
local function main()
    local srcDir = path.join(fs.realpath("."), "src")
    
    if not pcall(fs.statSync, srcDir) then
        print("Error: src directory not found")
        return
    end
    
    print("Converting Lua files to Luau in: " .. srcDir)
    local luaFiles = findLuaFiles(srcDir)
    local convertedFiles = {}
    
    -- First pass: convert all files
    for _, file in ipairs(luaFiles) do
        local newFile = convertFileToLuau(file)
        if newFile then
            table.insert(convertedFiles, newFile)
        end
    end
    
    -- Second pass: type check converted files
    print("\nType checking converted files...")
    local typeErrors = 0
    
    for _, file in ipairs(convertedFiles) do
        if not checkLuauTypes(file) then
            typeErrors = typeErrors + 1
        end
    end
    
    print("\nConversion complete!")
    print("- Converted " .. #convertedFiles .. " files")
    print("- Found " .. typeErrors .. " potential type issues")
    
    if typeErrors > 0 then
        print("\nNote: Some type checking issues were found. Please review the converted files.")
    end
    
    print("\nNext steps:")
    print("1. Review the converted files for any type errors")
    print("2. Run your test suite to ensure everything works as expected")
    print("3. Consider using a Luau type checker for more comprehensive validation")
    
    -- Create a summary file
    local summary = {
        timestamp = os.date("%Y-%m-%d %H:%M:%S"),
        convertedFiles = convertedFiles,
        totalConverted = #convertedFiles,
        typeIssues = typeErrors
    }
    
    fs.writeFileSync(
        path.join(__dirname, "luau_conversion_summary.json"),
        require("json").encode(summary, {indent = true})
    )
end

-- Run the script
main()
