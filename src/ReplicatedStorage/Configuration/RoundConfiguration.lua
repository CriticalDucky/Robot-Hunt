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
			[PhaseType.Infiltration] = MINUTE*0.5,
			[PhaseType.PhaseOne] = MINUTE*2.5,
			[PhaseType.PhaseTwo] = MINUTE*2.5,
		},

		lobby = {
			[PhaseType.Intermission] = 15,
			[PhaseType.Results] = 10,
		}
	},

	gunStrengthMultiplier = 29/30,
	gunPowerupMultiplier = 1.2,
	hunterBeamColor = Color3.fromRGB(254, 51, 51),
	rebelBeamColor = Color3.fromRGB(0, 255, 0),

	hunterToRebelRatio = 1/3,

	minPlayers = 2,
}

return RoundConfiguration
