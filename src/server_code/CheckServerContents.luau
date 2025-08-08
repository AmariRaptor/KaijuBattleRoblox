--!strict
-- Script to list contents of ServerScriptService

print("=== ServerScriptService Contents ===\n")

local ServerScriptService = game:GetService("ServerScriptService")

-- List all children of ServerScriptService
print("Children of ServerScriptService:")
for _, child in ipairs(ServerScriptService:GetChildren()) do
    print(string.format("  - %s (%s)", child:GetFullName(), child.ClassName))
    
    -- If it's a Script or ModuleScript, show source preview
    if child:IsA("Script") or child:IsA("ModuleScript") then
        local source = child.Source
        print("    Source preview: " .. string.sub(source, 1, 100) .. (string.len(source) > 100 and "..." or ""))
    end
    
    -- If it's a Folder, list its contents
    if child:IsA("Folder") then
        print("    Contents:")
        for _, subchild in ipairs(child:GetChildren()) do
            print("      - " .. subchild:GetFullName() .. " (" .. subchild.ClassName .. ")")
        end
    end
end

print("\n=== End of ServerScriptService Contents ===\n")
