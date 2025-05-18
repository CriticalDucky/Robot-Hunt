--#region Imports

local ReplicatedFirst = game:GetService "ReplicatedFirst"
local RunService = game:GetService "RunService"

assert(RunService:IsClient(), "ClientState can only be required on the client.")

local Fusion = require(ReplicatedFirst:WaitForChild("Vendor"):WaitForChild "Fusion")

local Types = require(ReplicatedFirst:WaitForChild("Utility"):WaitForChild "Types")
local Enums = require(ReplicatedFirst:WaitForChild("Enums"))

type PlayerPersistentData = Types.PlayerPersistentData
type RoundPlayerData = Types.RoundPlayerData
type RoundBatteryData = Types.RoundBatteryData
type RoundTerminalData = Types.RoundTerminalData
type Value<T> = Fusion.Value<T>

local scope = Fusion.scoped(Fusion)

--#endregion

--[[
	A submodule of `PlayerData` storing the client's state.

	---

	For proper server replication when modifying player data, use the `PlayerData` module.
]]
local ClientState = {
	currency = {
		money = scope:Value(nil :: number?),
	},

	external = {
		publicPlayerData = scope:Value(),
		roundData = {
			currentRoundType = scope:Value(nil :: number?),
			currentPhaseType = scope:Value(nil :: number?),
			phaseEndTime = scope:Value(nil :: number?),
			isGameOver = scope:Value(false :: boolean),

			batteryData = scope:Value({nil :: RoundBatteryData?}),
			terminalData = scope:Value({nil :: RoundTerminalData?}),

			playerData = scope:Value({nil :: RoundPlayerData?}),
		},
	},

	inventory = {
		accessories = scope:Value(),
	},

	settings = {
		musicVolume = scope:Value(1 :: number),
		sfxVolume = scope:Value(1 :: number),
	},

	actions = {
		parkourState = scope:Value(Enums.ParkourState.grounded),
		isSpectating = scope:Value(false :: boolean),
	}
}

return ClientState
