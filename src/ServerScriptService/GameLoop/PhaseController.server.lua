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

local RoundConfiguration = require(ReplicatedStorage.Configuration.RoundConfiguration)
local Rounds = require(ServerStorage.GameLoop.Rounds)
local Modules = require(ServerStorage.GameLoop.Modules)
local PlayerDataManager = require(ServerStorage.Data.PlayerDataManager)
local Types = require(ReplicatedFirst.Utility.Types)
local Promise = require(ReplicatedFirst.Vendor.Promise)

type Promise = Types.Promise

--#endregion

local currentPhasePromise: Promise? = nil
local isResults: boolean = false

local function enoughPlayers()
	local playerCount = 0

	for _, player in Players:GetPlayers() do
		local character = player.Character
		local isDataLoaded = true -- PlayerDataManager.persistentDataIsLoaded(player)
		--and PlayerDataManager.tempDataIsLoaded(player)

		if (character and character.Parent == workspace) and isDataLoaded then
			playerCount += 1
		end
	end

	return playerCount >= RoundConfiguration.minPlayers
end

local function loop()
	if not currentPhasePromise and enoughPlayers() then
		currentPhasePromise = Modules.Intermission
			.begin()
			:andThen(function() return Rounds.DefaultRound.begin() end)
			:finally(function()
				print "Results started"

				isResults = true

				task.wait(RoundConfiguration.resultsLength)
			end)
			:finally(function()
				currentPhasePromise = nil
				isResults = false

				if enoughPlayers() then
					loop()
				else
					print "Not enough players, waiting for more"
				end
			end)
	elseif currentPhasePromise and not enoughPlayers() and not isResults then
        print("canceling promise")
		currentPhasePromise:cancel()
		currentPhasePromise = nil
	elseif currentPhasePromise and enoughPlayers() then
		-- Do nothing; we're already in a round
	else -- not currentPhasePromise and not enoughPlayers() and not isResults
		print(currentPhasePromise, enoughPlayers())
	end
end

RunService.Heartbeat:Connect(loop)
