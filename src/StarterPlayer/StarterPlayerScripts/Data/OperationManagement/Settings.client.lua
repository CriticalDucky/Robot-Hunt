--!strict

--#region Imports

local ReplicatedStorage = game:GetService "ReplicatedStorage"

local replicatedStorageSharedData = ReplicatedStorage:WaitForChild("Shared"):WaitForChild "Data"

local ClientState = require(replicatedStorageSharedData:WaitForChild "ClientState")
local ClientServerCommunication = require(replicatedStorageSharedData:WaitForChild "ClientServerCommunication")

--#endregion

ClientServerCommunication.registerActionAsync(
	"SetSettingFindOpenWorld",
	function(value: boolean) ClientState.settings.findOpenWorld:set(value) end
)

ClientServerCommunication.registerActionAsync(
	"SetSettingHomeLock",
	function(value: number) ClientState.settings.homeLock:set(value) end
)

ClientServerCommunication.registerActionAsync(
	"SetSettingMusicVolume",
	function(value: number) ClientState.settings.musicVolume:set(value) end
)

ClientServerCommunication.registerActionAsync(
	"SetSettingSFXVolume",
	function(value: number) ClientState.settings.sfxVolume:set(value) end
)
