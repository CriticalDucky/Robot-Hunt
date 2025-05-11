--!strict

--[[
    This file controls the main loop of the game. It decides when a round is started, and if a round can start.
]]

--#region Imports

local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ServerStorage = game:GetService "ServerStorage"
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

local function enoughPlayers() return #Actions.getEligiblePlayers() >= RoundConfiguration.minPlayers end

while true do
	if not enoughPlayers() then
		if RoundDataManager.data.currentPhaseType ~= PhaseType.NotEnoughPlayers then
			print("Not enough players to start a round")
			RoundDataManager.setPhase(PhaseType.NotEnoughPlayers)
		end

		task.wait()

		continue
	end

	Modules.Intermission.begin():await() -- Wait for intermission to finish

	if not enoughPlayers() then continue end

	currentRoundPromise = Rounds[RoundType.defaultRound].begin()

	assert(currentRoundPromise)

	currentRoundPromise:await()
	currentRoundPromise = nil

	for _, playerData in pairs(RoundDataManager.data.playerData) do
		local player = Players:GetPlayerByUserId(playerData.playerId or 1)

		if player and player.Team ~= Teams.Lobby then
			player.Team = Teams.Lobby
			RoundDataManager.registerLobbyTeleport(player, false)
			player:LoadCharacter()
		end
	end

	Modules.Results.begin():await() -- Wait for results to finish

	local map = workspace:FindFirstChild "Map"

	if map then map:Destroy() end
end
