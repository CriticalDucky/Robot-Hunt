--!strict

--#region Imports

local ReplicatedStorage = game:GetService "ReplicatedStorage"

local replicatedStorageSharedData = ReplicatedStorage:WaitForChild("Shared"):WaitForChild "Data"

local ClientState = require(replicatedStorageSharedData:WaitForChild "ClientState")
local ClientServerCommunication = require(replicatedStorageSharedData:WaitForChild "ClientServerCommunication")

--#endregion

ClientServerCommunication.registerActionAsync("UpdateWorldPopulationList", function(worldPopulationList)
    ClientState.external.worldPopulationList:set(worldPopulationList)
end)