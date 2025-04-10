local ProximityPromptService = game:GetService "ProximityPromptService"
local ServerStorage = game:GetService "ServerStorage"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Players = game:GetService "Players"
local RunService = game:GetService "RunService"

local GameLoop = ServerStorage.GameLoop
local Data = ReplicatedStorage.Data
local Utility = ReplicatedFirst.Utility

local RoundDataManager = require(GameLoop.RoundDataManager)
local RoundConfiguration = require(ReplicatedStorage.Configuration.RoundConfiguration)
local ClientServerCommunication = require(Data.ClientServerCommunication)
local SpacialQuery = require(Utility.SpacialQuery)
local Table = require(Utility.Table)
local Types = require(Utility.Types)
local Enums = require(ReplicatedFirst.Enums)

type RoundPlayerData = Types.RoundPlayerData

function getRandomCooldownTime()
	return math.random(RoundConfiguration.minTerminalCooldown, RoundConfiguration.maxTerminalCooldown)
end

function onClientPuzzleResult(player, terminalId, success)
	local terminalData = RoundDataManager.data.terminalData[terminalId]

	assert(terminalData, "Terminal data not found")

	-- remove from puzzle queue
	local index = table.find(terminalData.puzzleQueue, player)
	if index then
		table.remove(terminalData.puzzleQueue, index)
	end

	if success then
		RoundDataManager.incrementTerminalProgress(terminalId, RoundConfiguration.puzzleBonusPerPlayer)
	else
		RoundDataManager.incrementTerminalProgress(terminalId, -RoundConfiguration.puzzlePenaltyPerPlayer)
		RoundDataManager.removeHacker(terminalId, player.UserId) -- haha

		RoundDataManager.setTerminalStates(terminalId, {
			isErrored = true,
		})
	end

	if #terminalData.puzzleQueue == 0 then
		RoundDataManager.setTerminalStates(terminalId, {
			isPuzzleMode = false,
		})
	end
end

function promptPuzzle(terminalData: Types.RoundTerminalData)
	RoundDataManager.setTerminalStates(terminalData.id, {
		isPuzzleMode = true,
	})

	terminalData.cooldown = getRandomCooldownTime()

	for _, player in ipairs(terminalData.hackers) do
		table.insert(terminalData.puzzleQueue, player)
		ClientServerCommunication.replicateAsync("PromptTerminalPuzzle", player)

		task.delay(RoundConfiguration.puzzleTimeout, function()
			if table.find(terminalData.puzzleQueue, player) then
				onClientPuzzleResult(player, terminalData.id, false)
			end
		end)
	end
end

ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
	if prompt.Name ~= "Terminal" then return end

	if not RoundConfiguration.roundPhases[RoundDataManager.data.currentPhaseType] then return end

	local terminalData
	local terminalModel = prompt:FindFirstAncestor "Terminal"

	if not terminalModel then return end

	for _, data in pairs(RoundDataManager.data.terminalData) do
		if data.model == terminalModel then
			terminalData = data

			break
		end
	end

	if not terminalData then return end

	if terminalData.progress >= 100 then return end

	for _, data in pairs(RoundDataManager.data.terminalData) do
		if table.find(data.hackers, player) then return end
	end

	for _, data in pairs(RoundDataManager.data.batteryData) do
		if data.holder == player.UserId then return end
	end

	local playerData = RoundDataManager.data.playerData[player.UserId]

	if not playerData then return end
	if playerData.status ~= Enums.PlayerStatus.alive then return end
	if playerData.actions.isHacking then return end
	if playerData.actions.isShooting then return end

	RoundDataManager.addHacker(terminalData.id, player.UserId)
end)

RunService.Heartbeat:Connect(function(dt)
	for _, terminalData in pairs(RoundDataManager.data.terminalData) do
		if terminalData.progress >= 100 then continue end

		local numHackers = #terminalData.hackers
		if terminalData.isPuzzleMode or numHackers == 0 then continue end

		if terminalData.progress == 0 then
			terminalData.cooldown = getRandomCooldownTime()
		end

		RoundDataManager.incrementTerminalProgress(
			terminalData.id,
			dt * RoundConfiguration.terminalProgressPerSecondPerPlayer * numHackers
		)

		if terminalData.progress >= 100 then continue end

		terminalData.cooldown -= dt
		if terminalData.cooldown <= 0 then
			if terminalData.progress >= 97 then
				terminalData.cooldown = 10000 -- we don't want to trigger a puzzle if the terminal is almost done
			else
				promptPuzzle(terminalData)
			end
		end
	end
end)
