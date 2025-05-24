# Kaiju Battle Arena - Roblox Game

A thrilling kaiju-themed battle game where players can choose to be giant monsters or city defenders!

## Game Features
- Choose between Kaiju, Guardian, or Engineer classes
- Epic monster battles in a destructible city environment
- Unique abilities for each class
- Team-based gameplay
- Dynamic weather effects

## Setup Instructions
1. Create a new Roblox Studio project
2. Copy all files from this repository into your project's ReplicatedStorage folder
3. Create a new Script in ServerScriptService and require("MainModule")
4. Customize the game settings in MainModule.lua

## Classes
- **Kaiju**: Giant monster with powerful attacks
- **Guardian**: City defender with defensive abilities
- **Engineer**: Support role with healing and buff abilities

## Configuration
Edit the MainModule.lua file to adjust:
- Game duration
- Player limits
- Damage multipliers
- Other game settings

## Requirements
- Roblox Studio
- Basic knowledge of Roblox Lua scripting
- Internet connection for asset downloads

## FILE STRUCTURE
ReplicatedStorage
├── Modules
│   ├── MainModule.lua
│   ├── PlayerController.lua
│   ├── KaijuSystem.lua
│   ├── ScoringSystem.lua
│   ├── BuildingSystem.lua
│   └── WorldGenerator.lua
└── GameController.lua