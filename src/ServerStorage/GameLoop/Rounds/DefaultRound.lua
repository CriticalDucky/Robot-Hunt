local ServerStorage = game:GetService "ServerStorage"

local Modules = require(ServerStorage.GameLoop.Modules)

local DefaultRound = {}

function DefaultRound.begin()
	return Modules.DefaultRound.Hiding
		.begin()
		:andThenCall(Modules.DefaultRound.PhaseOne.begin)
        :andThenCall(Modules.DefaultRound.PhaseTwo.begin)
end

return DefaultRound
