--#region Imports

local ReplicatedFirst = game:GetService "ReplicatedFirst"
local RunService = game:GetService "RunService"

assert(RunService:IsClient(), "ClientState can only be required on the client.")

local Fusion = require(ReplicatedFirst:WaitForChild("Vendor"):WaitForChild "Fusion")

local Types = require(ReplicatedFirst:WaitForChild("Utility"):WaitForChild "Types")

type PlayerPersistentData = Types.PlayerPersistentData

local Value = Fusion.Value

--#endregion

--[[
	A submodule of `PlayerData` storing the client's state.

	---

	For proper server replication when modifying player data, use the `PlayerData` module.
]]
local ClientState = {
	currency = {
		money = Value(),
	},

	external = {
		publicPlayerData = Value(),
		worldPopulationList = Value(),
		roundData = Value(),
	},

	inventory = {
		accessories = Value(),
	},

	settings = {
		musicVolume = Value(),
		sfxVolume = Value(),
	},
}

return ClientState
