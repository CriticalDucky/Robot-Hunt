--#region Imports

-- Services

local ReplicatedStorage = game:GetService "ReplicatedStorage"

-- Source

local replicatedStorageSharedData = ReplicatedStorage:WaitForChild("Shared"):WaitForChild "Data"

local ClientState = require(replicatedStorageSharedData:WaitForChild "ClientState")
local DataReplication = require(replicatedStorageSharedData:WaitForChild "DataReplication")

--#endregion

DataReplication.registerActionAsync(
	"SetSettingFindOpenWorld",
	function(value: boolean) ClientState.settings.findOpenWorld:set(value) end
)

DataReplication.registerActionAsync(
	"SetSettingHomeLock",
	function(value: number) ClientState.settings.homeLock:set(value) end
)

DataReplication.registerActionAsync(
	"SetSettingMusicVolume",
	function(value: number) ClientState.settings.musicVolume:set(value) end
)

DataReplication.registerActionAsync(
	"SetSettingSFXVolume",
	function(value: number) ClientState.settings.sfxVolume:set(value) end
)
