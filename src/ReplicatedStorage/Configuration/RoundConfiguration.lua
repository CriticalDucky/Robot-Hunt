--!strict

local MINUTE = 60/6

type RoundConfiguration = {
	defaultRound: {
		hidingTime: number,
        phaseOneLength: number,
        phaseTwoLength: number,
    },

	intermissionLength: number,
	resultsLength: number,

	minPlayers: number,
}

--[[
	Configuration for player data.
]]
local RoundConfiguration: RoundConfiguration = {
	defaultRound = {
		hidingTime = MINUTE*0.5,
		phaseOneLength = MINUTE*2.5,
		phaseTwoLength = MINUTE*2.5,
	},

	intermissionLength = 15,
	resultsLength = 10,

	minPlayers = 2,
}

return RoundConfiguration
