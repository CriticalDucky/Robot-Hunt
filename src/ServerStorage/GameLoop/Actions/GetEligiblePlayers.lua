local ServerStorage = game:GetService "ServerStorage"

local PlayerDataManager = require(ServerStorage.Data.PlayerDataManager)

return function()
    -- TODO: Add an AFK check
    return PlayerDataManager.getPlayersWithDataLoaded()
end