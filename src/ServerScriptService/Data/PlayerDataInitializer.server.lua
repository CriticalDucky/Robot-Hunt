--!strict

--#region Imports

local ServerStorage = game:GetService "ServerStorage"

local PlayerDataManager = require(ServerStorage.Data.PlayerDataManager)

--#endregion

local function initializePersistentData(player: Player)
	local data = PlayerDataManager.getPersistentData(player)
	assert(data)
	-- TODO: Handle persistent data initialization failure
end

for _, player in pairs(PlayerDataManager.getPlayersWithLoadedPersistentData()) do
	initializePersistentData(player)
end

PlayerDataManager.persistentDataLoaded:Connect(initializePersistentData)
