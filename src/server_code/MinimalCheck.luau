-- MinimalCheck.luau
-- A minimal script to test basic functionality in the MCP environment

-- Simple output
debug.output("=== Starting Minimal Check ===")
debug.output("If you can see this, basic script execution is working!")

-- Basic environment info
debug.output("\nEnvironment:")
debug.output("_VERSION: " .. tostring(_VERSION))
debug.output("os.time(): " .. tostring(os and os.time() or "os not available"))

-- Check for common globals
local function checkGlobal(name)
    local value = _G[name]
    debug.output(string.format("%-15s: %s", name, tostring(value ~= nil)))
end

debug.output("\nGlobal Variables:")
checkGlobal("game")
checkGlobal("workspace")
checkGlobal("script")
checkGlobal("require")
checkGlobal("print")
checkGlobal("debug")
checkGlobal("debug.output")

debug.output("\n=== Minimal Check Complete ===")

return true, "Minimal check completed successfully"
