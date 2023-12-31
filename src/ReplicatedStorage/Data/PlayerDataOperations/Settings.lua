--#region Imports

-- Services

local ReplicatedStorage = game:GetService "ReplicatedStorage"
local RunService = game:GetService "RunService"
local ServerStorage = game:GetService "ServerStorage"

local isServer = RunService:IsServer()

-- Source

local replicatedStorageSharedData = ReplicatedStorage:WaitForChild("Shared"):WaitForChild "Data"

local PlayerDataManager = if isServer then require(ServerStorage.Shared.Data.PlayerDataManager) else nil
local ClientState = if not isServer then require(replicatedStorageSharedData:WaitForChild "ClientState") else nil
local ClientServerCommunication = require(replicatedStorageSharedData:WaitForChild "ClientServerCommunication")

--#endregion

--[[
	A submodule of `PlayerData` that handles the player's settings.
]]
local Settings = {}

--[[
	Sets the player's *Find Open World* setting.

	---

	The player parameter is **required** on the server and **ignored** on the client.
]]
function Settings.setSettingFindOpenWorld(value: boolean, player: Player?)
	if isServer and not player then
		warn "A player must be provided when calling from the server."
		return
	elseif not isServer and player then
		warn "No player needs to be given when calling from the client, so this parameter will be ignored."
	end

	if isServer then
		PlayerDataManager.setValuePersistentAsync(player, { "settings", "findOpenWorld" }, value)
		ClientServerCommunication.replicateAsync("SetSettingFindOpenWorld", value, player)
	else
		ClientState.playerSettings.findOpenWorld:set(value)
		ClientServerCommunication.replicateAsync("SetSettingFindOpenWorld", value)
	end
end

--[[
	Sets the player's *Home Lock* setting.

	---

	The given home lock type must be a valid `HomeLockType` enum value.

	The player parameter is **required** on the server and **ignored** on the client.
]]
function Settings.setSettingHomeLock(homeLockType: number, player: Player?)
	if isServer and not player then
		warn "A player must be provided when calling from the server."
		return
	elseif not isServer and player then
		warn "No player needs to be given when calling from the client, so this parameter will be ignored."
	end

	if isServer then
		PlayerDataManager.setValuePersistentAsync(player, { "settings", "homeLock" }, homeLockType)
		ClientServerCommunication.replicateAsync("SetSettingHomeLock", homeLockType, player)
	else
		ClientState.playerSettings.homeLock:set(homeLockType)
		ClientServerCommunication.replicateAsync("SetSettingHomeLock", homeLockType)
	end
end

--[[
	Sets the player's *Music Volume* setting.

	---

	The given volume must be a number between 0 and 1.

	The player parameter is **required** on the server and **ignored** on the client.
]]
function Settings.setSettingMusicVolume(volume: number, player: Player?)
	if isServer and not player then
		warn "A player must be provided when calling from the server."
		return
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
		warn "A player must be provided when calling from the server."
		return
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
