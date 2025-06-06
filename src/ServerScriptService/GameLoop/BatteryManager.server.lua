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

local function disappearBatteryModel(battery: Model) -- anchor it, put it somewhere hidden very far away
	if not battery then return end

	local batteryBody = battery:FindFirstChild "Body" :: Part
	if not batteryBody then return end

	batteryBody.Anchored = true

	local map = workspace:FindFirstChild "Map" :: Model
	if not map then return end

	local hiddenFolder = map:FindFirstChild "HiddenBatteries" :: Folder
	if not hiddenFolder then
		hiddenFolder = Instance.new "Folder"
		hiddenFolder.Name = "HiddenBatteries"
		hiddenFolder.Parent = map
	end

	battery.Parent = hiddenFolder
	battery:PivotTo(CFrame.new(0, -10000, 0))
end

local function reappearBatteryModel(battery: Model, CFrameToPutBattery: CFrame, player: Player)
	if not battery then return end
	if not CFrameToPutBattery then return end

	local map = workspace:FindFirstChild "Map" :: Model
	if not map then return end

	local batteriesFolder = map:FindFirstChild "Batteries" :: Folder
	if not batteriesFolder then return end

	local body = battery:FindFirstChild "Body" :: Part
	if not body then return end

	battery.Parent = batteriesFolder
	battery:PivotTo(CFrameToPutBattery)
	body.Anchored = false
	body:SetNetworkOwner(player)
	task.defer(function()
		if body and body:IsDescendantOf(batteriesFolder) and player:IsDescendantOf(Players)then
			body:SetNetworkOwner(player) -- ugh
		end
	end)
end

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
				reappearBatteryModel(battery, CFrameToPutBattery, player)
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

				disappearBatteryModel(battery)

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
