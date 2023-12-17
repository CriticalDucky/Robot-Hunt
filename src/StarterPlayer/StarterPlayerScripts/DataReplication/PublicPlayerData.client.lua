--#region Imports

-- Services

local ReplicatedStorage = game:GetService "ReplicatedStorage"

-- Source

local replicatedStorageSharedData = ReplicatedStorage:WaitForChild("Shared"):WaitForChild "Data"

local DataReplication = require(replicatedStorageSharedData:WaitForChild "DataReplication")

--#endregion

DataReplication.registerActionAsync "SubscribeToPersistentData"
