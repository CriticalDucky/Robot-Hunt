--#region Imports

local ReplicatedStorage = game:GetService "ReplicatedStorage"

local DataReplication = require(ReplicatedStorage.Data.DataReplication)

--#endregion

DataReplication.registerActionAsync("SetMoney")