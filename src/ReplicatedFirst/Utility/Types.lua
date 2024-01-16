--!strict

local ReplicatedFirst = game:GetService "ReplicatedFirst"

local replicatedFirstVendor = ReplicatedFirst:WaitForChild "Vendor"

local Promise = require(replicatedFirstVendor:WaitForChild "Promise")
local Fusion = require(replicatedFirstVendor:WaitForChild "Fusion")

export type ItemAccessory = {
	type: number,
}

type Use = Fusion.Use

export type ItemCategory = { InventoryItem }

export type UserEnum = string | number

export type Profile = {
	Data: PlayerPersistentData,
	Release: (Profile) -> (),
	AddUserId: (Profile, number) -> (),
	Reconcile: (Profile) -> (),
	ListenToRelease: (Profile, () -> ()) -> (),
}

export type DataTreeArray = { DataTreeValue }

export type DataTreeDictionary = { [string]: DataTreeValue }

export type DataTreeValue = number | string | boolean | nil | DataTreeArray | DataTreeDictionary

export type PlayerPersistentData = {
	currency: {
		money: number,
	},
	inventory: {
		accessories: { [string]: ItemAccessory? },
	},
	settings: {
		musicVolume: number,
		sfxVolume: number,
	},
}

export type PlayerPersistentDataPublic = {
	inventory: {
		accessories: { [string]: ItemAccessory? },
	},
}

export type RoundPlayerData = {
	playerId: number,

	-- The players current status enum (Enums.PlayerStatus). The player is alive, dead, or in life support.
	status: number,

	-- The playerId of the last player to attack this player
	lastAttackerId: number?,
	killedById: number?,
	-- The list of userids that are attacking this player.
	attackers: { number },

    -- The player's current team enum (Enums.TeamType)
    team: number,

	-- The player's current health, armor, life support (0-100)
	health: number,
	armor: number,
	lifeSupport: number,

	-- The player's ammo
	ammo: number?,

	-- The position the player is shooting. Only exists on the client
	gunHitPosition: Vector3?,

	-- The player's various actions.
	actions: {
		-- Whether or not the player is shooting
		isShooting: boolean,

		-- Whether or not the player is hacking
		isHacking: boolean,
	},

	-- The player's round statistics
	stats: {
		-- The total damage the player has dealt
		damageDealt: number,

		-- The total kills the player has
		kills: number,
	},
}

export type PlayerTempData = {}

export type TimeRange = {
	introduction: number | { [any]: any },
	closing: number | { [any]: any },
	isInRange: (TimeRange, timeInfo: TimeInfo?, Use) -> boolean,
	distanceToClosing: (TimeRange, timeInfo: TimeInfo?, Use) -> number,
	distanceToIntroduction: (TimeRange, timeInfo: TimeInfo?, Use) -> number,
	isATimeRange: true,
}

export type TimeInfo = number | (
) -> TimeInfo | {
	year: number?,
	month: number?,
	day: number?,
	hour: number?,
	min: number?,
	sec: number?,
}

export type InventoryItem = {
	id: string,
	itemCategory: UserEnum,
	itemEnum: string | number,
	permanent: boolean?,
}

export type Promise = typeof(Promise.new(function() end))

return nil
