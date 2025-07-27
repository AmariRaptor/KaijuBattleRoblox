-- convert_to_luau.lua
-- Script to convert Lua files to strictly-typed Luau

local fs = require("fs")
local path = require("path")

-- Function to convert a single Lua file to Luau
local function convertFileToLuau(filePath)
    print("Converting: " .. filePath)
    
    -- Read the file
    local content = fs.readFileSync(filePath, "utf8")
    
    -- Add strict typing if not present
    if not content:match("^%s*%-%-!strict") then
        content = "--!strict\n" .. content
    end
    
    -- Replace .lua with .luau in requires (basic, might need more complex handling)
    content = content:gsub("require%(["']([^"']+)%.lua["']%)", "require('%1.luau')")
    content = content:gsub("require%(["']([^"']+)['"]%)", function(module)
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

-- Find all .lua files in the src directory
local function findLuaFiles(dir)
    local files = {}
    
    local function scan(directory)
        local entries = fs.readdirSync(directory)
        
        for _, entry in ipairs(entries) do
            local fullPath = path.join(directory, entry)
            local stat = fs.statSync(fullPath)
            
            if stat.isDirectory() then
                scan(fullPath)
            elseif entry:match("%.lua$") then
                table.insert(files, fullPath)
            end
        end
    end
    
    scan(dir)
    return files
end

-- Main function
local function main()
    local srcDir = path.join(__dirname, "src")
    local luaFiles = findLuaFiles(srcDir)
    
    if #luaFiles == 0 then
        print("No .lua files found in " .. srcDir)
        return
    end
    
    print("Found " .. #luaFiles .. " .lua files to convert:")
    
    local converted = {}
    for _, file in ipairs(luaFiles) do
        local success, result = pcall(convertFileToLuau, file)
        if success then
            table.insert(converted, result)
        else
            print("Error converting " .. file .. ": " .. tostring(result))
        end
    end
    
    print("\nConversion complete!")
    print("Converted " .. #converted .. " files to .luau")
    
    -- Create a summary file
    local summary = {
        timestamp = os.date("%Y-%m-%d %H:%M:%S"),
        convertedFiles = converted,
        totalConverted = #converted
    }
    
    fs.writeFileSync(
        path.join(__dirname, "luau_conversion_summary.json"),
        require("json").encode(summary, {indent = true})
    )
end

-- Run the script
main()
