--!strict

--#region Imports

local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerStorage = game:GetService "ServerStorage"

local ClientServerCommunication = require(ReplicatedStorage.Data.ClientServerCommunication)
local PlayerDataManager = require(ServerStorage.Data.PlayerDataManager)
local Types = require(ReplicatedFirst.Utility.Types)

type PlayerPersistentData = Types.PlayerPersistentData

--#endregion

ClientServerCommunication.registerActionAsync("SetSettingMusicVolume", function(player: Player, value)
	local data = PlayerDataManager.getPersistentData(player)
	assert(data)

	if typeof(value) ~= "number" or value ~= value or value ~= math.clamp(value, 0, 1) then
		ClientServerCommunication.replicateAsync("SetSettingMusicVolume", data.settings.musicVolume, player)
		return
	end

	data.settings.musicVolume = value
end)

ClientServerCommunication.registerActionAsync("SetSettingSFXVolume", function(player: Player, value)
	local data = PlayerDataManager.getPersistentData(player)
	assert(data)

	if typeof(value) ~= "number" or value ~= value or value ~= math.clamp(value, 0, 1) then
		ClientServerCommunication.replicateAsync("SetSettingSFXVolume", data.settings.sfxVolume, player)
		return
	end

	data.settings.sfxVolume = value
end)
