--#region Imports

local ReplicatedStorage = game:GetService "ReplicatedStorage"

local DataReplication = require(ReplicatedStorage.Shared.Data.DataReplication)

--#endregion

DataReplication.registerActionAsync("SetMoney")