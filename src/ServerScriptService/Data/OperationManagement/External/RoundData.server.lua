--!strict

--#region Imports

local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerStorage = game:GetService "ServerStorage"

local ClientServerCommunication = require(ReplicatedStorage.Data.ClientServerCommunication)
local RoundDataManager = require(ServerStorage.GameLoop.RoundDataManager)

--#endregion

ClientServerCommunication.registerActionAsync("UpdateRoundData", function(player: Player)
    RoundDataManager.replicateDataAsync(player)
end)