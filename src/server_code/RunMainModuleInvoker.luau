--!strict
-- RunMainModuleInvoker.luau
-- Small invoker that calls RunMainModuleViaMCP.runMainViaMCP using a default runner (pcall+loadstring).
-- This file prepares a safe local runner and prints results. For authoritative execution in Roblox Studio,
-- run the equivalent code via the MCP 'run_code' function or provide an MCP runner function.

local RunMainModuleViaMCP = require(script.Parent.RunMainModuleViaMCP)

-- Default runner: attempts to execute code locally using loadstring (best-effort, non-MCP).
local function defaultRunner(code: string): (boolean, any)
    local fn, loadErr = loadstring(code)
    if not fn then
        return false, loadErr
    end
    local ok, res = pcall(fn)
    return ok, res
end

-- Wrapper to call RunMainModuleViaMCP.runMainViaMCP with retries and delay.
local function invoke(retries: number?, delaySeconds: number?): (boolean, any)
    retries = retries or 3
    delaySeconds = delaySeconds or 0.5

    local ok, result = pcall(function()
        return RunMainModuleViaMCP.runMainViaMCP(defaultRunner, retries, delaySeconds)
    end)

    if not ok then
        warn("[RunMainModuleInvoker] runMainViaMCP errored: " .. tostring(result))
        return false, result
    end

    print("[RunMainModuleInvoker] runMainViaMCP returned:", tostring(result))
    return true, result
end

-- Auto-run when required/started (best-effort; useful when run inside Roblox Studio or a compatible environment)
local ranOk, ranRes = invoke()
if not ranOk then
    warn("[RunMainModuleInvoker] Auto-invoke failed; see run() to retry with a different runner.")
end

return {
    run = invoke
}