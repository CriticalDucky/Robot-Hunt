--!strict

--#region Imports

local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerStorage = game:GetService "ServerStorage"

local DataReplication = require(ReplicatedStorage.Shared.Data.DataReplication)
local HomeLockType = require(ReplicatedFirst.Shared.Enums.HomeLockType)
local PlayerDataManager = require(ServerStorage.Shared.Data.PlayerDataManager)
local Types = require(ReplicatedFirst.Shared.Utility.Types)

type PlayerPersistentData = Types.PlayerPersistentData

--#endregion

DataReplication.registerActionAsync("SetSettingHomeLock", function(player: Player, value: number)
	local validValue = false

	for _, enumValue in pairs(HomeLockType) do
		if value == enumValue then
			validValue = true
			break
		end
	end

	if not validValue then
		DataReplication.replicateAsync(
			"SetSettingHomeLock",
			(PlayerDataManager.viewPersistentData(player) :: PlayerPersistentData).settings.homeLock,
			player
		)

		return
	end

	PlayerDataManager.setValuePersistent(player, { "settings", "homeLock" }, value)
end)

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
