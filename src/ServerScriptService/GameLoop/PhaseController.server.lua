--!strict

--[[
    This file controls the main loop of the game. It decides when a round is started, and if a round can start.
]]

--#region Imports

local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ServerStorage = game:GetService "ServerStorage"
local RunService = game:GetService "RunService"

local GameLoop = ServerStorage.GameLoop

local RoundConfiguration = require(ReplicatedStorage.Configuration.RoundConfiguration)
local Rounds = require(ServerStorage.GameLoop.Rounds)
local Modules = require(ServerStorage.GameLoop.Modules)
local PlayerDataManager = require(ServerStorage.Data.PlayerDataManager)
local Types = require(ReplicatedFirst.Utility.Types)
local Enums = require(ReplicatedFirst.Enums)
local Actions = require(GameLoop.Actions)
local RoundData = require(GameLoop.RoundData)

local RoundType = Enums.RoundType
local PhaseType = Enums.PhaseType

type Promise = Types.Promise

--#endregion

local currentRoundPromise: Promise? = nil
local isResults: boolean = false

local function enoughPlayers()
	return #PlayerDataManager.getPlayersWithDataLoaded() >= RoundConfiguration.minPlayers
end

local function loop()
	if not currentRoundPromise and enoughPlayers() and not isResults then
		currentRoundPromise = Modules.Intermission
			.begin()
			:andThen(function() return Rounds[RoundType.defaultRound].begin() end)

		assert(currentRoundPromise)

		currentRoundPromise:finally(function()
			print "Results started"

			isResults = true
			currentRoundPromise = nil
			
			RoundData.data.currentPhaseType = Enums.PhaseType.Hiding
			RoundData.data.currentRoundType = nil
			RoundData.data.phaseStartTime = os.time()
			Actions.replicateRoundData()

			task.wait(RoundConfiguration.timeLengths.lobby[PhaseType.Results])

			print "Results ended"

			isResults = false

			if enoughPlayers() then
				loop()
			else
				print "Not enough players, waiting for more"

				RoundData.data.currentPhaseType = Enums.PhaseType.NotEnoughPlayers
				RoundData.data.phaseStartTime = nil
				Actions.replicateRoundData()
			end
		end)
	elseif currentRoundPromise and not enoughPlayers() and not isResults then
		currentRoundPromise:cancel()
		currentRoundPromise = nil
	elseif currentRoundPromise and enoughPlayers() then
		-- Do nothing; we're already in a round
	elseif isResults then
		-- Do nothing; we're in results and nothing can change that
	else
		print(currentRoundPromise, enoughPlayers())
	end
end

RunService.Heartbeat:Connect(loop)
