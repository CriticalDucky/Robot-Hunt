--!strict

--#region Imports

local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local ReplicatedStorageData = ReplicatedStorage:WaitForChild "Data"

local ClientState = require(ReplicatedStorageData:WaitForChild "ClientState")
local ClientServerCommunication = require(ReplicatedStorageData:WaitForChild "ClientServerCommunication")
local Types = require(ReplicatedFirst:WaitForChild("Utility"):WaitForChild "Types")

type PlayerPersistentData = Types.PlayerPersistentData

--#endregion

ClientServerCommunication.registerActionAsync("InitializeClientState", function(data: PlayerPersistentData)
    ClientState.currency.money:set(data.currency.money)
    ClientState.inventory.accessories:set(data.inventory.accessories)
    ClientState.settings.musicVolume:set(data.settings.musicVolume)
    ClientState.settings.sfxVolume:set(data.settings.sfxVolume)
end)
