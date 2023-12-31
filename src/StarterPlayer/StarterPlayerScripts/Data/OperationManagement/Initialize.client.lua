--!strict

--#region Imports

local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local replicatedFirstShared = ReplicatedFirst:WaitForChild "Shared"
local ReplicatedStorageShared = ReplicatedStorage:WaitForChild "Shared"
local ReplicatedStorageSharedData = ReplicatedStorageShared:WaitForChild "Data"

local ClientState = require(ReplicatedStorageSharedData:WaitForChild "ClientState")
local ClientServerCommunication = require(ReplicatedStorageSharedData:WaitForChild "ClientServerCommunication")
local Types = require(replicatedFirstShared:WaitForChild("Utility"):WaitForChild "Types")

type PlayerPersistentData = Types.PlayerPersistentData

--#endregion

ClientServerCommunication.registerActionAsync("InitializeClientState", function(data: PlayerPersistentData)
    ClientState.currency.money:set(data.currency.money)
    ClientState.home.selected:set(data.home.selected)
    ClientState.inventory.accessories:set(data.inventory.accessories)
    ClientState.inventory.furniture:set(data.inventory.furniture)
    ClientState.inventory.homes:set(data.inventory.homes)
    ClientState.settings.findOpenWorld:set(data.settings.findOpenWorld)
    ClientState.settings.homeLock:set(data.settings.homeLock)
    ClientState.settings.musicVolume:set(data.settings.musicVolume)
    ClientState.settings.sfxVolume:set(data.settings.sfxVolume)
end)
