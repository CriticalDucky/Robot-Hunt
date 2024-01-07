--!strict

local ReplicatedFirst = game:GetService("ReplicatedFirst")

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
    players: {
        [number]: {
            playerId: number,

            -- True if the player is alive, false if they are dead
            alive: boolean,

            -- The player's current health (0-100)
            health: number,
        }?,
    },
}

local roundData: RoundData = {
    currentRoundType = nil,
    currentPhaseType = Enums.PhaseType.NotEnoughPlayers,
    phaseStartTime = nil,

    players = {},
}

local RoundDataManager = {}

RoundDataManager.data = roundData

--[[
    Retrieves the round data and returns a filtered version of it for the client.
]]
function RoundDataManager.getFilteredData()
    local filteredData = {}

    filteredData.currentRoundType = roundData.currentRoundType
    filteredData.currentPhaseType = roundData.currentPhaseType
    filteredData.phaseStartTime = roundData.phaseStartTime

    return filteredData
end

return RoundDataManager