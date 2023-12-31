--!strict

--#region Imports

local ReplicatedStorage = game:GetService "ReplicatedStorage"

local ClientServerCommunication = require(ReplicatedStorage.Data.ClientServerCommunication)

--#endregion

ClientServerCommunication.registerActionAsync("UpdateWorldPopulationList")
