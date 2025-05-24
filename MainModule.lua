-- MainModule.lua
local MainModule = {}

-- Constants
MainModule.GAME_NAME = "Kaiju Battle Arena"
MainModule.MAX_PLAYERS = 8
MainModule.BATTLE_ARENA_SIZE = Vector3.new(200, 50, 200)

-- Player Classes
MainModule.PLAYER_CLASSES = {
    "Kaiju", -- Giant monster
    "Guardian", -- City defender
    "Engineer", -- Support role
}

-- Game States
MainModule.GAME_STATES = {
    LOBBY = 0,
    PREPARATION = 1,
    BATTLE = 2,
    END = 3
}

-- Configuration
MainModule.CONFIG = {
    ROUND_TIME = 300, -- 5 minutes
    SPAWN_DELAY = 5,
    REGENERATION_RATE = 1,
    DAMAGE_MULTIPLIER = 1.0,
    
    -- Class-specific settings
    KAIJU = {
        HEALTH = 500,
        ENERGY = 100,
        ATTACK_COOLDOWN = 2,
        ABILITIES = {
            ENERGY_BEAM = {
                DAMAGE = 50,
                COOLDOWN = 10,
                RANGE = 100
            },
            ROAR = {
                STUN_DURATION = 2,
                COOLDOWN = 20,
                RANGE = 50
            }
        }
    },
    
    GUARDIAN = {
        HEALTH = 200,
        SHIELD = 100,
        REPAIR_RATE = 5,
        ABILITIES = {
            SHIELD_GENERATOR = {
                DURATION = 10,
                COOLDOWN = 30,
                RANGE = 20
            },
            MISSILE_BARRAGE = {
                DAMAGE = 30,
                COOLDOWN = 15,
                COUNT = 5
            }
        }
    },
    
    ENGINEER = {
        HEALTH = 150,
        ENERGY = 200,
        REPAIR_RATE = 10,
        ABILITIES = {
            HEAL_BEAM = {
                HEAL_AMOUNT = 20,
                COOLDOWN = 5,
                RANGE = 50
            },
            TURRET = {
                DAMAGE = 15,
                COOLDOWN = 20,
                DURATION = 60
            }
        }
    }
}

return MainModule
