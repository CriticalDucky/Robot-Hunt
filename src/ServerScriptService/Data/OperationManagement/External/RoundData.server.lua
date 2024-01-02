--!strict

--#region Imports

local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerStorage = game:GetService "ServerStorage"

local ClientServerCommunication = require(ReplicatedStorage.Data.ClientServerCommunication)
local RoundData = require(ServerStorage.GameLoop.RoundData)

--#endregion

ClientServerCommunication.registerActionAsync("UpdateRoundData", function(player: Player, value)
    ClientServerCommunication.replicateAsync("UpdateRoundData", RoundData.getFilteredData(), player)
end)