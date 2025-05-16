--!strict

--#region Imports

local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local replicatedFirstVendor = ReplicatedFirst:WaitForChild("Vendor")
local replicatedStorageData = ReplicatedStorage:WaitForChild "Data"

local Fusion = require(replicatedFirstVendor:WaitForChild "Fusion")

local ClientState = require(replicatedStorageData:WaitForChild "ClientState")
local ClientServerCommunication = require(replicatedStorageData:WaitForChild "ClientServerCommunication")

local peek = Fusion.peek

--#endregion

ClientServerCommunication.registerActionAsync("UpdatePublicPlayerData", function(publicPlayerDataInfo)
    local publicPlayerDataDictionary = peek(ClientState.external.publicPlayerData)

    publicPlayerDataDictionary[publicPlayerDataInfo.userId] = publicPlayerDataInfo.data

    ClientState.external.publicPlayerData:set(publicPlayerDataDictionary)
end)