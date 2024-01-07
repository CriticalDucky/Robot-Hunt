--!strict

--#region Imports

local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerStorage = game:GetService "ServerStorage"

local ClientServerCommunication = require(ReplicatedStorage.Data.ClientServerCommunication)
local RoundDataManager = require(ServerStorage.GameLoop.RoundDataManager)

--#endregion

ClientServerCommunication.registerActionAsync("InitializeRoundData", function(player: Player)
    RoundDataManager.initializedRoundDataAsync(player)
end)

ClientServerCommunication.registerActionAsync("UpdateRoundType")

ClientServerCommunication.registerActionAsync("UpdatePhaseType")

ClientServerCommunication.registerActionAsync("UpdatePhaseEndTime")

ClientServerCommunication.registerActionAsync("UpdatePlayerData")