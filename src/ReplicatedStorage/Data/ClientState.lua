--#region Imports

local Players = game:GetService "Players"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local RunService = game:GetService "RunService"

assert(RunService:IsClient(), "ClientState can only be required on the client")

local Fusion = require(ReplicatedFirst:WaitForChild("Vendor"):WaitForChild "Fusion")

local ReplicaCollection = require(ReplicatedStorage:WaitForChild("Replication"):WaitForChild "ReplicaCollection")

local Value = Fusion.Value

local player = Players.LocalPlayer

--#endregion

--#region Private Player Data

local privatePlayerData = ReplicaCollection.waitForReplica(`PrivatePlayerData{player.UserId}`).Data

--#endregion

--#region Public Player Data

local publicPlayerData = ReplicaCollection.waitForReplica("PublicPlayerData").Data

local publicPlayerDataState = Value(publicPlayerData)

publicPlayerData:ListenToRaw(function(action) publicPlayerDataState:set(publicPlayerData) end)

--#endregion

--[[
	A submodule of `PlayerData` storing the client's state.

	---

	For proper server replication when modifying player data, use the `PlayerData` module.
]]
local ClientState = {
	currency = {
		money = Value(privatePlayerData.currency.money),
	},

	inventory = {
		accessories = Value(privatePlayerData.inventory.accessories),
	},

	publicPlayerData = publicPlayerDataState,

	settings = {
		musicVolume = Value(privatePlayerData.settings.musicVolume),
		sfxVolume = Value(privatePlayerData.settings.sfxVolume),
	},
}

return ClientState
