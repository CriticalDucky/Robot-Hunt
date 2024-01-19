--!strict

local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Players = game:GetService "Players"

local ClientServerCommunication = require(ReplicatedStorage.Data.ClientServerCommunication)
local RoundConfiguration = require(ReplicatedStorage.Configuration.RoundConfiguration)

local Enums = require(ReplicatedFirst.Enums)
local Types = require(ReplicatedFirst.Utility.Types)
local PhaseType = Enums.PhaseType

type RoundPlayerData = Types.RoundPlayerData

type RoundData = {
	-- The current round type enum (Enums.RoundType)
	currentRoundType: number?,

	-- The current phase type enum (Enums.PhaseType)
	currentPhaseType: number,

	-- The Unix timestamp of when the phase should end
	phaseEndTime: number?,

	playerData: {
		[number --[[userId]]]: RoundPlayerData,
	},
}

local roundData: RoundData = {
	currentRoundType = nil,
	currentPhaseType = Enums.PhaseType.NotEnoughPlayers,
	phaseEndTime = nil,

	playerData = {},
}

local function filterPlayerData(playerData: RoundPlayerData, player: Player): RoundPlayerData
	return {
		playerId = playerData.playerId,

		status = playerData.status,

		lastAttackerId = playerData.lastAttackerId,
		killedById = playerData.killedById,
		attackers = playerData.attackers,

		team = playerData.team,

		health = playerData.health,
		armor = playerData.armor,
		lifeSupport = playerData.lifeSupport,

		ammo = playerData.ammo,

		gunHitPosition = if playerData.playerId ~= player.UserId then playerData.gunHitPosition else nil,

		actions = playerData.actions,

		stats = playerData.stats,
	}
end

--[[
    Retrieves the round data and returns a filtered version of it for the client.
]]
function filterData(player: Player)
	local filteredData = {}

	filteredData.currentRoundType = roundData.currentRoundType
	filteredData.currentPhaseType = roundData.currentPhaseType
	filteredData.phaseEndTime = roundData.phaseEndTime

	filteredData.playerData = {}

	for _, playerData in ipairs(roundData.playerData) do
		table.insert(filteredData.playerData, filterPlayerData(playerData, player))
	end

	return filteredData
end

local RoundDataManager = {}

RoundDataManager.data = roundData

function RoundDataManager.initializedRoundDataAsync(player: Player?)
	local players = if player then { player } else Players:GetPlayers()

	for _, player in ipairs(players) do
		ClientServerCommunication.replicateAsync("InitializeRoundData", filterData(player), player)
	end
end

function RoundDataManager.setPhaseToResultsAsync(endTime: number)
	roundData.currentPhaseType = PhaseType.Results
	roundData.currentRoundType = nil
	roundData.phaseEndTime = endTime

	ClientServerCommunication.replicateAsync("SetPhase", {
		phaseType = PhaseType.Results,
		phaseEndTime = endTime,
	})
end

function RoundDataManager.setPhaseToIntermissionAsync(endTime)
	roundData.currentPhaseType = PhaseType.Intermission
	roundData.phaseEndTime = endTime

	table.clear(roundData.playerData)

	ClientServerCommunication.replicateAsync("SetPhase", {
		phaseType = PhaseType.Intermission,
		phaseEndTime = endTime,
	})
end

function RoundDataManager.setPhaseToLoadingAsync(endTime)
	roundData.currentPhaseType = PhaseType.Loading
	roundData.phaseEndTime = endTime

	table.clear(roundData.playerData)

	ClientServerCommunication.replicateAsync("SetPhase", {
		phaseType = PhaseType.Loading,
		phaseEndTime = endTime,
	})
end

function RoundDataManager.setPhaseToNotEnoughPlayersAsync()
	roundData.currentPhaseType = PhaseType.NotEnoughPlayers
	roundData.phaseEndTime = nil

	ClientServerCommunication.replicateAsync "SetPhase" {
		phaseType = PhaseType.NotEnoughPlayers,
	}
end

function RoundDataManager.newPlayerData(player: Player, team: number): RoundPlayerData
	return {
		playerId = player.UserId,

		status = Enums.PlayerStatus.alive,

		lastAttackerId = nil,
		killedById = nil,
		attackers = {},

		team = team,

		health = 100,
		armor = 0,
		lifeSupport = 100,

		ammo = 100,

		gunHitPosition = nil,

		actions = {
			isHacking = false,
			isShooting = false,
		},

		stats = {
			damageDealt = 0,
			kills = 0,
		},
	}
end

function RoundDataManager.addAttacker(victim: Player, attacker: Player)
	local victimData = roundData.playerData[victim.UserId]

	assert(victimData, "Victim data does not exist")

	victimData.lastAttackerId = attacker.UserId
	victimData.attackers[attacker.UserId] = true

	ClientServerCommunication.replicateAsync("updateAttackers", {
		victimId = victim.UserId,
		attackers = victimData.attackers,
	})
end

function RoundDataManager.removeAttacker(victim: Player, attacker: Player)
	local victimData = roundData.playerData[victim.UserId]

	assert(victimData, "Victim data does not exist")

	victimData.attackers[attacker.UserId] = nil

	ClientServerCommunication.replicateAsync("updateAttackers", {
		victimId = victim.UserId,
		attackers = victimData.attackers,
	})
end

function RoundDataManager.killPlayer(victim: Player, killer: Player?)
	local playerData = roundData.playerData[victim.UserId]

	assert(playerData, "Player data does not exist")

	playerData.status = Enums.PlayerStatus.dead
	playerData.health = 0
	playerData.armor = 0
	playerData.lifeSupport = 0

	if killer then
		playerData.killedById = killer and killer.UserId or nil

		local killerData = roundData.playerData[killer.UserId]

		killerData.stats.kills += 1
	end

	ClientServerCommunication.replicateAsync("killPlayer", {
		victimId = victim.UserId,
		killedById = playerData.killedById,
	})
end

function RoundDataManager.revivePlayer(player: Player)
	local playerData = roundData.playerData[player.UserId]

	assert(playerData, "Player data does not exist")

	playerData.status = Enums.PlayerStatus.alive
	playerData.health = 100
	playerData.armor = 0
	playerData.lifeSupport = 100

	ClientServerCommunication.replicateAsync("revivePlayer", {
		playerId = player.UserId,
	})
end

function RoundDataManager.setHealth(player: Player, health: number)
	local playerData = roundData.playerData[player.UserId]

	assert(health >= 0 and health <= 100, "Health must be between 0 and 100")

	playerData.health = health

	ClientServerCommunication.replicateAsync("updateHealth", {
		playerId = player.UserId,
		health = health,
	})
end

function RoundDataManager.incrementHealth(player: Player, amount: number)
	local playerData = roundData.playerData[player.UserId]

	assert(playerData, "Player data does not exist")
	assert(playerData.health + amount >= 0 and playerData.health + amount <= 100, "Health must be between 0 and 100")

	playerData.health += amount

	ClientServerCommunication.replicateAsync("updateHealth", {
		playerId = player.UserId,
		health = playerData.health,
	})
end

function RoundDataManager.setLifeSupport(player: Player, lifeSupport: number)
	local playerData = roundData.playerData[player.UserId]

	assert(lifeSupport >= 0 and lifeSupport <= 100, "Life support must be between 0 and 100")

	playerData.lifeSupport = lifeSupport

	ClientServerCommunication.replicateAsync("updateLifeSupport", {
		playerId = player.UserId,
		lifeSupport = lifeSupport,
	})
end

function RoundDataManager.incrementLifeSupport(player: Player, amount: number)
	local playerData = roundData.playerData[player.UserId]

	assert(playerData, "Player data does not exist")
	assert(
		playerData.lifeSupport + amount >= 0 and playerData.lifeSupport + amount <= 100,
		"Life support must be between 0 and 100"
	)

	playerData.lifeSupport += amount

	ClientServerCommunication.replicateAsync("updateLifeSupport", {
		playerId = player.UserId,
		lifeSupport = playerData.lifeSupport,
	})
end

function RoundDataManager.setArmor(player: Player, armor: number)
	local playerData = roundData.playerData[player.UserId]

	assert(playerData, "Player data does not exist")
	assert(armor >= 0 and armor <= 100, "Armor must be between 0 and 100")

	playerData.armor = armor

	ClientServerCommunication.replicateAsync("updateArmor", {
		playerId = player.UserId,
		armor = armor,
	})
end

function RoundDataManager.incrementArmor(player: Player, amount: number)
	local playerData = roundData.playerData[player.UserId]

	assert(playerData, "Player data does not exist")
	assert(playerData.armor + amount >= 0 and playerData.armor + amount <= 100, "Armor must be between 0 and 100")

	playerData.armor += amount

	ClientServerCommunication.replicateAsync("updateArmor", {
		playerId = player.UserId,
		armor = playerData.armor,
	})
end

function RoundDataManager.setAmmo(player: Player, ammo: number)
	local playerData = roundData.playerData[player.UserId]

	assert(ammo >= 0 and ammo <= 100, "Ammo must be between 0 and 100")
	assert(playerData, "Player data does not exist")

	playerData.ammo = ammo

	ClientServerCommunication.replicateAsync("updateAmmo", {
		playerId = player.UserId,
		ammo = ammo,
	})
end

function RoundDataManager.incrementAmmo(player: Player, amount: number)
	local playerData = roundData.playerData[player.UserId]

	assert(playerData, "Player data does not exist")
	assert(playerData.ammo, "Player data ammo does not exist")
	assert(playerData.ammo + amount >= 0 and playerData.ammo + amount <= 100, "Ammo must be between 0 and 100")

	playerData.ammo += amount

	ClientServerCommunication.replicateAsync("updateAmmo", {
		playerId = player.UserId,
		ammo = playerData.ammo,
	})
end

function RoundDataManager.setUpRound(roundType: number, playerDatas: { [number]: RoundPlayerData })
	roundData.currentRoundType = roundType
	roundData.playerData = playerDatas
end

return RoundDataManager
