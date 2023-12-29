--!strict

--#region Imports

local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerStorage = game:GetService "ServerStorage"

local DataReplication = require(ReplicatedStorage.Data.DataReplication)
local PlayerDataManager = require(ServerStorage.Data.PlayerDataManager)
local Types = require(ReplicatedFirst.Utility.Types)

type PlayerPersistentData = Types.PlayerPersistentData

--#endregion

DataReplication.registerActionAsync("SetSettingMusicVolume", function(player: Player, value: number)
	if typeof(value) ~= "number" or value ~= value or value ~= math.clamp(value, 0, 1) then
		DataReplication.replicateAsync(
			"SetSettingMusicVolume",
			(PlayerDataManager.viewPersistentData(player) :: PlayerPersistentData).settings.musicVolume,
			player
		)

		return
	end

	PlayerDataManager.setValuePersistent(player, { "settings", "musicVolume" }, value)
end)

DataReplication.registerActionAsync("SetSettingSFXVolume", function(player: Player, value: number)
	if typeof(value) ~= "number" or value ~= value or value ~= math.clamp(value, 0, 1) then
		DataReplication.replicateAsync(
			"SetSettingSFXVolume",
			(PlayerDataManager.viewPersistentData(player) :: PlayerPersistentData).settings.sfxVolume,
			player
		)

		return
	end

	PlayerDataManager.setValuePersistent(player, { "settings", "sfxVolume" }, value)
end)
