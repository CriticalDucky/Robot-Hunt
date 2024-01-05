--!strict

--#region Imports

local ReplicatedStorage = game:GetService "ReplicatedStorage"

local replicatedStorageData = ReplicatedStorage:WaitForChild "Data"

local ClientState = require(replicatedStorageData:WaitForChild "ClientState")
local ClientServerCommunication = require(replicatedStorageData:WaitForChild "ClientServerCommunication")

--#endregion

ClientServerCommunication.registerActionAsync("UpdateRoundData", function(roundData)
    ClientState.external.roundData:set(roundData)
end)

ClientServerCommunication.replicateAsync "UpdateRoundData"