--!strict

print("Init script started.")

-- Modules
local ClassSystem = require(script.Parent.systems.ClassSystem)
local CharacterSystem = require(script.Parent.systems.CharacterSystem)

-- Initialize Systems
ClassSystem.init()
CharacterSystem.init()

print("Server systems initialized.")