local ServerStorage = game:GetService "ServerStorage"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local Teams = game:GetService "Teams"

local GameLoop = ServerStorage.GameLoop

local Enums = require(ReplicatedFirst.Enums)
local Modules = require(GameLoop.Modules)
local Actions = require(GameLoop.Actions)
local RoundDataManager = require(GameLoop.RoundDataManager)

local teams = {
	[Enums.TeamType.rebels] = Teams:WaitForChild("Rebels"),
	[Enums.TeamType.hunters] = Teams:WaitForChild("Hunters"),
}

local DefaultRound = {}

function DefaultRound.begin()
	local playingPlayers = Actions.getEligiblePlayers()
	local sorted = Actions.sortPlayers(playingPlayers)

	local playerDatas = {}

	for teamType, players: {Player} in pairs(sorted) do
		for _, player in players do
			player.Team = teams[teamType]

			local data = RoundDataManager.newPlayerData(player, teamType)

			playerDatas[player.UserId] = data
		end
	end

	return Modules.DefaultRound.Loading
		.begin()
		:andThenCall(Modules.DefaultRound.Infiltration.begin)
		:andThenCall(Modules.DefaultRound.PhaseOne.begin)
        :andThenCall(Modules.DefaultRound.PhaseTwo.begin)
end

return DefaultRound
