--!strict
local DEBUG_MULTIPLIER = 0.1
local MINUTE = 60

local ReplicatedFirst = game:GetService("ReplicatedFirst")

local Enums = require(ReplicatedFirst:WaitForChild("Enums"))

local PhaseType = Enums.PhaseType
local RoundType = Enums.RoundType
local TeamType = Enums.TeamType

type RoundType = number
type PhaseType = number

--[[
	Configuration for player data.
]]
local RoundConfiguration = {
	timeLengths = {
		[RoundType.defaultRound] = {
			[PhaseType.Infiltration] = 15*DEBUG_MULTIPLIER,
			[PhaseType.PhaseOne] = MINUTE*6*DEBUG_MULTIPLIER,
			[PhaseType.PhaseTwo] = MINUTE*6*DEBUG_MULTIPLIER,
			[PhaseType.Purge] = MINUTE*6*DEBUG_MULTIPLIER,
		},

		lobby = {
			[PhaseType.Intermission] = 30*DEBUG_MULTIPLIER,
			[PhaseType.Results] = 10,
			[PhaseType.Loading] = 5,
		}
	},

	lobbyPhases = {
		[PhaseType.Intermission] = true,
		[PhaseType.Results] = true,
		[PhaseType.Loading] = true,
		[PhaseType.NotEnoughPlayers] = true,
	},

	gunStrengthMultiplier = 29/30,
	gunPowerupMultiplier = 1.2,
	gunBaseDamagePerSecond = 20,

	gunEffectColors = {
		[TeamType.hunters] = {
			beamColor = Color3.fromRGB(255, 0, 0),
			attackLightColor = Color3.fromRGB(255, 32, 32),
			attackGlowColor = Color3.fromRGB(255, 48, 48),
			attackElectricityColor = Color3.fromRGB(255, 142, 142),
		},

		[TeamType.rebels] = {
			beamColor = Color3.fromRGB(59, 193, 255),
			attackLightColor = Color3.fromRGB(106, 173, 255),
			attackGlowColor = Color3.fromRGB(106, 173, 255),
			attackElectricityColor = Color3.fromRGB(101, 247, 255),
		},
	},

	hunterToRebelRatio = 1/3,

	maxTerminals = 6, -- Otherwise, the number of terminals is the number of players.
	minTerminals = 2,
	extraTerminals = 1,

	batteryLowerPercentage = 0.1, -- At least 50% of the batteries will spawn.
	batteryUpperPercentage = 0.5, -- At most 75% of the batteries will spawn.

	minPlayers = 2,

	controlPriorities = {
		battery = 1000,
		shootGun = 100,
	}
}

return RoundConfiguration
