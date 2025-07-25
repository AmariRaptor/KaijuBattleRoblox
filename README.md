# Kaiju Battle Arena - Roblox Game

A thrilling kaiju-themed battle game where players can choose to be giant monsters or city defenders!

## Game Features

- Choose between Kaiju, Guardian, or Engineer classes
- Epic monster battles in a destructible city environment
- Unique abilities for each class
- Team-based gameplay
- Dynamic weather effects

## Setup Instructions

This project uses Rojo to manage the codebase.

1. Install [Aftman](https://github.com/LPGhatguy/aftman) and [Rojo](https://rojo.space/docs/v7/getting-started/).
2. Run `rojo build -o KaijuBattleRoblox.rbxlx` to build the place file.
3. Open `KaijuBattleRoblox.rbxlx` in Roblox Studio.

## Classes

- **Kaiju**: Giant monster with powerful attacks
- **Guardian**: City defender with defensive abilities
- **Engineer**: Support role with healing and buff abilities

## Configuration

Edit the `src/shared/modules/MainModule.luau` file to adjust:

- Game duration
- Player limits
- Damage multipliers
- Other game settings

## Requirements

- Roblox Studio
- Rojo
- Aftman
- Basic knowledge of Roblox Luau scripting

## File Structure

```text
src
├── client
│   ├── controllers
│   │   └── PlayerController.client.luau
│   └── init.client.luau
├── server
│   ├── systems
│   │   ├── BuildingSystem.server.luau
│   │   ├── KaijuSystem.server.luau
│   │   └── ScoringSystem.server.luau
│   └── init.server.luau
└── shared
    └── modules
        ├── Hello.luau
        └── MainModule.luau
```
