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
	if index then table.remove(terminalData.puzzleQueue, index) end

	if success then
		RoundDataManager.incrementTerminalProgress(terminalId, RoundConfiguration.puzzleBonusPerPlayer)
	else
		RoundDataManager.incrementTerminalProgress(terminalId, -RoundConfiguration.puzzlePenaltyPerPlayer)
		RoundDataManager.removeHackers(terminalId, player) -- haha

		RoundDataManager.setTerminalStates(terminalId, {
			isErrored = true,
		})

		terminalData.hasPuzzleErrored = true
	end

	if #terminalData.puzzleQueue == 0 then
		RoundDataManager.setTerminalStates(terminalId, {
			isPuzzleMode = false,
			isErrored = if terminalData.hasPuzzleErrored then true else false,
		})

		terminalData.hasPuzzleErrored = false
	end
end

function promptPuzzle(terminalData: Types.RoundTerminalData)
	RoundDataManager.setTerminalStates(terminalData.id, {
		isPuzzleMode = true,
	})

	terminalData.cooldown = getRandomCooldownTime()

	for _, player in pairs(terminalData.hackers) do
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
	if prompt.Name ~= "Terminal" then 
		print("Prompt is not a Terminal.")
		return 
	end

	if not RoundConfiguration.terminalPhases[RoundDataManager.data.currentPhaseType] then 
		print("Current phase type does not allow terminal interaction.")
		return 
	end

	local terminalData
	local terminalModel = prompt:FindFirstAncestor "Terminal"

	if not terminalModel then 
		print("Terminal model not found.")
		return 
	end

	for _, data in pairs(RoundDataManager.data.terminalData) do
		if data.model == terminalModel then
			terminalData = data
			break
		end
	end

	if not terminalData then 
		print("Terminal data not found.")
		return 
	end

	if terminalData.progress >= 100 then 
		print("Terminal progress is already complete.")
		return 
	end

	for _, data in pairs(RoundDataManager.data.terminalData) do
		if table.find(data.hackers, player) then 
			print("Player is already hacking another terminal.")
			return 
		end
	end

	for _, data in pairs(RoundDataManager.data.batteryData) do
		if data.holder == player.UserId then 
			print("Player is holding a battery and cannot hack.")
			return 
		end
	end

	local playerData = RoundDataManager.data.playerData[player.UserId]

	if not playerData then 
		print("Player data not found.")
		return 
	end
	if playerData.status ~= Enums.PlayerStatus.alive then 
		print("Player is not alive and cannot hack.")
		return 
	end
	if playerData.actions.isHacking then 
		print("Player is already hacking.")
		return 
	end
	if playerData.actions.isShooting then 
		print("Player is shooting and cannot hack.")
		return 
	end

	local seat = prompt.Parent.Parent:FindFirstChild "Seat" :: BasePart
	local character = player.Character

	if not seat or not character then 
		print("Seat or character not found.")
		return 
	end

	local characterPivot = character:GetPivot()
	local seatPivot = seat:GetPivot()

	-- Set the character's x and z position to the seat's x and z position
	local destinationCFrame = CFrame.new(seatPivot.Position.X, characterPivot.Position.Y, seatPivot.Position.Z)


	destinationCFrame *= CFrame.Angles(0, seatPivot.Rotation.Y, 0)
	-- but we need to offset the rotation by 90 degrees to the right for some reason
	destinationCFrame *= CFrame.Angles(0, math.rad(90), 0)

	character:PivotTo(destinationCFrame)

	RoundDataManager.addHacker(terminalData.id, player)
end)

RunService.Heartbeat:Connect(function(dt)
	for _, terminalData in pairs(RoundDataManager.data.terminalData) do
		if terminalData.progress >= 100 then continue end

		local numHackers = #terminalData.hackers

		if numHackers == 0 then continue end

		do
			local safeHackers = {}

			local zone = terminalData.model:FindFirstChild "Zone"

			local parts = workspace:GetPartBoundsInBox(zone.CFrame, zone.Size)

			for _, hacker in pairs(terminalData.hackers) do
				local character = hacker.Character

				if not character then
					RoundDataManager.removeHackers(terminalData.id, hacker)
				else
					for _, part in ipairs(parts) do
						if part:IsDescendantOf(character) then
							table.insert(safeHackers, hacker)
							break
						end
					end
				end
			end

			for _, hacker in pairs(terminalData.hackers) do
				if not table.find(safeHackers, hacker) then
					RoundDataManager.removeHackers(terminalData.id, hacker)
				end
			end
		end

		if terminalData.isPuzzleMode then continue end

		if terminalData.progress == 0 then terminalData.cooldown = getRandomCooldownTime() end

		RoundDataManager.incrementTerminalProgress(
			terminalData.id,
			dt * RoundConfiguration.terminalProgressPerSecondPerPlayer * numHackers
		)
		-- TODO: Score

		if terminalData.progress >= 100 then
			-- TODO: Score

			if #terminalData.hackers > 0 then
				RoundDataManager.removeHackers(terminalData.id, terminalData.hackers)
			end

			RoundDataManager.setTerminalStates(terminalData.id, {
				isPuzzleMode = false,
			})

			table.clear(terminalData.puzzleQueue)

			continue
		end

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

RoundDataManager.onPlayerStatusUpdated:Connect(function(playerData: RoundPlayerData)
	if playerData.status == Enums.PlayerStatus.alive then return end

	local player = Players:GetPlayerByUserId(playerData.playerId)

	for _, terminalData in pairs(RoundDataManager.data.terminalData) do
		if table.find(terminalData.hackers, player) then
			RoundDataManager.removeHackers(terminalData.id, player)
		end
	end
end)

RoundDataManager.onPhaseChanged:Connect(function(phaseType)
	if RoundConfiguration.roundPhases[phaseType] and not RoundConfiguration.terminalPhases[phaseType] then
		for _, terminalData in pairs(RoundDataManager.data.terminalData) do
			if #terminalData.hackers > 0 then
				RoundDataManager.removeHackers(terminalData.id, terminalData.hackers)
			end

			if terminalData.progress ~= 100 then
				RoundDataManager.setTerminalProgress(terminalData.id, 100)
			end

			if terminalData.isPuzzleMode then
				RoundDataManager.setTerminalStates(terminalData.id, {
					isPuzzleMode = false,
				})
			end

			table.clear(terminalData.puzzleQueue)
		end
	end
end)

ClientServerCommunication.registerActionAsync("PromptTerminalPuzzle", onClientPuzzleResult)