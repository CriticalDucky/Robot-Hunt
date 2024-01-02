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
}

local roundData: RoundData = {
    currentRoundType = nil,
    currentPhaseType = Enums.PhaseType.NotEnoughPlayers,
    phaseStartTime = nil,
}

local RoundDataController = {}

RoundDataController.data = roundData

--[[
    Retrieves the round data and returns a filtered version of it for the client.
]]
function RoundDataController.getFilteredData()
    local filteredData = {}

    filteredData.currentRoundType = roundData.currentRoundType
    filteredData.currentPhaseType = roundData.currentPhaseType
    filteredData.phaseStartTime = roundData.phaseStartTime

    return filteredData
end

return RoundDataController