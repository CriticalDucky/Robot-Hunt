--#region Imports

-- Services

local ReplicatedStorage = game:GetService "ReplicatedStorage"
local RunService = game:GetService "RunService"
local ServerStorage = game:GetService "ServerStorage"

local isServer = RunService:IsServer()

-- Source

local replicatedStorageData = ReplicatedStorage:WaitForChild "Data"

local PlayerDataManager = if isServer then require(ServerStorage.Data.PlayerDataManager) else nil
local ClientState = if not isServer then require(replicatedStorageData:WaitForChild "ClientState") else nil
local ClientServerCommunication = require(replicatedStorageData:WaitForChild "ClientServerCommunication")

--#endregion

--[[
	A submodule of `PlayerData` that handles the player's settings.
]]
local Settings = {}

--[[
	Sets the player's *Music Volume* setting.

	---

	The given volume must be a number between 0 and 1.

	The player parameter is **required** on the server and **ignored** on the client.
]]
function Settings.setSettingMusicVolume(volume: number, player: Player?)
	if isServer and not player then
		error "A player must be provided when calling from the server."
	elseif not isServer and player then
		warn "No player needs to be given when calling from the client, so this parameter will be ignored."
	end

	if isServer then
		PlayerDataManager.setValuePersistentAsync(player, { "settings", "musicVolume" }, volume)
		ClientServerCommunication.replicateAsync("SetSettingMusicVolume", volume, player)
	else
		ClientState.playerSettings.musicVolume:set(volume)
		ClientServerCommunication.replicateAsync("SetSettingMusicVolume", volume)
	end
end

--[[
	Sets the player's *SFX Volume* setting.

	---

	The given volume must be a number between 0 and 1.

	The player parameter is **required** on the server and **ignored** on the client.
]]
function Settings.setSettingSFXVolume(volume: number, player: Player?)
	if isServer and not player then
		error "A player must be provided when calling from the server."
	elseif not isServer and player then
		warn "No player needs to be given when calling from the client, so this parameter will be ignored."
	end

	if isServer then
		PlayerDataManager.setValuePersistentAsync(player, { "settings", "sfxVolume" }, volume)
		ClientServerCommunication.replicateAsync("SetSettingSFXVolume", volume, player)
	else
		ClientState.playerSettings.sfxVolume:set(volume)
		ClientServerCommunication.replicateAsync("SetSettingSFXVolume", volume)
	end
end

return Settings
