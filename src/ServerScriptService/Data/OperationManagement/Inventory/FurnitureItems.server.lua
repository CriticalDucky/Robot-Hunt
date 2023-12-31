--#region Imports

local ReplicatedStorage = game:GetService "ReplicatedStorage"

local ClientServerCommunication = require(ReplicatedStorage.Shared.Data.ClientServerCommunication)

--#endregion

ClientServerCommunication.registerActionAsync "SetFurniture"
