--#region Imports

local ReplicatedFirst = game:GetService "ReplicatedFirst"
local RunService = game:GetService "RunService"

assert(RunService:IsClient(), "ClientState can only be required on the client.")

local Fusion = require(ReplicatedFirst:WaitForChild("Vendor"):WaitForChild "Fusion")

local Types = require(ReplicatedFirst:WaitForChild("Utility"):WaitForChild "Types")

type PlayerPersistentData = Types.PlayerPersistentData
type RoundPlayerData = Types.RoundPlayerData
type Value<T> = Fusion.Value<T>

local Value = Fusion.Value
local peek = Fusion.peek

--#endregion

--[[
	A submodule of `PlayerData` storing the client's state.

	---

	For proper server replication when modifying player data, use the `PlayerData` module.
]]
local ClientState = {
	currency = {
		money = Value(nil :: number?),
	},

	external = {
		publicPlayerData = Value(),
		roundData = {
			currentRoundType = Value(nil :: number?),
			currentPhaseType = Value(nil :: number?),
			phaseEndTime = Value(nil :: number?),

			playerData = Value({nil :: RoundPlayerData?}),
		},
	},

	inventory = {
		accessories = Value(),
	},

	settings = {
		musicVolume = Value(1 :: number),
		sfxVolume = Value(1 :: number),
	},

	actions = {
		isCrawling = Value(false :: boolean),
		isHacking = Value(false :: boolean),
		isShooting = Value(false :: boolean),
	}
}

return ClientState
