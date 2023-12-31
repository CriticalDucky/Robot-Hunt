--#region Imports

local ReplicatedFirst = game:GetService "ReplicatedFirst"
local RunService = game:GetService "RunService"

assert(RunService:IsClient(), "ClientState can only be required on the client.")

local Fusion = require(ReplicatedFirst:WaitForChild("Vendor"):WaitForChild "Fusion")

local Types = require(ReplicatedFirst:WaitForChild("Shared"):WaitForChild("Utility"):WaitForChild "Types")

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
	},

	home = {
		selected = Value(),
	},

	inventory = {
		accessories = Value(),
		furniture = Value(),
		homes = Value(),
	},

	settings = {
		findOpenWorld = Value(),
		homeLock = Value(),
		musicVolume = Value(),
		sfxVolume = Value(),
	},
}

return ClientState
