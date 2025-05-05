--!strict

--#region Imports

local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local Players = game:GetService "Players"

local replicatedStorageData = ReplicatedStorage:WaitForChild "Data"
local roundDataFolder = replicatedStorageData:WaitForChild "RoundData"

local ClientState = require(replicatedStorageData:WaitForChild "ClientState")
local ClientServerCommunication = require(replicatedStorageData:WaitForChild "ClientServerCommunication")
local ClientRoundDataUtility = require(roundDataFolder:WaitForChild("ClientRoundDataUtility"))
local Fusion = require(ReplicatedFirst:WaitForChild("Vendor"):WaitForChild "Fusion")
local Enums = require(ReplicatedFirst:WaitForChild "Enums")
local Table = require(ReplicatedFirst:WaitForChild("Utility"):WaitForChild "Table")
local Types = require(ReplicatedFirst:WaitForChild("Utility"):WaitForChild "Types")

type RoundTerminalData = Types.RoundTerminalData

local peek = Fusion.peek
local roundData = ClientState.external.roundData
local PhaseType = Enums.PhaseType

--#endregion

ClientServerCommunication.registerActionAsync("InitializeRoundData", function(newRoundData)
	for key, value in newRoundData do
		roundData[key]:set(value)
	end
end)

ClientServerCommunication.registerActionAsync("SetPhase", function(data)
	local phaseType = data.phaseType
	local endTime = data.phaseEndTime

	if phaseType == PhaseType.GameOver then
		roundData.isGameOver:set(true)
	else
		roundData.currentPhaseType:set(phaseType)
	end

	roundData.phaseEndTime:set(endTime)

	if phaseType == PhaseType.Intermission then
		roundData.playerData:set {}
	elseif phaseType == PhaseType.Loading then
		roundData.currentRoundType:set(nil)
	elseif phaseType == PhaseType.Results then
		local playerDatas = peek(roundData.playerData)

		for _, playerData in pairs(playerDatas) do
			playerData.victims = {}
		end

		roundData.playerData:set(playerDatas)
	end
end)

--[[ How its like on the server
	function RoundDataManager.addVictim(attacker: Player, victim: Player)
	local attackerData = roundData.playerData[attacker.UserId]
	local victimData = roundData.playerData[victim.UserId]

	assert(attackerData, "Attacker data does not exist")
	assert(victimData, "Victim data does not exist")

	victimData.lastAttackerId = attacker.UserId
	attackerData.victims[attacker.UserId] = true

	ClientServerCommunication.replicateAsync("UpdateVictims", {
		attackerId = attacker.UserId,
		victims = attackerData.victims,
	})

	onDataUpdatedEvent:Fire(roundData)
end

function RoundDataManager.removeVictim(attacker: Player, victim: Player)
	local attackerData = roundData.playerData[attacker.UserId]
	local victimData = roundData.playerData[victim.UserId]

	assert(attackerData, "Attacker data does not exist")
	assert(victimData, "Victim data does not exist")

	attackerData.victims[victim.UserId] = nil

	ClientServerCommunication.replicateAsync("UpdateVictims", {
		attackerId = attacker.UserId,
		victims = attackerData.victims,
	})

	onDataUpdatedEvent:Fire(roundData)
end
]]

ClientServerCommunication.registerActionAsync("UpdateVictims", function(data)
	local attackerId = data.attackerId
	local victims = Table.editKeys(data.victims, tonumber)

	local newPlayerData = peek(roundData.playerData)
	local attackerData = newPlayerData[attackerId]

	if not newPlayerData or not attackerData then
		return
	end

	attackerData.victims = victims

	roundData.playerData:set(newPlayerData)
end)

--[[ How its like on the server
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

	ClientServerCommunication.replicateAsync("KillPlayer", {
		victimId = victim.UserId,
		killedById = playerData.killedById,
	})

	onDataUpdatedEvent:Fire(roundData)
end
]]

ClientServerCommunication.registerActionAsync("KillPlayer", function(data)
	local victimId = data.victimId
	local killedById = data.killedById

	local newPlayerData = peek(roundData.playerData)
	local victimData = newPlayerData[victimId]

	if not newPlayerData or not victimData then
		return
	end

	victimData.status = Enums.PlayerStatus.dead
	victimData.health = 0
	victimData.armor = 0
	victimData.lifeSupport = 0
	victimData.killedById = killedById

	if killedById then
		local killerData = newPlayerData[killedById]

		if killerData then
			killerData.stats.kills += 1
		end
	end

	roundData.playerData:set(newPlayerData)
end)

--[[
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

	onDataUpdatedEvent:Fire(roundData)
end
]]

ClientServerCommunication.registerActionAsync("RevivePlayer", function(data)
	local playerId = data.playerId

	local newPlayerData = peek(roundData.playerData)
	local playerData = newPlayerData[playerId]

	if not newPlayerData or not playerData then
		return
	end

	playerData.status = Enums.PlayerStatus.alive
	playerData.health = 100
	playerData.armor = 0
	playerData.lifeSupport = 100

	roundData.playerData:set(newPlayerData)
end)

--[[
	function RoundDataManager.setHealth(player: Player, armor: number?, health: number?)
	local playerData = roundData.playerData[player.UserId]

	assert(playerData, "Player data does not exist")

	if armor then
		playerData.armor = armor
	end

	if health then
		playerData.health = health

		if health <= 0 then
			playerData.status = Enums.PlayerStatus.lifeSupport
		end
	end

	ClientServerCommunication.replicateAsync("UpdateHealth", {
		playerId = player.UserId,
		health = playerData.health,
		armor = playerData.armor,
	})

	onDataUpdatedEvent:Fire(roundData)
end
]]

ClientServerCommunication.registerActionAsync("UpdateHealth", function(data)
	local playerId = data.playerId
	local health = data.health
	local armor = data.armor

	local newPlayerData = peek(roundData.playerData)
	local playerData = newPlayerData[playerId]

	if not newPlayerData or not playerData then
		return
	end

	if armor then
		playerData.armor = armor
	end

	if health then
		playerData.health = health

		if health <= 0 then
			playerData.status = Enums.PlayerStatus.lifeSupport
		end
	end

	roundData.playerData:set(newPlayerData)
end)

--[[
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
]]

ClientServerCommunication.registerActionAsync("UpdateLifeSupport", function(data)
	local playerId = data.playerId
	local lifeSupport = data.lifeSupport

	local newPlayerData = peek(roundData.playerData)
	local playerData = newPlayerData[playerId]

	if not newPlayerData or not playerData then
		return
	end

	playerData.lifeSupport = lifeSupport

	roundData.playerData:set(newPlayerData)
end)

--[[
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
]]

ClientServerCommunication.registerActionAsync("UpdateAmmo", function(data)
	local playerId = data.playerId
	local ammo = data.ammo

	local newPlayerData = peek(roundData.playerData)
	local playerData = newPlayerData[playerId]

	if not newPlayerData or not playerData then
		return
	end

	playerData.ammo = ammo

	roundData.playerData:set(newPlayerData)
end)

--[[
	function RoundDataManager.updateBatteryStatus(batteryId: number, holder: Player?, deleteBattery: boolean?)
	local batteryData = roundData.batteryData[batteryId]

	assert(batteryData, "Battery data does not exist")

	batteryData.holder = holder and holder.UserId or nil

	if deleteBattery then
		roundData.batteryData[batteryId] = nil
	end

	ClientServerCommunication.replicateAsync("updateBatteryStatus", {
		batteryId = batteryId,
		holderId = batteryData.holder,
		deleteBattery = not holder,
	})

	onDataUpdatedEvent:Fire(roundData)
end
]]

ClientServerCommunication.registerActionAsync("UpdateBatteryStatus", function(data)
	local batteryId = data.batteryId
	local holderId = data.holderId
	local deleteBattery = data.deleteBattery

	local newBatteryData = peek(roundData.batteryData)
	local batteryData = newBatteryData[batteryId]

	if not newBatteryData or not batteryData then
		return
	end

	batteryData.holder = holderId
	if deleteBattery then
		newBatteryData[batteryId] = nil
	end

	roundData.batteryData:set(newBatteryData)
end)

--[[
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
]]

ClientServerCommunication.registerActionAsync("UpdateShootingStatus", function(data)
	local playerId = data.playerId

	local value = data.value

	local newPlayerData = peek(roundData.playerData)
	local playerData = newPlayerData[playerId]

	if not newPlayerData or not playerData then
		return
	end

	if playerId ~= game.Players.LocalPlayer.UserId then
		playerData.gunHitPositionL = data.gunHitPositionL
		playerData.gunHitPositionR = data.gunHitPositionR
		playerData.actions.isShooting = value
	end

	roundData.playerData:set(newPlayerData)
end)

ClientServerCommunication.registerActionAsync("UpdateTerminalData", function(data: RoundTerminalData & {_states: {[string]: any}? })
	local terminalId = data.id

	local newTerminalData = peek(roundData.terminalData)
	local terminal
	do
		for _, t in pairs(newTerminalData) do
			if t.id == terminalId then
				terminal = t
				break
			end
		end
	end

	if not newTerminalData or not terminal then
		return
	end

	if data._states then
		for key, value in pairs(data._states) do
			terminal[key] = value
		end

		data._states = nil
	end

	for key, value in pairs(data) do
		terminal[key] = value
	end

	roundData.terminalData:set(newTerminalData)

	-- Now, we need to set isHacking for all players based on if they appear in terminal.hackers

	local newPlayerData = peek(roundData.playerData)
	for _, playerData in pairs(newPlayerData) do
		if table.find(terminal.hackers, Players:GetPlayerByUserId(playerData.playerId)) then
			playerData.actions.isHacking = true
		else
			playerData.actions.isHacking = false
		end
	end

	roundData.playerData:set(newPlayerData)
end)

ClientServerCommunication.registerActionAsync("PromptTerminalPuzzle", function(data)
	-- beh
end)

--[[
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
	})

	onDataUpdatedEvent:Fire(roundData)
end
]]

ClientServerCommunication.registerActionAsync("SetUpRound", function(data)
	-- This is to make sure negative player ids dont get converted to strings
	data.playerData = Table.editKeys(data.playerData, tonumber)
	data.batteryData = Table.editKeys(data.batteryData, tonumber)
	data.terminalData = Table.editKeys(data.terminalData, tonumber)

	roundData.currentRoundType:set(data.roundType)
	roundData.playerData:set(data.playerData)
	roundData.terminalData:set(data.terminalData)
	roundData.batteryData:set(data.batteryData)

	ClientRoundDataUtility.setUpRound:Fire()
end)

ClientServerCommunication.replicateAsync("InitializeRoundData")