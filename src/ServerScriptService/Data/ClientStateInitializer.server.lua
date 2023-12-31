--!strict

--#region Imports

local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerStorage = game:GetService "ServerStorage"

local ClientServerCommunication = require(ReplicatedStorage.Shared.Data.ClientServerCommunication)
local PlayerDataManager = require(ServerStorage.Shared.Data.PlayerDataManager)

--#endregion

local function initializeClientState(player, persistentData)
	ClientServerCommunication.replicateAsync("InitializeClientState", persistentData, player)
end

for _, player in pairs(PlayerDataManager.getPlayersWithLoadedPersistentData()) do
	initializeClientState(player, PlayerDataManager.getPersistentData(player))
end

PlayerDataManager.persistentDataLoaded:Connect(initializeClientState)
