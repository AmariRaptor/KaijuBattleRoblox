--!strict
-- RunMainModuleViaMCP.luau
-- Uses MCPHelpers to inspect and optionally run MainModule via MCP's run_code

local MCPHelpers = require(script.Parent.MCPHelpers)

-- Default runInStudio placeholder replaced by MCP server tool when executed remotely
local function defaultRunInStudio(code: string): (boolean, any)
    return pcall(loadstring(code))
end

local function runMainViaMCP(runFunc, retries, delaySeconds)
    local runner = runFunc or defaultRunInStudio
    local ok, result = MCPHelpers.inspectMainModule(runner, retries, delaySeconds)
    if not ok then
        warn("[RunMainModuleViaMCP] Failed to inspect MainModule: " .. tostring(result))
        return false, result
    end

    -- If the module is not initialized but has an init method, attempt to init
    if not result.isInitialized and result.hasInit then
        print("[RunMainModuleViaMCP] MainModule is not initialized; attempting to init via MCP.")
        local initCode = [[
            local sss = game:GetService("ServerScriptService")
            local mainModule = sss:FindFirstChild("MainModule")
            if not mainModule then return nil, "MainModule not found" end
            local success, moduleOrErr = pcall(require, mainModule)
            if not success then return nil, moduleOrErr end
            if type(moduleOrErr.init) == "function" then
                local initOk, initRes = pcall(moduleOrErr.init, moduleOrErr)
                if initOk then return "init_ok" else return nil, initRes end
            end
            return "no_init_method"
        ]]
        local initOk, initResult = MCPHelpers.run_code_with_retry(runner, initCode, retries or 3, delaySeconds or 0.5)
        if not initOk then
            warn("[RunMainModuleViaMCP] Init attempt failed: " .. tostring(initResult))
            return false, initResult
        end
        print("[RunMainModuleViaMCP] Init attempt result: " .. tostring(initResult))
    else
        print("[RunMainModuleViaMCP] MainModule already initialized or has no init; nothing to do.")
    end

    return true, result
end

return {
    runMainViaMCP = runMainViaMCP
}