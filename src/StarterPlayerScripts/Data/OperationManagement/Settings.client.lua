--!strict

--#region Imports

local ReplicatedStorage = game:GetService "ReplicatedStorage"

local replicatedStorageData = ReplicatedStorage:WaitForChild "Data"

local ClientState = require(replicatedStorageData:WaitForChild "ClientState")
local ClientServerCommunication = require(replicatedStorageData:WaitForChild "ClientServerCommunication")

--#endregion

ClientServerCommunication.registerActionAsync(
	"SetSettingMusicVolume",
	function(value: number) ClientState.settings.musicVolume:set(value) end
)

ClientServerCommunication.registerActionAsync(
	"SetSettingSFXVolume",
	function(value: number) ClientState.settings.sfxVolume:set(value) end
)
