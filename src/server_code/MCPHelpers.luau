--!strict
-- MCPHelpers.luau
-- Helpers to run code via MCP's run_code with retries and timeouts

local MCPHelpers = {}

-- Default runInStudio fallback (used when executing locally)
local function defaultRunInStudio(code: string): (boolean, any)
    return pcall(loadstring(code))
end

local function sleep(seconds: number)
    seconds = seconds or 0.5
    -- Prefer task.wait in Roblox; otherwise attempt OS-level fallback (best-effort)
    if pcall(function() task.wait(seconds) end) then
        return
    end
    -- Try to use os.execute as a fallback (platform-dependent)
    if type(package) == "table" and type(package.config) == "string" and package.config:sub(1,1) == "\\" then
        -- Windows: use ping hack for best-effort sleep
        pcall(function() os.execute("ping -n " .. tostring(math.max(1, math.floor(seconds))) .. " 127.0.0.1 > NUL") end)
    else
        pcall(function() os.execute("sleep " .. tostring(seconds)) end)
    end
end

function MCPHelpers.run_code_with_retry(runFunc, code: string, retries: number?, delaySeconds: number?): (boolean, any)
    retries = retries or 3
    delaySeconds = delaySeconds or 0.5
    local lastErr = "unknown error"
    local run = runFunc or defaultRunInStudio

    for i = 1, retries do
        local ok, r1, r2 = pcall(run, code)
        if not ok then
            lastErr = r1
            warn(string.format("[MCPHelpers] run threw an error on attempt %d: %s", i, tostring(r1)))
        else
            if type(r1) == "boolean" then
                if r1 then
                    return true, r2
                else
                    lastErr = r2
                    warn(string.format("[MCPHelpers] run returned false on attempt %d: %s", i, tostring(r2)))
                end
            else
                -- Non-boolean return: treat as success and return the first value
                return true, r1
            end
        end

        if i < retries then
            pcall(function() sleep(delaySeconds) end)
        end
    end

    return false, lastErr
end

function MCPHelpers.buildInspectMainModuleSnippet(): string
    local snippet = [[
        local sss = game:GetService("ServerScriptService")
        local mainModule = sss:FindFirstChild("MainModule")
        if not mainModule then return nil, "MainModule not found" end
        local success, moduleOrErr = pcall(require, mainModule)
        if not success then return nil, moduleOrErr end
        local methods = {}
        for k, v in pairs(moduleOrErr) do
            if type(v) == "function" then
                table.insert(methods, k)
            end
        end
        table.sort(methods)
        local isInitialized = nil
        if type(moduleOrErr.isInitialized) == "function" then
            local ok, val = pcall(moduleOrErr.isInitialized, moduleOrErr)
            if ok then isInitialized = val end
        end
        local initResult = nil
        if not isInitialized and type(moduleOrErr.init) == "function" then
            local initOk, initRes = pcall(moduleOrErr.init, moduleOrErr)
            if initOk then
                initResult = "success"
                if type(moduleOrErr.isInitialized) == "function" then
                    local ok2, val2 = pcall(moduleOrErr.isInitialized, moduleOrErr)
                    if ok2 then isInitialized = val2 end
                end
            else
                initResult = "failed: " .. tostring(initRes)
            end
        end
        local systems = {}
        if type(moduleOrErr.getInitializedSystems) == "function" then
            local ok, res = pcall(moduleOrErr.getInitializedSystems, moduleOrErr)
            if ok and type(res) == "table" then
                for k, _ in pairs(res) do
                    table.insert(systems, tostring(k))
                end
                table.sort(systems)
            end
        end
        return {
            type = type(moduleOrErr),
            methods = methods,
            isInitialized = isInitialized,
            hasInit = type(moduleOrErr.init) == "function",
            initResult = initResult,
            systems = systems
        }
    ]]
    return snippet
end

function MCPHelpers.inspectMainModule(runFunc, retries, delaySeconds)
    local code = MCPHelpers.buildInspectMainModuleSnippet()
    return MCPHelpers.run_code_with_retry(runFunc, code, retries or 3, delaySeconds or 0.5)
end

return MCPHelpers