--!strict

local MINUTE = 60/6

local ReplicatedFirst = game:GetService("ReplicatedFirst")

local Enums = require(ReplicatedFirst:WaitForChild("Enums"))

local PhaseType = Enums.PhaseType
local RoundType = Enums.RoundType

type RoundType = number
type PhaseType = number

--[[
	Configuration for player data.
]]
local RoundConfiguration = {
	timeLengths = {
		[RoundType.defaultRound] = {
			[PhaseType.Infiltration] = 15,
			[PhaseType.PhaseOne] = MINUTE*6,
			[PhaseType.PhaseTwo] = MINUTE*6,
		},

		lobby = {
			[PhaseType.Intermission] = 30,
			[PhaseType.Results] = 10,
			[PhaseType.Loading] = 5,
		}
	},

	gunStrengthMultiplier = 29/30,
	gunPowerupMultiplier = 1.2,
	hunterBeamColor = Color3.fromRGB(254, 51, 51),
	rebelBeamColor = Color3.fromRGB(0, 255, 0),

	hunterToRebelRatio = 1/3,

	maxTerminals = 6, -- Otherwise, the number of terminals is the number of players.
	minTerminals = 2,
	extraTerminals = 1,

	batteryLowerPercentage = 0.1, -- At least 50% of the batteries will spawn.
	batteryUpperPercentage = 0.5, -- At most 75% of the batteries will spawn.

	minPlayers = 2,
}

return RoundConfiguration
