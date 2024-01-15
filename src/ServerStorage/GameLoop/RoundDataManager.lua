--!strict

local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Players = game:GetService "Players"

local ClientServerCommunication = require(ReplicatedStorage.Data.ClientServerCommunication)
local RoundConfiguration = require(ReplicatedStorage.Configuration.RoundConfiguration)

local Enums = require(ReplicatedFirst.Enums)
local Types = require(ReplicatedFirst.Utility.Types)
local PhaseType = Enums.PhaseType

type RoundPlayerData = Types.RoundPlayerData
type RoundPlayerDataStatus = RoundPlayerData

type RoundData = {
	-- The current round type enum (Enums.RoundType)
	currentRoundType: number?,

	-- The current phase type enum (Enums.PhaseType)
	currentPhaseType: number,

	-- The Unix timestamp of when the phase should end
	phaseEndTime: number?,

	playerData: { RoundPlayerData },
}

local roundData: RoundData = {
	currentRoundType = nil,
	currentPhaseType = Enums.PhaseType.NotEnoughPlayers,
	phaseEndTime = nil,

	playerData = {},
}

local function filterPlayerData(playerData: RoundPlayerData, player: Player)
	return {
		playerId = playerData.playerId,

        status = playerData.status,

		lastAttackerId = playerData.lastAttackerId,
		killedById = playerData.killedById,
        attackers = playerData.attackers,
		
		team = playerData.team,

		health = playerData.health,
        armor = playerData.armor,
		lifeSupport = playerData.lifeSupport,

        ammo = playerData.ammo,

        gunData = if playerData.playerId ~= player.UserId then playerData.gunData else nil,
		
		stats = playerData.stats,
	}
end

--[[
    Retrieves the round data and returns a filtered version of it for the client.
]]
function filterData(player: Player)
	local filteredData = {}

	filteredData.currentRoundType = roundData.currentRoundType
	filteredData.currentPhaseType = roundData.currentPhaseType
	filteredData.phaseEndTime = roundData.phaseEndTime

	filteredData.playerData = {}

	for _, playerData in ipairs(roundData.playerData) do
		table.insert(filteredData.playerData, filterPlayerData(playerData, player))
	end

	return filteredData
end

local RoundDataManager = {}

RoundDataManager.data = roundData

function RoundDataManager.initializedRoundDataAsync(player: Player?)
	local players = if player then { player } else Players:GetPlayers()

	for _, player in ipairs(players) do
		ClientServerCommunication.replicateAsync("InitializeRoundData", filterData(player), player)
	end
end

function RoundDataManager.setPhaseToResultsAsync(endTime: number)
	roundData.currentPhaseType = PhaseType.Results
	roundData.currentRoundType = nil
	roundData.phaseEndTime = endTime

	ClientServerCommunication.replicateAsync("SetPhaseToResults", {
		phaseEndTime = endTime,
	})
end

function RoundDataManager.setPhaseToIntermissionAsync(endTime)
	roundData.currentPhaseType = PhaseType.Intermission
	roundData.phaseEndTime = endTime

	table.clear(roundData.playerData)

	ClientServerCommunication.replicateAsync("SetPhaseToIntermission", {
		phaseEndTime = endTime,
	})
end

function RoundDataManager.setPhaseToNotEnoughPlayersAsync()
	roundData.currentPhaseType = PhaseType.NotEnoughPlayers
	roundData.phaseEndTime = nil

	ClientServerCommunication.replicateAsync "SetPhaseToNotEnoughPlayers"
end

--[[
    Replicates round player data to all clients.

    If targetPlayer is provided, only replicate the data for that player.
]]
function RoundDataManager.replicatePlayerDataAsync(targetPlayer: Player?)
	local playerData: RoundPlayerData?

	if targetPlayer then
		for _, data in ipairs(roundData.playerData) do
			if data.playerId == targetPlayer.UserId then
				playerData = data
				break
			end
		end

		if playerData then playerData = filterPlayerData(playerData, targetPlayer) end
	end

	local data = {
		playerData = playerData or {},
		targetPlayerId = targetPlayer and targetPlayer.UserId or nil,
	}

	for _, player in ipairs(Players:GetPlayers()) do
		if not targetPlayer then
			local filteredPlayerDatas = {}

			for _, newData in ipairs(roundData.playerData) do
				table.insert(filteredPlayerDatas, filterPlayerData(newData, player))
			end

			data.playerData = filteredPlayerDatas
		end

		ClientServerCommunication.replicateAsync("UpdatePlayerData", data, player)
	end
end

return RoundDataManager
