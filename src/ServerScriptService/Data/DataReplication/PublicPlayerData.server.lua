--#region Imports

local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerStorage = game:GetService "ServerStorage"

local DataReplication = require(ReplicatedStorage.Data.DataReplication)
local PlayerDataManager = require(ServerStorage.Data.PlayerDataManager)

--#endregion

DataReplication.registerActionAsync(
	"SubscribeToPersistentData",
	function(player, userId) PlayerDataManager.subscribePlayerToPersistentData(player, userId) end
)
