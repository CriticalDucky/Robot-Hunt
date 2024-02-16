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

ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
	if not RoundConfiguration.roundPhases[RoundDataManager.data.currentPhaseType] then return end

	if prompt.Name ~= "Terminal" then return end

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
		if data.hackers[player.UserId] then return end
	end

	for _, data in pairs(RoundDataManager.data.batteryData) do
		if data.holder == player.UserId then return end
	end

    local playerData = RoundDataManager.data.playerData[player.UserId]

    if not playerData then return end
    if playerData.status ~= Enums.PlayerStatus.alive then return end
    if playerData.actions.isHacking then return end
    if playerData.actions.isShooting then return end

    
end)

RunService.Heartbeat:Connect(function(dt)
    for _, terminalData in pairs(RoundDataManager.data.terminalData) do
        if terminalData.progress >= 100 then continue end

        
    end
end)