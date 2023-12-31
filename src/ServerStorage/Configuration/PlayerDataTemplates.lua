--!strict

local ReplicatedFirst = game:GetService "ReplicatedFirst"

local Enums = require(ReplicatedFirst.Shared.Enums)
local Types = require(ReplicatedFirst.Shared.Utility.Types)

type PlayerPersistentData = Types.PlayerPersistentData
type PlayerTempData = Types.PlayerTempData

type PlayerDataTemplates = {
	persistentDataTemplate: PlayerPersistentData,
	tempDataTemplate: PlayerTempData,
}

--[[
	Configuration for player data.
]]
local PlayerDataTemplates: PlayerDataTemplates = {
	persistentDataTemplate = {
		currency = {
			money = 0,
		},

		home = {},

		inventory = {
			accessories = {},
			furniture = {},
			homes = {},
		},

		settings = {
			findOpenWorld = true,
			homeLock = Enums.HomeLockType.unlocked,
			musicVolume = 1,
			sfxVolume = 1,
		},
	},
	tempDataTemplate = {},
}

return PlayerDataTemplates
