--!strict
-- GameConfig.luau
-- Centralized configuration for game settings

type AbilityDef = {
    Cost: number?,
    Cooldown: number?,
}

type ClassAttributes = {
    MaxHealth: number,
    WalkSpeed: number,
    JumpPower: number,
    Abilities: { [number]: string }?,
}

type KaijuAbilityConfig = {
    Cooldown: number?,
    Damage: number?,
    Range: number?,
    Duration: number?,
    BuffMultiplier: number?,
    SoundId: string?,
}

type KaijuDef = {
    Name: string,
    MaxHealth: number,
    Size: Vector3,
    PhaseThresholds: { number }?,
    Abilities: { [string]: KaijuAbilityConfig }?,
}

type RespawnConfig = {
    Enabled: boolean,
    RespawnTime: number,
    ExtraLives: number,
}

type AbilitiesConfig = {
    EnergyMax: number,
    EnergyRegen: number,
    UltimateThreshold: number,
    UltimateGainPerDamage: number,
    Defaults: { [string]: AbilityDef }?,
}

type MapConfig = {
    SpawnPoints: { Vector3 }?,
    Props: {
        DefaultSize: Vector3?,
        DefaultHealth: number?,
    }?,
}

type GameConfig = {
    Classes: {
        Kaiju: ClassAttributes,
        Guardian: ClassAttributes,
        Engineer: ClassAttributes,
    },
    Kaiju: {
        Size: Vector3,
        BaseHealth: number,
        Abilities: { EnergyBeam: KaijuAbilityConfig, Roar: KaijuAbilityConfig }
    },
    KaijuDefs: { [string]: KaijuDef }?,
    Building: {
        MaxHealth: number,
        RepairRate: number,
    },
    Game: {
        RoundDuration: number,
        MinPlayers: number,
        MaxPlayers: number,
        Respawn: RespawnConfig,
    },
    Abilities: AbilitiesConfig,
    Map: MapConfig?,
}

local Config: GameConfig = {
    Classes = {
        Kaiju = {
            MaxHealth = 500,
            WalkSpeed = 24,
            JumpPower = 50,
            Abilities = {
                "Smash",
                "Charge",
                "Roar",
            },
        },
        Guardian = {
            MaxHealth = 200,
            WalkSpeed = 16,
            JumpPower = 50,
            Abilities = {
                "ShieldBash",
                "Taunt",
                "Rally",
            },
        },
        Engineer = {
            MaxHealth = 150,
            WalkSpeed = 18,
            JumpPower = 50,
            Abilities = {
                "Repair",
                "Turret",
                "SpeedBoost",
            },
        },
    },
    Kaiju = {
        Size = Vector3.new(10, 5, 10),
        BaseHealth = 500,
        Abilities = {
            EnergyBeam = {
                Cooldown = 10,
                Damage = 30,
                Range = 100,
                SoundId = "123456789",
            },
            Roar = {
                Cooldown = 30,
                Duration = 10,
                BuffMultiplier = 1.5,
                SoundId = "123456789",
            },
        },
    },
    KaijuDefs = {
        Basic = {
            Name = "Basic",
            MaxHealth = 3000,
            Size = Vector3.new(20, 10, 20),
            PhaseThresholds = { 0.6, 0.3 },
            Abilities = {
                Stomp = { Cooldown = 6, Damage = 50, Range = 10 },
                Swipe = { Cooldown = 1.5, Damage = 25 },
                Charge = { Cooldown = 8, Damage = 80, Range = 40 },
            },
        },
    },
    Building = {
        MaxHealth = 1000,
        RepairRate = 10,
    },
    Game = {
        RoundDuration = 600, -- 10 minutes
        MinPlayers = 2,
        MaxPlayers = 10,
        Respawn = {
            Enabled = true,
            RespawnTime = 10,
            ExtraLives = 2,
        },
    },
    Abilities = {
        EnergyMax = 100,
        EnergyRegen = 8,
        UltimateThreshold = 100,
        UltimateGainPerDamage = 0.5,
        Defaults = {
            Dash = { Cost = 20, Cooldown = 3 },
            Shield = { Cost = 30, Cooldown = 10 },
            Primary = { Cost = 0, Cooldown = 0.5 },
            Heavy = { Cost = 10, Cooldown = 5 },
        },
    },

    -- Map/prototype settings for spawn points and destructible prop defaults
    Map = {
        SpawnPoints = {
            Vector3.new(0, 5, 0),
            Vector3.new(50, 5, 0),
            Vector3.new(-50, 5, 0),
        },
        Props = {
            DefaultSize = Vector3.new(4, 4, 4),
            DefaultHealth = 200,
        },
    },
}

return Config
