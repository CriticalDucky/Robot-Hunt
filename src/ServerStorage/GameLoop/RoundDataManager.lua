--!strict

local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Players = game:GetService "Players"

local ClientServerCommunication = require(ReplicatedStorage.Data.ClientServerCommunication)
-- local RoundConfiguration = require(ReplicatedStorage.Configuration.RoundConfiguration)

local Enums = require(ReplicatedFirst.Enums)
local Types = require(ReplicatedFirst.Utility.Types)
local PhaseType = Enums.PhaseType

type RoundPlayerData = Types.RoundPlayerData
type RoundTerminalData = Types.RoundTerminalData
type RoundBatteryData = Types.RoundBatteryData

type RoundData = {
	-- The current round type enum (Enums.RoundType)
	currentRoundType: number?,

	-- The current phase type enum (Enums.PhaseType)
	currentPhaseType: number,

	-- The Unix timestamp of when the phase should end
	phaseEndTime: number?,

	terminalData: { RoundTerminalData },

	batteryData: { RoundBatteryData },

	playerData: {
		[number --[[userId]]]: RoundPlayerData,
	},
}

local roundData: RoundData = {
	currentRoundType = nil,
	currentPhaseType = Enums.PhaseType.NotEnoughPlayers,
	phaseEndTime = nil,

	terminalData = {},

	batteryData = {},

	playerData = {},
}

local function filterPlayerData(playerData: RoundPlayerData, player: Player): RoundPlayerData
	return {
		playerId = playerData.playerId,

		status = playerData.status,

		lastAttackerId = playerData.lastAttackerId,
		killedById = playerData.killedById,
		victims = playerData.victims,

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

local onDataUpdatedEvent = Instance.new "BindableEvent"
local onPlayerStatusUpdatedEvent = Instance.new "BindableEvent"
local onHealthDataUpdatedEvent = Instance.new "BindableEvent"

RoundDataManager.data = roundData
RoundDataManager.onDataUpdated = onDataUpdatedEvent.Event :: RBXScriptSignal<RoundData>
RoundDataManager.onPlayerStatusUpdated = onPlayerStatusUpdatedEvent.Event :: RBXScriptSignal<RoundPlayerData>
RoundDataManager.onHealthDataUpdated = onHealthDataUpdatedEvent.Event :: RBXScriptSignal<RoundPlayerData>

function RoundDataManager.initializeRoundDataAsync(player: Player?)
	local players = if player then { player } else Players:GetPlayers()

	for _, player in ipairs(players) do
		ClientServerCommunication.replicateAsync("InitializeRoundData", filterData(player), player)
	end
end

function RoundDataManager.setPhase(phaseType: number, endTime: number?)
	roundData.currentPhaseType = phaseType
	roundData.phaseEndTime = endTime

	if phaseType == PhaseType.Intermission then
		roundData.currentRoundType = nil
	elseif phaseType == PhaseType.Loading then
		table.clear(roundData.playerData)
	end

	ClientServerCommunication.replicateAsync("SetPhase", {
		phaseType = phaseType,
		phaseEndTime = endTime,
	})

	onDataUpdatedEvent:Fire(roundData)
end

function RoundDataManager.newPlayerData(player: Player, team: number): RoundPlayerData
	return {
		playerId = player.UserId,

		status = Enums.PlayerStatus.alive,

		lastAttackerId = nil,
		killedById = nil,
		victims = {},

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

function RoundDataManager.addVictim(attacker: Player, victim: Player)
	local attackerData = roundData.playerData[attacker.UserId]
	local victimData = roundData.playerData[victim.UserId]

	assert(attackerData, "Attacker data does not exist")
	assert(victimData, "Victim data does not exist")

	victimData.lastAttackerId = attacker.UserId
	attackerData.victims[victim.UserId] = true

	ClientServerCommunication.replicateAsync("UpdateVictims", {
		attackerId = attacker.UserId,
		victims = attackerData.victims,
	})

	onDataUpdatedEvent:Fire(roundData)
end

function RoundDataManager.removeVictim(attacker: Player, victim: Player?)
	local attackerData = roundData.playerData[attacker.UserId]

	assert(attackerData, "Attacker data does not exist")

	if victim then
		attackerData.victims[victim.UserId] = nil
	else
		table.clear(attackerData.victims)
	end

	ClientServerCommunication.replicateAsync("UpdateVictims", {
		attackerId = attacker.UserId,
		victims = attackerData.victims,
	})

	onDataUpdatedEvent:Fire(roundData)
end

function RoundDataManager.killPlayer(victim: Player, killer: Player?)
	local playerData = roundData.playerData[victim.UserId]

	assert(playerData, "Player data does not exist")

	playerData.status = Enums.PlayerStatus.dead
	playerData.health = 0
	playerData.armor = 0
	playerData.lifeSupport = 0
	playerData.gunHitPosition = nil
	playerData.victims = {}

	for _, otherPlayerData in pairs(roundData.playerData) do
		otherPlayerData.victims[victim.UserId] = nil
	end

	if killer then
		playerData.killedById = killer and killer.UserId or nil

		local killerData = roundData.playerData[killer.UserId]

		killerData.stats.kills += 1
	end

	ClientServerCommunication.replicateAsync("KillPlayer", {
		victimId = victim.UserId,
		killedById = playerData.killedById,
	})

	onDataUpdatedEvent:Fire(roundData)
	onPlayerStatusUpdatedEvent:Fire(playerData)
end

-- Can only be called when the player is in life support
function RoundDataManager.revivePlayer(player: Player)
	local playerData = roundData.playerData[player.UserId]

	assert(playerData, "Player data does not exist")

	playerData.status = Enums.PlayerStatus.alive
	playerData.health = 100
	playerData.armor = 0
	playerData.lifeSupport = 100

	ClientServerCommunication.replicateAsync("RevivePlayer", {
		playerId = player.UserId,
	})

	onDataUpdatedEvent:Fire(roundData)
	onPlayerStatusUpdatedEvent:Fire(playerData)
end

function RoundDataManager.setHealth(player: Player, armor: number?, health: number?)
	local playerData = roundData.playerData[player.UserId]

	assert(playerData, "Player data does not exist")

	if armor then playerData.armor = armor end

	if health then
		playerData.health = health

		if health <= 0 then playerData.status = Enums.PlayerStatus.lifeSupport end
	end

	ClientServerCommunication.replicateAsync("UpdateHealth", {
		playerId = player.UserId,
		health = playerData.health,
		armor = playerData.armor,
	})

	onDataUpdatedEvent:Fire(roundData)

	if playerData.status == Enums.PlayerStatus.lifeSupport then onPlayerStatusUpdatedEvent:Fire(playerData) end
end

--[[
	Increments the player's shield and health by the given amount.
	If the amount is negative, the player will take shield damage first, and the rest of it then health damage.
	If the amount is positive, the player will only gain health.
]]
function RoundDataManager.incrementAccountedHealth(player: Player, amount: number)
	local playerData = roundData.playerData[player.UserId]

	assert(playerData, "Player data does not exist")

	local health = playerData.health
	local armor = playerData.armor

	if amount < 0 then
		-- Take shield damage first
		armor += amount

		if armor < 0 then
			-- Take health damage
			health += armor
			armor = 0
		end
	else
		-- Gain health
		health += amount
	end

	health = math.clamp(health, 0, 100)

	RoundDataManager.setHealth(player, armor, health)
end

function RoundDataManager.setLifeSupport(player: Player, lifeSupport: number)
	local playerData = roundData.playerData[player.UserId]

	assert(lifeSupport >= 0 and lifeSupport <= 100, "Life support must be between 0 and 100")

	playerData.lifeSupport = lifeSupport

	if lifeSupport <= 0 then
		return RoundDataManager.killPlayer(player) -- u had a good run
	end

	ClientServerCommunication.replicateAsync("UpdateLifeSupport", {
		playerId = player.UserId,
		lifeSupport = lifeSupport,
	})

	onDataUpdatedEvent:Fire(roundData)
end

function RoundDataManager.incrementLifeSupport(player: Player, amount: number)
	local playerData = roundData.playerData[player.UserId]

	assert(playerData, "Player data does not exist")

	local lifeSupport = math.clamp(playerData.lifeSupport + amount, 0, 100)

	RoundDataManager.setLifeSupport(player, lifeSupport)
end

function RoundDataManager.setAmmo(player: Player, ammo: number)
	local playerData = roundData.playerData[player.UserId]

	assert(ammo >= 0 and ammo <= 100, "Ammo must be between 0 and 100")
	assert(playerData, "Player data does not exist")

	playerData.ammo = ammo

	ClientServerCommunication.replicateAsync("UpdateAmmo", {
		playerId = player.UserId,
		ammo = ammo,
	})

	onDataUpdatedEvent:Fire(roundData)
end

function RoundDataManager.incrementAmmo(player: Player, amount: number)
	local playerData = roundData.playerData[player.UserId]

	assert(playerData, "Player data does not exist")
	assert(playerData.ammo, "Player data ammo does not exist")

	amount = math.clamp(playerData.ammo + amount, 0, 100)

	RoundDataManager.setAmmo(player, amount)
end

function RoundDataManager.updateShootingStatus(player: Player, value: boolean, gunHitPosition: Vector3?)
	local playerData = roundData.playerData[player.UserId]

	assert(playerData, "Player data does not exist")

	playerData.actions.isShooting = value
	playerData.gunHitPosition = gunHitPosition -- nil if not shooting

	ClientServerCommunication.replicateAsync("UpdateShootingStatus", {
		playerId = player.UserId,
		value = value,
		gunHitPosition = gunHitPosition,
	})

	onDataUpdatedEvent:Fire(roundData)
end

function RoundDataManager.updateBatteryStatus(batteryId: number, holder: Player?, deleteBattery: boolean?)
	local batteryData = roundData.batteryData[batteryId]

	assert(batteryData, "Battery data does not exist")

	batteryData.holder = holder and holder.UserId or nil

	if deleteBattery then roundData.batteryData[batteryId] = nil end

	ClientServerCommunication.replicateAsync("UpdateBatteryStatus", {
		batteryId = batteryId,
		holderId = batteryData.holder,
		deleteBattery = deleteBattery,
	})

	onDataUpdatedEvent:Fire(roundData)
end

function RoundDataManager.setUpRound(
	roundType: number,
	playerDatas: { [number]: RoundPlayerData },
	terminalData: { RoundTerminalData },
	batteryData: { RoundBatteryData }
)
	roundData.currentRoundType = roundType
	roundData.playerData = playerDatas

	roundData.terminalData = terminalData
	roundData.batteryData = batteryData

	ClientServerCommunication.replicateAsync("SetUpRound", {
		roundType = roundType,
		playerData = playerDatas,
		terminalData = terminalData,
		batteryData = batteryData,
	})

	onDataUpdatedEvent:Fire(roundData)
end

return RoundDataManager
