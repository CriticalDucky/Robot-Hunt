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
local Types = require(ReplicatedFirst.Utility.Types)

type RoundBatteryData = Types.RoundBatteryData
type RoundTerminalData = Types.RoundTerminalData

local teams = {
	[Enums.TeamType.rebels] = Teams:WaitForChild "Rebels",
	[Enums.TeamType.hunters] = Teams:WaitForChild "Hunters",
}

local DefaultRound = {}

function DefaultRound.begin()
	local playerDatas = {}

	local numRequiredTerminals: number

	return Modules.DefaultRound.Loading
		.begin()
		:andThen(function()
			-- At this point the map should be ready for players to spawn in

			local playingPlayers = Actions.getEligiblePlayers()
			local sorted = Actions.sortPlayers(playingPlayers)

			for teamType, players: { Player } in pairs(sorted) do
				for _, player in players do
					local data = RoundDataManager.newPlayerData(player, teamType)

					playerDatas[player.UserId] = data
				end
			end

			do
				local numPlayers = #sorted[Enums.TeamType.rebels]

				numRequiredTerminals =
					math.clamp(numPlayers, RoundConfiguration.minTerminals, RoundConfiguration.maxTerminals)
			end

			local totalTerminals = numRequiredTerminals + RoundConfiguration.extraTerminals
			local batteryPercentage = math.random(
				RoundConfiguration.batteryLowerPercentage * 1000,
				RoundConfiguration.batteryUpperPercentage * 1000
			) / 1000

			local map = workspace:FindFirstChild "Map"
			assert(map, "Map not found")

			local batteriesFolder = map:FindFirstChild "Batteries"
			assert(batteriesFolder, "Batteries folder not found")

			local terminalsFolder = map:FindFirstChild "Terminals"
			assert(terminalsFolder, "Terminals folder not found")

			local batteryModels = batteriesFolder:GetChildren()
			local terminalModels = terminalsFolder:GetChildren()

			local numDesiredBatteries = math.ceil(#batteryModels * batteryPercentage)
			local numDesiredTerminals = math.max(totalTerminals, #terminalModels)

			-- now we delete some of the models to get the desired amount (make sure its random)

			local function deleteRandomModels(folder: Folder, numDesired: number)
				local models = folder:GetChildren()

				for i = 1, #models - numDesired do
					local model = models[math.random(1, #models)]

					model:Destroy()
				end
			end

			deleteRandomModels(batteriesFolder, numDesiredBatteries)
			deleteRandomModels(terminalsFolder, numDesiredTerminals)

			-- now we get the models again

			batteryModels = batteriesFolder:GetChildren()
			terminalModels = terminalsFolder:GetChildren()

			-- now we create the data for the terminals

			local terminalData = {}

			for i, model in pairs(terminalModels) do
				local data = {} :: RoundTerminalData

				data.id = i
				data.model = model
				data.status = Enums.TerminalStatus.notHacked

				table.insert(terminalData, data)
			end

			-- now we create the data for the batteries

			local batteryData = {}

			for i, model in pairs(batteryModels) do
				local data = {} :: RoundBatteryData

				data.id = i
				data.model = model

				table.insert(batteryData, data)
			end

			-- now we create the round data

			RoundDataManager.setUpRound(Enums.RoundType.defaultRound, playerDatas, terminalData, batteryData)

			for playerId, data in pairs(playerDatas) do
				local player = Players:GetPlayerByUserId(playerId)

				if player then
					player.Team = teams[data.team]
					player:LoadCharacter()
				end
			end

			-- may the best team win >:)
		end)
		:andThenCall(Modules.DefaultRound.Infiltration.begin)
		:andThenCall(Modules.DefaultRound.PhaseOne.begin)
		:andThen(function()
			local function enoughTerminalsHacked()
				local numTerminalsHacked = 0

				for _, terminalData in RoundDataManager.data.terminalData do
					if terminalData.status == Enums.TerminalStatus.hacked then
						numTerminalsHacked += 1
					end
				end

				if numTerminalsHacked >= numRequiredTerminals then
					return true
				else
					return false
				end
			end

			if enoughTerminalsHacked() then
				return Modules.DefaultRound.PhaseTwo.begin()
			else -- uh oh
				return Modules.DefaultRound.Purge.begin():andThen(function()
					if enoughTerminalsHacked() then
						return Modules.DefaultRound.PhaseTwo.begin()
					else
						-- Tie

						return
					end
				end)
			end
		end)
end

return DefaultRound
