--#region Imports

-- Services

local ReplicatedStorage = game:GetService "ReplicatedStorage"

-- Source

local DataReplication = require(ReplicatedStorage.Shared.Data.DataReplication)

--#endregion

DataReplication.registerActionAsync "SetHomes"
