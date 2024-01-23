local ServerStorage = game:GetService "ServerStorage"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Teams = game:GetService "Teams"
local Players = game:GetService "Players"

local GameLoop = ServerStorage.GameLoop

local Enums = require(ReplicatedFirst.Enums)
local Modules = require(GameLoop.Modules)
local Actions = require(GameLoop.Actions)
local RoundDataManager = require(GameLoop.RoundDataManager)
local RoundConfiguration = require(ReplicatedStorage.Configuration.RoundConfiguration)

local teams = {
	[Enums.TeamType.rebels] = Teams:WaitForChild "Rebels",
	[Enums.TeamType.hunters] = Teams:WaitForChild "Hunters",
}

local DefaultRound = {}

function DefaultRound.begin()
	local playingPlayers = Actions.getEligiblePlayers()
	local sorted = Actions.sortPlayers(playingPlayers)

	local playerDatas = {}

	for teamType, players: { Player } in pairs(sorted) do
		for _, player in players do
			player.Team = teams[teamType]

			local data = RoundDataManager.newPlayerData(player, teamType)

			playerDatas[player.UserId] = data
		end
	end

	local numRequiredTerminals
	do
		local numPlayers = #sorted[Enums.TeamType.rebels]

		numRequiredTerminals = math.clamp(numPlayers, RoundConfiguration.minTerminals, RoundConfiguration.maxTerminals)
	end

	local totalTerminals = numRequiredTerminals + RoundConfiguration.extraTerminals
	local batteryPercentage = math.random(
		RoundConfiguration.batteryLowerPercentage * 1000,
		RoundConfiguration.batteryUpperPercentage * 1000
	) / 1000

	return Modules.DefaultRound.Loading
		.begin({
			numTerminals = totalTerminals,
			batteryPercentage = batteryPercentage,
		})
		:andThen(function()
			-- At this point the map should be ready for players to spawn in

			for playerId, _ in pairs(playerDatas) do
				local player = Players:GetPlayerByUserId(playerId)

				if player then player:LoadCharacter() end
			end
		end)
		:andThenCall(Modules.DefaultRound.Infiltration.begin)
		:andThenCall(Modules.DefaultRound.PhaseOne.begin)
		:andThenCall(Modules.DefaultRound.PhaseTwo.begin)
end

return DefaultRound
