--!strict

local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Players = game:GetService "Players"

local ClientServerCommunication = require(ReplicatedStorage.Data.ClientServerCommunication)
local RoundConfiguration = require(ReplicatedStorage.Configuration.RoundConfiguration)

local Enums = require(ReplicatedFirst.Enums)
local PhaseType = Enums.PhaseType

type PlayerData = {
	playerId: number,

	-- The players current status enum (Enums.PlayerStatus)
	status: number,

    -- The player's current team enum (Enums.TeamType)
    team: number,

	-- The player's current health (0-100)
	health: number,
    
    -- The player's current life support (0-100)
    lifeSupport: number,
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

local function filterPlayerData(playerData: PlayerData, player: Player)
	return {
		playerId = playerData.playerId,
		status = playerData.status,
        team = playerData.team,
		health = playerData.health,
        lifeSupport = playerData.lifeSupport,
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

    ClientServerCommunication.replicateAsync("SetPhaseToNotEnoughPlayers")
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
            playerData = filterPlayerData(playerData, targetPlayer)
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
                table.insert(filteredPlayerDatas, filterPlayerData(newData, player))
            end

            data.playerData = filteredPlayerDatas
        end

        ClientServerCommunication.replicateAsync("UpdatePlayerData", data, player)
    end
end

return RoundDataManager
