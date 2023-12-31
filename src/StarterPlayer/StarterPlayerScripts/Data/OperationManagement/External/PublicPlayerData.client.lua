--!strict

--#region Imports

local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local replicatedFirstVendor = ReplicatedFirst:WaitForChild("Vendor")
local replicatedStorageSharedData = ReplicatedStorage:WaitForChild("Shared"):WaitForChild "Data"

local Fusion = require(replicatedFirstVendor:WaitForChild "Fusion")

local ClientState = require(replicatedStorageSharedData:WaitForChild "ClientState")
local ClientServerCommunication = require(replicatedStorageSharedData:WaitForChild "ClientServerCommunication")

local peek = Fusion.peek

--#endregion

ClientServerCommunication.registerActionAsync("UpdatePublicPlayerData", function(publicPlayerDataInfo)
    local publicPlayerDataDictionary = peek(ClientState.external.publicPlayerData)

    publicPlayerDataDictionary[publicPlayerDataInfo.userId] = publicPlayerDataInfo.data

    ClientState.external.publicPlayerData:set(publicPlayerDataDictionary)
end)