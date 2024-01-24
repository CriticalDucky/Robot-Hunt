local ProximityPromptService = game:GetService "ProximityPromptService"
local ServerStorage = game:GetService "ServerStorage"

local GameLoop = ServerStorage.GameLoop

local RoundDataManager = require(GameLoop.RoundDataManager)

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

				RoundDataManager.updateBatteryHolder(data.id, player)

				break
			end
		end
	end
end)
