local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ReplicatedFirst = game:GetService "ReplicatedFirst"

local RoundConfiguration = require(ReplicatedStorage.Configuration.RoundConfiguration)
local Table = require(ReplicatedFirst.Utility.Table)
local Enums = require(ReplicatedFirst.Enums)

hunterToRebelRatio = RoundConfiguration.hunterToRebelRatio

--[[
    Sorts the players into teams based on the hunterToRebelRatio
    @param players The players to sort
    @return A table containing the sorted players
]]
return function(players): {number: {Player}}
	assert(#players >= 2, "There must be at least 2 players to start a round")

    local sorted = {
        [Enums.TeamType.rebels] = {}
    }

	local numHunters = math.ceil(#players * hunterToRebelRatio)
	local hunters = Table.randomArraySelection(players, numHunters)

    sorted[Enums.TeamType.hunters] = hunters

    for _, player in ipairs(players) do
        if not table.find(hunters, player) then
            table.insert(sorted[Enums.TeamType.rebels], player)
        end
    end

    return sorted
end
