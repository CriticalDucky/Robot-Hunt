local ServerStorage = game:GetService "ServerStorage"
local ReplicatedFirst = game:GetService "ReplicatedFirst"

local GameLoop = ServerStorage.GameLoop

local Enums = require(ReplicatedFirst.Enums)
local Modules = require(GameLoop.Modules)
-- local Actions = require(GameLoop.Actions)
local RoundDataManager = require(GameLoop.RoundDataManager)

local DefaultRound = {}

function DefaultRound.begin()
	RoundDataManager.data.currentRoundType = Enums.RoundType.defaultRound

	return Modules.DefaultRound.Hiding
		.begin()
		:andThenCall(Modules.DefaultRound.PhaseOne.begin)
        :andThenCall(Modules.DefaultRound.PhaseTwo.begin)
end

return DefaultRound
