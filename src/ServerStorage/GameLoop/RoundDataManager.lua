--!strict

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Players = game:GetService "Players"

local ClientServerCommunication = require(ReplicatedStorage.Data.ClientServerCommunication)

local Enums = require(ReplicatedFirst.Enums)

type RoundData = {
    -- The current round type enum (Enums.RoundType)
    currentRoundType: number?,
    -- The current phase type enum (Enums.PhaseType)
    currentPhaseType: number?,
    -- The Unix timestamp of when the phase started
    phaseStartTime: number?,

    --[[
        An array players in the round.
        Round player data is not deleted when a player leaves the round, but alive is set to false.
    ]]
    publicPlayerData: {
        {
            playerId: number,

            -- True if the player is alive, false if they are dead
            alive: boolean,

            -- The player's current health (0-100)
            health: number,
        }?
    },

    --[[
        An array of private player data.
        Private player data is deleted when a player leaves the round.
    ]]
    privatePlayerData: {
        {
            playerId: number,

            data: {
                
            },
        }?
    },
}

local roundData: RoundData = {
    currentRoundType = nil,
    currentPhaseType = Enums.PhaseType.NotEnoughPlayers,
    phaseStartTime = nil,

    publicPlayerData = {},
    privatePlayerData = {},
}

local RoundDataManager = {}

RoundDataManager.data = roundData

--[[
    Retrieves the round data and returns a filtered version of it for the client.
]]
function RoundDataManager.getFilteredData(player: Player)
    local filteredData = {}

    filteredData.currentRoundType = roundData.currentRoundType
    filteredData.currentPhaseType = roundData.currentPhaseType
    filteredData.phaseStartTime = roundData.phaseStartTime
    filteredData.publicPlayerData = roundData.publicPlayerData

    for _, playerData in ipairs(roundData.privatePlayerData) do
        assert(playerData)

        if playerData.playerId == player.UserId then
            filteredData.privatePlayerData = playerData.data

            break
        end
    end

    return filteredData
end

function RoundDataManager.replicateDataAsync(player: Player?)
    local players = if player then { player } else Players:GetPlayers()

    for _, player in ipairs(players) do
        ClientServerCommunication.replicateAsync("UpdateRoundData", RoundDataManager.getFilteredData(player), player)
    end
end

return RoundDataManager