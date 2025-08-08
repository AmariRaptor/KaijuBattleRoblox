--!strict
-- GameConfig.luau
-- Centralized configuration for game settings

type ClassAttributes = {
	MaxHealth: number,
	WalkSpeed: number,
	JumpPower: number,
	Abilities: { [string]: any }?,
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
		Abilities: {
			EnergyBeam: {
				Cooldown: number,
				Damage: number,
				Range: number,
			},
			Roar: {
				Cooldown: number,
				Duration: number,
				BuffMultiplier: number,
			},
		},
	},
	Building: {
		MaxHealth: number,
		RepairRate: number,
	},
	Game: {
		RoundDuration: number,
		MinPlayers: number,
		MaxPlayers: number,
		RespawnTime: number,
	},
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
			},
			Roar = {
				Cooldown = 30,
				Duration = 10,
				BuffMultiplier = 1.5,
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
		RespawnTime = 10,
	},
}

return Config
