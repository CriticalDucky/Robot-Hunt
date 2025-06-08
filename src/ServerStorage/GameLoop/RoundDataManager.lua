--!strict

-- Services
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Players = game:GetService "Players"

-- Modules
local ClientServerCommunication = require(ReplicatedStorage.Data.ClientServerCommunication)
-- local RoundConfiguration = require(ReplicatedStorage.Configuration.RoundConfiguration)

local Enums = require(ReplicatedFirst.Enums)
local Types = require(ReplicatedFirst.Utility.Types)
local RoundConfiguration = require(ReplicatedStorage.Configuration.RoundConfiguration)
local PhaseType = Enums.PhaseType

-- Types
type RoundPlayerData = Types.RoundPlayerData
type RoundTerminalData = Types.RoundTerminalData
type RoundBatteryData = Types.RoundBatteryData

-- Round data structure
type RoundData = {
	-- The current round type enum (Enums.RoundType)
	currentRoundType: number?,

	-- The current phase type enum (Enums.PhaseType)
	currentPhaseType: number,

	-- Whether the game is over. Decided by the specific game mode.
	-- The game might be over while players are still in the map.
	isGameOver: boolean,

	-- The Unix timestamp of when the phase should end
	phaseEndTime: number?,

	numRequiredTerminals: number?,

	terminalData: { RoundTerminalData },

	batteryData: { RoundBatteryData },

	playerData: {
		[number --[[userId]]]: RoundPlayerData,
	},
}

-- The main round data object
local roundData: RoundData = {
	currentRoundType = nil,
	currentPhaseType = Enums.PhaseType.NotEnoughPlayers,
	isGameOver = false,
	phaseEndTime = nil,

	terminalData = {},

	batteryData = {},

	playerData = {},
}

--[[
    Retrieves the round data and returns a filtered version of it for the client.

    @param player Player - The player requesting the filtered data.
    @return table - The filtered round data for the client.
]]
function getFilteredData(player: Player)
	-- Filters sensitive player data for the client.
	-- @param playerData RoundPlayerData - The player's data to filter.
	-- @param player Player - The player requesting the data.
	-- @return RoundPlayerData - The filtered player data.
	local function filter(playerData: RoundPlayerData, player: Player): RoundPlayerData
		return {
			playerId = playerData.playerId,
			status = playerData.status,
			isLobby = playerData.isLobby,
			lastAttackerId = playerData.lastAttackerId,
			killedById = playerData.killedById,
			victims = playerData.victims,
			team = playerData.team,
			health = playerData.health,
			shield = playerData.shield,
			lifeSupport = playerData.lifeSupport,
			ammo = playerData.ammo,
			gunHitPositionL = if playerData.playerId ~= player.UserId then playerData.gunHitPositionL else nil,
			gunHitPositionR = if playerData.playerId ~= player.UserId then playerData.gunHitPositionR else nil,
			actions = playerData.actions,
			stats = playerData.stats,
		}
	end

	local filteredData = {}

	filteredData.currentRoundType = roundData.currentRoundType
	filteredData.currentPhaseType = roundData.currentPhaseType
	filteredData.phaseEndTime = roundData.phaseEndTime
	filteredData.numRequiredTerminals = roundData.numRequiredTerminals
	filteredData.isGameOver = roundData.isGameOver
	filteredData.terminalData = {}

	for _, terminalData in ipairs(roundData.terminalData) do
		table.insert(filteredData.terminalData, {
			id = terminalData.id,
			model = terminalData.model,
			hackers = terminalData.hackers,
			progress = terminalData.progress,
			cooldown = terminalData.cooldown,
			isErrored = terminalData.isErrored,
			isPuzzleMode = terminalData.isPuzzleMode,
			puzzleQueue = terminalData.puzzleQueue,
		})
	end

	filteredData.batteryData = {}
	for _, batteryData in ipairs(roundData.batteryData) do
		table.insert(filteredData.batteryData, {
			id = batteryData.id,
			model = batteryData.model,
			holder = batteryData.holder,
		})
	end

	filteredData.playerData = {}

	for _, playerData in ipairs(roundData.playerData) do
		table.insert(filteredData.playerData, filter(playerData, player))
	end

	return filteredData
end

-- The main RoundDataManager module
local RoundDataManager = {}

-- Events for data updates
local onDataUpdatedEvent = Instance.new "BindableEvent" -- should rarely be used; only for reflective uses and not reciprocal
local onPlayerStatusUpdatedEvent = Instance.new "BindableEvent"
local onHealthDataUpdatedEvent = Instance.new "BindableEvent"
local onPhaseChangedEvent = Instance.new "BindableEvent"
local onTerminalDataUpdatedEvent = Instance.new "BindableEvent"

RoundDataManager.data = roundData
RoundDataManager.onDataUpdated = onDataUpdatedEvent.Event :: RBXScriptSignal<RoundData>
RoundDataManager.onPhaseChanged = onPhaseChangedEvent.Event :: RBXScriptSignal<RoundData>
RoundDataManager.onPlayerStatusUpdated = onPlayerStatusUpdatedEvent.Event :: RBXScriptSignal<RoundPlayerData>
RoundDataManager.onHealthDataUpdated = onHealthDataUpdatedEvent.Event :: RBXScriptSignal<RoundPlayerData>
RoundDataManager.onTerminalDataUpdated = onTerminalDataUpdatedEvent.Event :: RBXScriptSignal<RoundTerminalData>

--[[
    Initializes round data for a specific player or all players.

    @param player Player? - The player to initialize data for. If nil, initializes for all players.
]]
function RoundDataManager.initializeRoundDataAsync(player: Player?)
	local players = if player then { player } else Players:GetPlayers()

	for _, player in ipairs(players) do
		ClientServerCommunication.replicateAsync("InitializeRoundData", getFilteredData(player), player)
	end
end

--[[
    Sets the current phase of the round.

    @param phaseType number - The phase type (Enums.PhaseType).
    @param endTime number? - The Unix timestamp of when the phase ends.
]]
function RoundDataManager.setPhase(phaseType: number, endTime: number?)
	if phaseType == PhaseType.GameOver then
		roundData.isGameOver = true
	else
		roundData.currentPhaseType = phaseType
	end

	roundData.phaseEndTime = endTime

	if phaseType == PhaseType.Intermission then
		roundData.currentRoundType = nil
		roundData.isGameOver = false
		roundData.numRequiredTerminals = nil
	elseif phaseType == PhaseType.Loading then
		table.clear(roundData.playerData)
	end

	ClientServerCommunication.replicateAsync("SetPhase", {
		phaseType = phaseType,
		phaseEndTime = endTime,
	})

	onDataUpdatedEvent:Fire(roundData)
	onPhaseChangedEvent:Fire(roundData)
end

--[[
	Registers teleportation to the lobby for a player. The actual round script will handle teleportation.

	@param player Player - The player to register for teleportation.
]]
function RoundDataManager.registerLobbyTeleport(player: Player, destinationIsGame: boolean)
	local playerData = roundData.playerData[player.UserId]

	assert(playerData, "Player data does not exist")

	playerData.isLobby = not destinationIsGame

	ClientServerCommunication.replicateAsync("RegisterLobbyTeleport", {
		playerId = player.UserId,
		isLobby = playerData.isLobby,
	})

	onDataUpdatedEvent:Fire(roundData)
end

--[[
    Creates a new player data object.

    @param player Player - The player to create data for.
    @param team number - The team the player belongs to.
    @return RoundPlayerData - The newly created player data.
]]
function RoundDataManager.createNewPlayerData(player: Player, team: number): RoundPlayerData
	return {
		playerId = player.UserId,

		status = Enums.PlayerStatus.alive,
		isLobby = false,

		lastAttackerId = nil,
		killedById = nil,
		victims = {},

		team = team,

		health = 100,
		shield = RoundConfiguration.shieldBaseAmount,
		lifeSupport = 100,

		ammo = 100,

		gunHitPositionL = nil,
		gunHitPositionR = nil,

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

--[[
    Adds a victim to an attacker's victim list.

    @param attacker Player - The player who attacked.
    @param victim Player - The player who was attacked.
]]
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

--[[
    Removes a victim from an attacker's victim list.

    @param attacker Player - The player who attacked.
    @param victim Player? - The player to remove from the victim list. If nil, clears all victims.
]]
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

--[[
    Kills a player and updates their status.

    @param victim Player - The player who was killed.
    @param killer Player? - The player who killed the victim.
]]
function RoundDataManager.killPlayer(victim: Player, killer: Player?)
	local playerData = roundData.playerData[victim.UserId]

	assert(playerData, "Player data does not exist")

	playerData.status = Enums.PlayerStatus.dead
	playerData.health = 0
	playerData.shield = 0
	playerData.lifeSupport = 0
	playerData.gunHitPositionL = nil
	playerData.gunHitPositionR = nil
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

--[[
    Revives a player who is in life support.

    @param player Player - The player to revive.
]]
function RoundDataManager.revivePlayer(player: Player)
	local playerData = roundData.playerData[player.UserId]

	assert(playerData, "Player data does not exist")

	playerData.status = Enums.PlayerStatus.alive
	playerData.health = 100
	playerData.shield = RoundConfiguration.shieldBaseAmount

	ClientServerCommunication.replicateAsync("RevivePlayer", {
		playerId = player.UserId,
	})

	onDataUpdatedEvent:Fire(roundData)
	onPlayerStatusUpdatedEvent:Fire(playerData)
end

--[[
    Sets the health and shield of a player.
	WARNING: Will not set playerData.damageLastTakenTime. You must set that manually.

    @param player Player - The player whose health is being set.
    @param shield number? - The new shield value.
    @param health number? - The new health value.
]]
function RoundDataManager.setHealth(player: Player, shield: number?, health: number?)
	local playerData = roundData.playerData[player.UserId]

	assert(playerData, "Player data does not exist")

	if shield then playerData.shield = shield end

	if health then
		playerData.health = health

		if health <= 0 then playerData.status = Enums.PlayerStatus.lifeSupport end
	end

	ClientServerCommunication.replicateAsync("UpdateHealth", {
		playerId = player.UserId,
		health = playerData.health,
		shield = playerData.shield,
	})

	onDataUpdatedEvent:Fire(roundData)

	if playerData.status == Enums.PlayerStatus.lifeSupport then onPlayerStatusUpdatedEvent:Fire(playerData) end
end

--[[
	Increments the player's shield and health by the given amount.
	If the amount is negative, the player will take shield damage first, and the rest of it then health damage.
	If the amount is positive, the player will only gain health.

    @param player Player - The player whose health is being incremented.
    @param amount number - The amount to increment health by.
]]
function RoundDataManager.incrementAccountedHealth(player: Player, amount: number)
	local playerData = roundData.playerData[player.UserId]

	assert(playerData, "Player data does not exist")

	local health = playerData.health
	local shield = playerData.shield

	if amount < 0 then
		playerData.damageLastTakenTime = os.clock()

		-- Take shield damage first
		shield += amount

		if shield < 0 then
			-- Take health damage
			health += shield
			shield = 0
		end
	else
		-- Gain health
		health += amount
	end

	health = math.clamp(health, 0, 100)

	RoundDataManager.setHealth(player, shield, health)
end

--[[
    Sets the life support value for a player.

    @param player Player - The player whose life support is being set.
    @param lifeSupport number - The new life support value.
]]
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

--[[
    Increments the life support value for a player.

    @param player Player - The player whose life support is being incremented.
    @param amount number - The amount to increment life support by.
]]
function RoundDataManager.incrementLifeSupport(player: Player, amount: number)
	local playerData = roundData.playerData[player.UserId]

	assert(playerData, "Player data does not exist")

	local lifeSupport = math.clamp(playerData.lifeSupport + amount, 0, 100)

	RoundDataManager.setLifeSupport(player, lifeSupport)
end

--[[
	Increments the shield value for a player.

	@param player Player - The player whose shield is being incremented.
	@param amount number - The amount to increment shield by.
]]
function RoundDataManager.incrementShield(player: Player, amount: number)
	local playerData = roundData.playerData[player.UserId]

	assert(playerData, "Player data does not exist")

	local shield = math.clamp(playerData.shield + amount, 0, RoundConfiguration.shieldBaseAmount)

	RoundDataManager.setHealth(player, shield)
end

--[[
    Sets the ammo value for a player.

    @param player Player - The player whose ammo is being set.
    @param ammo number - The new ammo value.
]]
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

--[[
    Increments the ammo value for a player.

    @param player Player - The player whose ammo is being incremented.
    @param amount number - The amount to increment ammo by.
]]
function RoundDataManager.incrementAmmo(player: Player, amount: number)
	local playerData = roundData.playerData[player.UserId]

	assert(playerData, "Player data does not exist")
	assert(playerData.ammo, "Player data ammo does not exist")

	amount = math.clamp(playerData.ammo + amount, 0, 100)

	RoundDataManager.setAmmo(player, amount)
end

--[[
    Updates the shooting status of a player.

    @param player Player - The player whose shooting status is being updated.
    @param value boolean - Whether the player is shooting.
    @param gunHitPositionL Vector3? - The position where the gun hit, if applicable.
	@param gunHitPositionR Vector3? - The position where the gun hit, if applicable.
]]
function RoundDataManager.updateShootingStatus(player: Player, value: boolean, gunHitPositionL: Vector3?, gunHitPositionR: Vector3?)
	local playerData = roundData.playerData[player.UserId]

	assert(playerData, "Player data does not exist")

	playerData.actions.isShooting = value
	playerData.gunHitPositionL = gunHitPositionL -- nil if not shooting
	playerData.gunHitPositionR = gunHitPositionR -- nil if not shooting

	ClientServerCommunication.replicateAsync("UpdateShootingStatus", {
		playerId = player.UserId,
		value = value,
		gunHitPositionL = gunHitPositionL,
		gunHitPositionR = gunHitPositionR,
	})

	onDataUpdatedEvent:Fire(roundData)
end

--[[
    Updates the status of a battery.

    @param batteryId number - The ID of the battery.
    @param holder Player? - The player holding the battery, if any.
    @param deleteBattery boolean? - Whether to delete the battery.
]]
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

function RoundDataManager.setTerminalHackers(terminalId: number, hackers: { Player })
	local terminalData = roundData.terminalData[terminalId]

	assert(terminalData, "Terminal data does not exist")

	terminalData.hackers = hackers

	for userId, playerData in pairs(roundData.playerData) do
		if table.find(hackers, Players:GetPlayerByUserId(playerData.playerId)) then
			playerData.actions.isHacking = true
		else
			playerData.actions.isHacking = false
		end
	end

	ClientServerCommunication.replicateAsync("UpdateTerminalData", {
		id = terminalId,
		hackers = hackers,
	})

	onDataUpdatedEvent:Fire(roundData)
	onTerminalDataUpdatedEvent:Fire(terminalData)
end

function RoundDataManager.addHacker(terminalId: number, hacker: Player)
	local terminalData = roundData.terminalData[terminalId]

	assert(terminalData, "Terminal data does not exist")

	table.insert(terminalData.hackers, hacker)

	for userId, playerData in pairs(roundData.playerData) do
		if userId == hacker.UserId then
			playerData.actions.isHacking = true
		end
	end

	ClientServerCommunication.replicateAsync("UpdateTerminalData", {
		id = terminalId,
		hackers = terminalData.hackers,
	})

	onDataUpdatedEvent:Fire(roundData)
	onTerminalDataUpdatedEvent:Fire(terminalData)
end

function RoundDataManager.removeHackers(terminalId: number, hackers: Player | { Player })
	local terminalData = roundData.terminalData[terminalId]

	assert(terminalData, "Terminal data does not exist")

	if typeof(hackers) == "table" then
		for _, hacker in ipairs(hackers) do
			table.remove(terminalData.hackers, table.find(terminalData.hackers, hacker))

			for userId, playerData in pairs(roundData.playerData) do
				if userId == hacker.UserId then
					playerData.actions.isHacking = false
				end
			end
		end
	else
		table.remove(terminalData.hackers, table.find(terminalData.hackers, hackers))

		for userId, playerData in pairs(roundData.playerData) do
			if userId == hackers.UserId then
				playerData.actions.isHacking = false
			end
		end
	end

	ClientServerCommunication.replicateAsync("UpdateTerminalData", {
		id = terminalId,
		hackers = terminalData.hackers,
	})

	onDataUpdatedEvent:Fire(roundData)
	onTerminalDataUpdatedEvent:Fire(terminalData)
end

function RoundDataManager.setTerminalProgress(terminalId: number, progress: number)
	local terminalData = roundData.terminalData[terminalId]

	assert(terminalData, "Terminal data does not exist")

	terminalData.progress = progress

	ClientServerCommunication.replicateAsync("UpdateTerminalData", {
		id = terminalId,
		progress = progress,
	})

	onDataUpdatedEvent:Fire(roundData)
	onTerminalDataUpdatedEvent:Fire(terminalData)
end

function RoundDataManager.incrementTerminalProgress(terminalId: number, amount: number)
	local terminalData = roundData.terminalData[terminalId]

	assert(terminalData, "Terminal data does not exist")

	local progress = math.clamp(terminalData.progress + amount, 0, 100)

	RoundDataManager.setTerminalProgress(terminalId, progress)
end

--[[
	Sets the terminal states for a specific terminal. Takes in a single dictionary	.

	@param terminalId number - The ID of the terminal.
	@param states { [string]: any } - The states to set for the terminal.
]]
function RoundDataManager.setTerminalStates(terminalId: number, states: { [string]: any })
	local terminalData = roundData.terminalData[terminalId]

	assert(terminalData, "Terminal data does not exist")

	for key, value in pairs(states) do
		terminalData[key] = value
	end

	ClientServerCommunication.replicateAsync("UpdateTerminalData", {
		id = terminalId,
		_states = states,
	})

	onDataUpdatedEvent:Fire(roundData)
	onTerminalDataUpdatedEvent:Fire(terminalData)
end

function RoundDataManager.setUpRound(
	roundType: number,
	playerDatas: { [number]: RoundPlayerData },
	terminalData: { RoundTerminalData },
	batteryData: { RoundBatteryData },
	numRequiredTerminals: number? -- optional, only used for default round
)
	roundData.currentRoundType = roundType
	roundData.playerData = playerDatas

	roundData.terminalData = terminalData
	roundData.batteryData = batteryData

	roundData.numRequiredTerminals = numRequiredTerminals

	ClientServerCommunication.replicateAsync("SetUpRound", {
		roundType = roundType,
		playerData = playerDatas,
		terminalData = terminalData,
		batteryData = batteryData,
		numRequiredTerminals = numRequiredTerminals,
	})

	onDataUpdatedEvent:Fire(roundData)
end

return RoundDataManager
