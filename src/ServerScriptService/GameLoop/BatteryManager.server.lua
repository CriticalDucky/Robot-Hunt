local ProximityPromptService = game:GetService "ProximityPromptService"
local ServerStorage = game:GetService "ServerStorage"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Players = game:GetService "Players"

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

local function putDownBattery(player: Player, deleteBattery: boolean?)
	assert(player and player.Character)

	local batteryDatas = RoundDataManager.data.batteryData

	for _, data in pairs(batteryDatas) do
		if data.holder == player.UserId then
			local CFrameToPutBattery: CFrame?

			do
				if not deleteBattery then
					local fakeBattery = player.Character:FindFirstChild "Battery" :: Model
					local batteryBody = fakeBattery:FindFirstChild "Body" :: Part

					local pivotCFrame = fakeBattery:GetPivot()
					local headCFrame = (player.Character:FindFirstChild "Head" :: BasePart).CFrame

					local partsIntersectingRay =
						SpacialQuery.getPartsInBetweenPoints(headCFrame.Position, pivotCFrame.Position)
					local partsIntersectingBattery = workspace:GetPartsInPart(batteryBody)

					for _, part in Table.append(partsIntersectingBattery, partsIntersectingRay) do
						if not part:IsDescendantOf(player.Character) then
							local humanoidRootPart = player.Character:FindFirstChild "HumanoidRootPart" :: BasePart

							CFrameToPutBattery = humanoidRootPart.CFrame * CFrame.new(0, -2, 0)

							break
						end
					end

					if not CFrameToPutBattery then CFrameToPutBattery = pivotCFrame end
				end
			end

			local map = workspace:FindFirstChild "Map" :: Model
			local batteriesFolder = map and map:FindFirstChild "Batteries" :: Folder

			local battery = data.model

			if not batteriesFolder or not CFrameToPutBattery then
				battery:Destroy()
			else
				battery.Parent = batteriesFolder
				battery:PivotTo(CFrameToPutBattery)
			end

			RoundDataManager.updateBatteryStatus(data.id, nil)

			break
		end
	end
end

ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
	if not RoundConfiguration.roundPhases[RoundDataManager.data.currentPhaseType] then return end

	if prompt.Name == "Battery" then
		for _, batteryData in pairs(RoundDataManager.data.batteryData) do
			if batteryData.holder == player.UserId then return end
		end

		local battery: Model = prompt.Parent.Parent

		local batteryDatas = RoundDataManager.data.batteryData

		for _, data in pairs(batteryDatas) do
			if data.model == battery then
				if data.holder ~= nil then return end

				data.model.Parent = nil

				RoundDataManager.updateBatteryStatus(data.id, player)

				break
			end
		end
	elseif prompt.Name == "HealRobot" then
		local toBeHealed = Players:GetPlayerFromCharacter(prompt.Parent.Parent)

		if not toBeHealed then return end

		local toBeHealedData = RoundDataManager.data.playerData[toBeHealed.UserId]
		local playerData = RoundDataManager.data.playerData[player.UserId]

		if not toBeHealedData or not playerData then return end

		if toBeHealedData.team ~= playerData.team then return end

		if toBeHealedData.status == Enums.PlayerStatus.dead then return end

		local isHoldingBattery = false

		for _, batteryData in pairs(RoundDataManager.data.batteryData) do
			if batteryData.holder == player.UserId then isHoldingBattery = true end
		end

		if not isHoldingBattery then return end

		putDownBattery(player, true)

		if toBeHealedData.status == Enums.PlayerStatus.lifeSupport then
			RoundDataManager.revivePlayer(toBeHealed)
		elseif toBeHealedData.status == Enums.PlayerStatus.alive then
			RoundDataManager.setHealth(toBeHealed, nil, 100)
		end
	end
end)

ClientServerCommunication.registerActionAsync("PutDownBattery", putDownBattery)

RoundDataManager.onPlayerStatusUpdated:Connect(function(playerData)
	if playerData.status == Enums.PlayerStatus.lifeSupport or playerData.status == Enums.PlayerStatus.dead then
		local player = Players:GetPlayerByUserId(playerData.playerId)

		if not player then return end

		putDownBattery(player)
	end
end)
