--!strict

--#region Imports

local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerStorage = game:GetService "ServerStorage"

local ClientServerCommunication = require(ReplicatedStorage.Shared.Data.ClientServerCommunication)
local HomeLockType = require(ReplicatedFirst.Shared.Enums.HomeLockType)
local PlayerDataManager = require(ServerStorage.Shared.Data.PlayerDataManager)
local Types = require(ReplicatedFirst.Shared.Utility.Types)

type PlayerPersistentData = Types.PlayerPersistentData

--#endregion

ClientServerCommunication.registerActionAsync("SetSettingFindOpenWorld", function(player: Player, value)
	local data = PlayerDataManager.getPersistentData(player)
	assert(data)

	if typeof(value) ~= "boolean" then
		ClientServerCommunication.replicateAsync("SetSettingFindOpenWorld", data.settings.findOpenWorld, player)
		return
	end

	data.settings.findOpenWorld = value
end)

ClientServerCommunication.registerActionAsync("SetSettingHomeLock", function(player: Player, value)
	local data = PlayerDataManager.getPersistentData(player)
	assert(data)

	local validValue = false

	for _, enumValue in pairs(HomeLockType) do
		if value == enumValue then
			validValue = true
			break
		end
	end

	if not validValue then
		ClientServerCommunication.replicateAsync("SetSettingHomeLock", data.settings.homeLock, player)
		return
	end

	assert(typeof(value) == "number")

	data.settings.homeLock = value
end)

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
