--!strict

--#region Imports

local ReplicatedStorage = game:GetService "ReplicatedStorage"

local replicatedStorageData = ReplicatedStorage:WaitForChild "Data"

local ClientState = require(replicatedStorageData:WaitForChild "ClientState")
local ClientServerCommunication = require(replicatedStorageData:WaitForChild "ClientServerCommunication")

--#endregion

ClientServerCommunication.registerActionAsync("SetMoney", function(amount) ClientState.currency.money:set(amount) end)
