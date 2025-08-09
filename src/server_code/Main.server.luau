--!strict
-- This script is the main entry point for the server.
-- It requires and initializes the main game module.

local ServerScriptService = game:GetService("ServerScriptService")

-- Wait for the MainModule to exist to avoid race conditions
local _mainModule = ServerScriptService:WaitForChild("MainModule")

-- Once we know it exists, require it directly using its full path.
-- This is standard practice and helps static analysis tools understand the code.
local main = require(game.ServerScriptService.MainModule)

if main and type(main.init) == "function" then
    main:init()
else
    warn("MainModule did not return a valid module or was missing an init function.")
end
