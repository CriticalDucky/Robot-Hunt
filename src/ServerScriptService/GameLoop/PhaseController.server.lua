--!strict

--[[
    This file controls the main loop of the game. It decides when a round is started, and if a round can start.
]]

--#region Imports

local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ServerStorage = game:GetService "ServerStorage"
local RunService = game:GetService "RunService"
local Players = game:GetService "Players"
local Teams = game:GetService "Teams"

local GameLoop = ServerStorage.GameLoop

local RoundConfiguration = require(ReplicatedStorage.Configuration.RoundConfiguration)
local Rounds = require(ServerStorage.GameLoop.Rounds)
local Modules = require(ServerStorage.GameLoop.Modules)
local Types = require(ReplicatedFirst.Utility.Types)
local Enums = require(ReplicatedFirst.Enums)
local Actions = require(GameLoop.Actions)
local RoundDataManager = require(GameLoop.RoundDataManager)

local RoundType = Enums.RoundType
local PhaseType = Enums.PhaseType

type Promise = Types.Promise

--#endregion

local currentRoundPromise: Promise? = nil
local isResults: boolean = false

local function enoughPlayers() return #Actions.getEligiblePlayers() >= RoundConfiguration.minPlayers end

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

			local resultsEndTime = os.time() + RoundConfiguration.timeLengths.lobby[PhaseType.Results]

			-- RoundDataManager.setPhaseToResultsAsync(resultsEndTime)

			for _, playerData in pairs(RoundDataManager.data.playerData) do
				local player = Players:GetPlayerByUserId(playerData.playerId or 1)

				if player then
					player.Team = Teams.Lobby
				end

				player:LoadCharacter()
			end

			repeat
				RunService.Heartbeat:Wait()
			until os.time() >= resultsEndTime

			print "Results ended"

			isResults = false

			local map = workspace:FindFirstChild("Map")

			if map then
				map:Destroy()
			end

			if enoughPlayers() then
				loop()
			else
				print "Not enough players, waiting for more"

				-- RoundDataManager.setPhaseToNotEnoughPlayersAsync()
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
		-- Do nothing; we're waiting for more players
	end
end

RunService.Heartbeat:Connect(loop)
