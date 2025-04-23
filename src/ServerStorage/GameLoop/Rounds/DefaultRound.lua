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
local Promise = require(ReplicatedFirst.Vendor.Promise)
local Table = require(ReplicatedFirst.Utility.Table)

type RoundBatteryData = Types.RoundBatteryData
type RoundTerminalData = Types.RoundTerminalData

local teams = {
	[Enums.TeamType.rebels] = Teams:WaitForChild "Rebels",
	[Enums.TeamType.hunters] = Teams:WaitForChild "Hunters",
}

local DefaultRound = {}

function DefaultRound.begin()
	return Promise.new(function(resolve, reject, onCancel)
		local playerDatas = {}
		local connections = {} :: { RBXScriptConnection }

		local numRequiredTerminals: number

		local promise = Modules.DefaultRound.Loading
			.begin()
			:andThen(function()
				-- At this point the map should be ready for players to spawn in

				local playingPlayers = Actions.getEligiblePlayers()
				local sorted = Actions.sortPlayers(playingPlayers)

				for teamType, players: { Player } in pairs(sorted) do
					for _, player in players do
						local data = RoundDataManager.createNewPlayerData(player, teamType)

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
				local numDesiredTerminals = math.min(totalTerminals, #terminalModels)

				numRequiredTerminals = math.min(numRequiredTerminals, #terminalModels)

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

					model:WaitForChild("Id").Value = i

					data.hackers = {}

					data.isPuzzleMode = false
					data.puzzleQueue = {}

					data.progress = 0
					data.cooldown = 0
					data.isErrored = false

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

				-- may the best team win >;)
			end)
			:andThen(function()
				-- Resolves once enough terminals are hacked
				local terminalsHackedPromise = Promise.fromEvent(RoundDataManager.onTerminalDataUpdated, function()
					local numTerminalsHacked = 0

					for _, terminalData in pairs(RoundDataManager.data.terminalData) do
						if terminalData.progress >= 100 then
							numTerminalsHacked += 1
						end
					end

					if numTerminalsHacked >= numRequiredTerminals then
						return true
					else
						return false
					end
				end)

				return Promise.race {
					terminalsHackedPromise,
					Modules.DefaultRound.Infiltration
						.begin()
						:andThenCall(Modules.DefaultRound.PhaseOne.begin)
						:andThenCall(Modules.DefaultRound.Purge.begin)
						:andThenReturn(false)
				}
			end)
			:andThen(function(terminalsComplete: boolean)
				if terminalsComplete then
					return Modules.DefaultRound.PhaseTwo.begin()
				else
					return -- Tie
				end
			end)
			:catch(function(err) print("Error in default round: " .. err) end)

		local playerStatusChangedConnection = RoundDataManager.onPlayerStatusUpdated:Connect(function()
			local numActiveHunters = 0
			local numActiveRebels = 0

			for _, playerData in pairs(playerDatas) do
				if playerData.status == Enums.PlayerStatus.dead then continue end
				if playerData.status == Enums.PlayerStatus.lifeSupport then continue end

				if playerData.team == Enums.TeamType.hunters then
					numActiveHunters += 1
				else
					numActiveRebels += 1
				end
			end

			if numActiveHunters == 0 or numActiveRebels == 0 then
				print("Canceling round because one team is dead: " .. numActiveHunters .. " " .. numActiveRebels)
				promise:cancel()

				for _, connection in pairs(connections) do
					connection:Disconnect()
				end

				resolve(Modules.DefaultRound.GameOver.begin())
			end
		end)

		table.insert(connections, playerStatusChangedConnection)

		onCancel(function()
			print "Cancelling round"

			promise:cancel()

			for _, connection in pairs(connections) do
				connection:Disconnect()
			end
		end)

		promise:andThen(function()
			for _, connection in pairs(connections) do
				connection:Disconnect()
			end

			resolve(Modules.DefaultRound.GameOver.begin())
		end)
	end)
end

return DefaultRound
