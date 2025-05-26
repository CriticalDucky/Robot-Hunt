--[[
    This script collects souls from the dead and gives them to the living.
]]

local ServerStorage = game:GetService "ServerStorage"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local Players = game:GetService "Players"
local RunService = game:GetService "RunService"

local GameLoop = ServerStorage.GameLoop

local RoundDataManager = require(GameLoop.RoundDataManager)
local Actions = require(GameLoop.Actions)
local RoundConfiguration = require(ReplicatedStorage.Configuration.RoundConfiguration)
local Enums = require(ReplicatedFirst.Enums)

local lobbyTeam = game:GetService("Teams"):WaitForChild "Lobby"

RoundDataManager.onPlayerStatusUpdated:Connect(function(playerData)
	local player = Players:GetPlayerByUserId(playerData.playerId)

	if not player then
		warn("Player not found for userId: " .. tostring(playerData.playerId))
		return
	end

	if playerData.status == Enums.PlayerStatus.dead then
		local character = player.Character

		if character then
			local map = workspace:FindFirstChild "Map"

			if not map then return end
			local bodiesFolder = map:FindFirstChild "Bodies" or Instance.new "Folder"
			bodiesFolder.Name = "Bodies"
			bodiesFolder.Parent = map

			character.Archivable = true
			local body = character:Clone()
			character.Archivable = false

			do
				local joints = {}
				local cframes = {}

				for _, descendant in ipairs(body:GetDescendants()) do
					if descendant:IsA "Motor6D" or descendant:IsA "JointInstance" then
						table.insert(joints, descendant)
					elseif descendant:IsA "BasePart" then
						cframes[descendant] = descendant.CFrame
					else
						descendant:Destroy()
					end
				end

				for _, joint in ipairs(joints) do
					joint:Destroy()
				end

				for part, cframe in pairs(cframes) do
					part.Anchored = true
					part.CFrame = cframe
				end

				local face = body:FindFirstChild "Face"
				if face then face:Destroy() end

				local triangle = body:FindFirstChild "Triangle"
				if triangle then triangle.Color = Color3.new(0.3, 0.3, 0.3) end
			end

			task.wait(RoundConfiguration.deathWaitTime)

			if
				player:IsDescendantOf(Players)
				and player.Character == character
				and player.Team ~= lobbyTeam
				and not playerData.isLobby
			then
				body.Parent = bodiesFolder

				Actions.teleport.toLobby(player)
			else
				body:Destroy()
			end
		end
	end
end)

local function onPlayerManuallyQuits(player: Player)
	local playerData = RoundDataManager.data.playerData[player.UserId]

	if playerData and playerData.status ~= Enums.PlayerStatus.dead and RoundDataManager.data.isGameOver == false then
		RoundDataManager.killPlayer(player, Players:GetPlayerByUserId(playerData.lastAttackerId or 0))
	end
end

Players.PlayerRemoving:Connect(function(player) onPlayerManuallyQuits(player) end)

Players.PlayerAdded:Connect(function(player)
	player.CharacterRemoving:Connect(function(character)
		if RoundDataManager.data.currentPhaseType ~= Enums.PhaseType.Loading then onPlayerManuallyQuits(player) end
	end)
end)

-- Decreases life support for players in life support. Applies for both hunters and rebels in life support.
RunService.Heartbeat:Connect(function(dt)
	for _, player in pairs(Players:GetPlayers()) do
		local playerData = RoundDataManager.data.playerData[player.UserId]

		if playerData and playerData.status == Enums.PlayerStatus.lifeSupport and playerData.lifeSupport > 0 then
			local lifeSupportLoss

			do
				local rate = RoundConfiguration.lifeSupportLossPerSecond

				local function getRateLossFromDistance(distance: number)
					return if distance <= 10 then 1 else 2 / (distance + 2 - 10)
				end

				for _, otherPlayer in pairs(Players:GetPlayers()) do
					if otherPlayer == player then continue end

					local otherPlayerData = RoundDataManager.data.playerData[otherPlayer.UserId]

					if
						otherPlayerData
						and otherPlayerData.status == Enums.PlayerStatus.alive
						and not otherPlayerData.isLobby
						and otherPlayerData.team ~= playerData.team
					then
						local distance = (
							player.Character.PrimaryPart.Position - otherPlayer.Character.PrimaryPart.Position
						).Magnitude

						rate -= getRateLossFromDistance(distance) * RoundConfiguration.lifeSupportLossPerSecond
						math.clamp(rate, 0, 1)
					end
				end

				lifeSupportLoss = rate * dt
			end

			RoundDataManager.incrementLifeSupport(player, -lifeSupportLoss)
		elseif
			playerData
			and playerData.status == Enums.PlayerStatus.alive
			and not RoundDataManager.data.isGameOver
			and playerData.damageLastTakenTime
			and os.clock() - playerData.damageLastTakenTime > RoundConfiguration.shieldRegenBuffer
		then
			local shield = playerData.shield or 0

			if shield < RoundConfiguration.shieldBaseAmount then
				RoundDataManager.incrementShield(player, RoundConfiguration.shieldRegenAmountPerSecond * dt)
			end
		end
	end
end)
