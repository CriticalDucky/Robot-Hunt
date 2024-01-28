local ProximityPromptService = game:GetService "ProximityPromptService"
local ServerStorage = game:GetService "ServerStorage"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Players = game:GetService "Players"

local GameLoop = ServerStorage.GameLoop
local Data = ReplicatedStorage.Data
local Utility = ReplicatedFirst.Utility

local RoundDataManager = require(GameLoop.RoundDataManager)
local ClientServerCommunication = require(Data.ClientServerCommunication)
local SpacialQuery = require(Utility.SpacialQuery)
local Table = require(Utility.Table)
local Types = require(Utility.Types)
local Enums = require(ReplicatedFirst.Enums)

type RoundPlayerData = Types.RoundPlayerData

local function putDownBattery(player: Player)
	print("putting down battery")

	assert(player and player.Character)

	local batteryDatas = RoundDataManager.data.batteryData

	print(batteryDatas)

	for _, data in pairs(batteryDatas) do
		print(1)
		if data.holder == player.UserId then
			print(2)
			local CFrameToPutBattery: CFrame?

			do
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

			print(3)

			local map = workspace:FindFirstChild "Map" :: Model
			local batteriesFolder = map and map:FindFirstChild "Batteries" :: Folder

			local battery = data.model

			if not batteriesFolder then
				battery:Destroy()
			else
				battery.Parent = batteriesFolder
				battery:PivotTo(CFrameToPutBattery)
			end

			print("this should print")

			RoundDataManager.updateBatteryHolder(data.id, nil)

			break
		end
	end
end

ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
	if prompt.Name == "Battery" then
		for _, batterData in pairs(RoundDataManager.data.batteryData) do
			if batterData.holder == player.UserId then return end
		end

		local battery: Model = prompt.Parent.Parent

		local batterDatas = RoundDataManager.data.batteryData

		for _, data in pairs(batterDatas) do
			if data.model == battery then
				if data.holder ~= nil then return end

				data.model.Parent = nil

				RoundDataManager.updateBatteryHolder(data.id, player)

				break
			end
		end
	end
end)

ClientServerCommunication.registerActionAsync("PutDownBattery", putDownBattery)

RoundDataManager.onPlayerStatusUpdated:Connect(function(playerData)
	if playerData.status == Enums.PlayerStatus.lifeSupport then
		local player = Players:GetPlayerByUserId(playerData.id)

		if not player then return end

		putDownBattery(player)
	end
end)

local function onPlayerManuallyQuits(player: Player)
	local playerDatas = RoundDataManager.data.playerData

	for _, playerData in pairs(playerDatas) do
		if playerData.playerId == player.UserId then
			local batteryDatas = RoundDataManager.data.batteryData

			for _, batteryData in pairs(batteryDatas) do
				if batteryData.holder == player.UserId then
					putDownBattery(player) -- bye bye :(

					break
				end
			end

			break
		end
	end
end

Players.PlayerRemoving:Connect(function(player) onPlayerManuallyQuits(player) end)

Players.PlayerAdded:Connect(function(player)
	player.CharacterRemoving:Connect(function(character) onPlayerManuallyQuits(player) end)
end)
