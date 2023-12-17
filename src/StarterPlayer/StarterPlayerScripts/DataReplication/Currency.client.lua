--#region Imports

local ReplicatedStorage = game:GetService "ReplicatedStorage"

local replicatedStorageSharedData = ReplicatedStorage:WaitForChild("Shared"):WaitForChild "Data"

local ClientState = require(replicatedStorageSharedData:WaitForChild "ClientState")
local DataReplication = require(replicatedStorageSharedData:WaitForChild "DataReplication")

--#endregion

DataReplication.registerActionAsync("SetMoney", function(amount) ClientState.currency.money:set(amount) end)
