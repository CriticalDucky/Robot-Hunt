--!strict

local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Players = game:GetService "Players"

local ClientServerCommunication = require(ReplicatedStorage.Data.ClientServerCommunication)

local Enums = require(ReplicatedFirst.Enums)

type PlayerData = {
	playerId: number,

	-- True if the player is alive, false if they are dead
	alive: boolean,

	-- The player's current health (0-100)
	health: number,
}

type RoundData = {
	-- The current round type enum (Enums.RoundType)
	currentRoundType: number?,

	-- The current phase type enum (Enums.PhaseType)
	currentPhaseType: number?,

	-- The Unix timestamp of when the phase should end
	phaseEndTime: number?,

	playerData: { PlayerData },
}

local roundData: RoundData = {
	currentRoundType = nil,
	currentPhaseType = Enums.PhaseType.NotEnoughPlayers,
	phaseEndTime = nil,

	playerData = {},
}

local RoundDataManager = {}

RoundDataManager.data = roundData

function RoundDataManager.filterPlayerData(playerData: PlayerData, player: Player)
	return {
		playerId = playerData.playerId,
		alive = playerData.alive,
		health = playerData.health,
	}
end

--[[
    Retrieves the round data and returns a filtered version of it for the client.
]]
function RoundDataManager.getFilteredData(player: Player)
	local filteredData = {}

	filteredData.currentRoundType = roundData.currentRoundType
	filteredData.currentPhaseType = roundData.currentPhaseType
	filteredData.phaseEndTime = roundData.phaseEndTime
	
    filteredData.playerData = {}

    for _, playerData in ipairs(roundData.playerData) do
        table.insert(filteredData.playerData, RoundDataManager.filterPlayerData(playerData, player))
    end

	return filteredData
end

function RoundDataManager.initializedRoundDataAsync(player: Player?)
	local players = if player then { player } else Players:GetPlayers()

	for _, player in ipairs(players) do
		ClientServerCommunication.replicateAsync("InitializeRoundData", RoundDataManager.getFilteredData(player), player)
	end
end

function RoundDataManager.replicateRoundTypeAsync()
	ClientServerCommunication.replicateAsync("UpdateRoundType", roundData.currentRoundType)
end

function RoundDataManager.replicatePhaseTypeAsync()
	ClientServerCommunication.replicateAsync("UpdatePhaseType", roundData.currentPhaseType)
end

function RoundDataManager.replicatePhaseEndTimeAsync()
	ClientServerCommunication.replicateAsync("UpdatePhaseEndTime", roundData.phaseEndTime)
end

--[[
    Replicates round player data to all clients.

    If targetPlayer is provided, only replicate the data for that player.
]]
function RoundDataManager.replicatePlayerDataAsync(targetPlayer: Player?)
    local playerData: PlayerData?

    if targetPlayer then
        for _, data in ipairs(roundData.playerData) do
            if data.playerId == targetPlayer.UserId then
                playerData = data
                break
            end
        end

        if playerData then
            playerData = RoundDataManager.filterPlayerData(playerData, targetPlayer)
        end
    end

    local data = {
        playerData = playerData or {},
        targetPlayerId = targetPlayer and targetPlayer.UserId or nil,
    }

    for _, player in ipairs(Players:GetPlayers()) do
        if not targetPlayer then
            local filteredPlayerDatas = {}

            for _, newData in ipairs(roundData.playerData) do
                table.insert(filteredPlayerDatas, RoundDataManager.filterPlayerData(newData, player))
            end

            data.playerData = filteredPlayerDatas
        end

        ClientServerCommunication.replicateAsync("UpdatePlayerData", data, player)
    end
end

return RoundDataManager
