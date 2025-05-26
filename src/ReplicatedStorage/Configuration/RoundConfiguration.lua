--!strict
local DEBUG_MULTIPLIER = 1
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
			[PhaseType.Infiltration] = 5,--15*DEBUG_MULTIPLIER,
			[PhaseType.PhaseOne] = MINUTE*6*DEBUG_MULTIPLIER,
			[PhaseType.PhaseTwo] = MINUTE*6*DEBUG_MULTIPLIER,
			[PhaseType.Purge] = MINUTE*6*DEBUG_MULTIPLIER,
			[PhaseType.GameOver] = 5,
		},

		lobby = {
			[PhaseType.Intermission] = 5,--30*DEBUG_MULTIPLIER,
			[PhaseType.Results] = 10,
			[PhaseType.Loading] = 5,
		}
	},

	terminalPhases = {
		[PhaseType.Infiltration] = true,
		[PhaseType.PhaseOne] = true,
		[PhaseType.Purge] = true,
	},

	lobbyPhases = {
		[PhaseType.Intermission] = true,
		[PhaseType.Results] = true,
		[PhaseType.Loading] = true,
		[PhaseType.NotEnoughPlayers] = true,
	},

	roundPhases = {
		[PhaseType.Infiltration] = true,
		[PhaseType.PhaseOne] = true,
		[PhaseType.PhaseTwo] = true,
		[PhaseType.Purge] = true,
	},

	gunStrengthMultiplier = 29/30,
	gunPowerupMultiplier = 1.2,
	gunBaseDamagePerSecond = 20,

	shieldRegenBuffer = 8, -- The time it takes to start regenerating the shield after taking damage.
	shieldRegenAmountPerSecond = 5,
	shieldBaseAmount = 25,
	lifeSupportLossPerSecond = 100/45,

	hunterToRebelRatio = 1/3,

	maxTerminals = 6, -- Otherwise, the number of terminals is the number of players.
	minTerminals = 2,
	extraTerminals = 1,
	terminalProgressPerSecondPerPlayer = 100/45,
	minTerminalCooldown = 8,
	maxTerminalCooldown = 12,
	puzzleTimeout = 6,
	puzzleBonusPerPlayer = 0,
	puzzlePenaltyPerPlayer = 3,

	batteryLowerPercentage = 0.1, -- At least 50% of the batteries will spawn.
	batteryUpperPercentage = 0.5, -- At most 75% of the batteries will spawn.

	walkSpeed = 16,
	jumpPower = 50,

	deathWaitTime = 3,

	minPlayers = 2,

	controlPriorities = {
		battery = 1000,
		shootGun = 100,
	}
}

return RoundConfiguration
