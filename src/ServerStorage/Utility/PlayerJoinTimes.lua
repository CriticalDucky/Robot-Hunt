local list = {}
local calculated = {}
-- Add a player joined table here

local PlayerJoinTimes = {} -- Number of times a player has joined this server

function PlayerJoinTimes.getTimesJoined(player: Player)
    assert(typeof(player) == "Instance" and player:IsA("Player"), "PlayerJoinTimes.getTimesJoined: player must be a Player")

    if not calculated[player] then
        calculated[player] = true

        local timesJoined = list[player.UserId] or 0

        list[player.UserId] = timesJoined + 1
    end

    return list[player.UserId]
end

return PlayerJoinTimes
