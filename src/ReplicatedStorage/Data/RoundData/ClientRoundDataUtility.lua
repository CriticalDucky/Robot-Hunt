local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ReplicatedFirst = game:GetService "ReplicatedFirst"

local dataFolder = ReplicatedStorage:WaitForChild "Data"
local configurationFolder = ReplicatedStorage:WaitForChild "Configuration"

local ClientState = require(dataFolder:WaitForChild "ClientState")
local ClientServerCommunication = require(dataFolder:WaitForChild "ClientServerCommunication")
local Enums = require(ReplicatedFirst:WaitForChild "Enums")
local RoundConfiguration = require(configurationFolder:WaitForChild "RoundConfiguration")
local PhaseType = Enums.PhaseType

local Fusion = require(ReplicatedFirst:WaitForChild("Vendor"):WaitForChild "Fusion")

local scope = Fusion.scoped(Fusion)
local peek = Fusion.peek

local roundPhases = RoundConfiguration.roundPhases

local ClientRoundDataUtility = {}

-- Event that fires when the map is finished loading
ClientRoundDataUtility.mapLoadingFinished = Instance.new "BindableEvent"
ClientRoundDataUtility.setUpRound = Instance.new "BindableEvent"
ClientRoundDataUtility.playerStatusChanged = Instance.new "BindableEvent"
ClientRoundDataUtility.terminalCompleted = Instance.new "BindableEvent"

-- Whether or not players are currently loaded into the map
ClientRoundDataUtility.isRoundActive = scope:Computed(function(use)
	local roundData = ClientState.external.roundData
	local currentPhase = use(roundData.currentPhaseType)
	local currentRoundType = use(roundData.currentRoundType)

	return roundPhases[currentPhase] and currentRoundType ~= nil
end)

ClientRoundDataUtility.isGunEnabled = scope:Computed(function(use)
	local resultTable: { [number]: boolean } = {}

	local isGameRunning = use(ClientRoundDataUtility.isRoundActive)

	if not isGameRunning then return resultTable end

	local roundData = ClientState.external.roundData
	local roundPlayerData = use(roundData.playerData)
	local currentRoundType = use(roundData.currentRoundType) -- gamemode

	for _, playerData in pairs(roundPlayerData) do
		local playerId = playerData.playerId

		local isAlive = not (playerData.status == Enums.PlayerStatus.dead)

		if not isAlive then continue end

		if currentRoundType == Enums.RoundType.defaultRound then
			local team = playerData.team
			local phase = use(roundData.currentPhaseType)

			if team == Enums.TeamType.hunters or phase == PhaseType.PhaseTwo then resultTable[playerId] = true end
		else
			if currentRoundType ~= nil then error "Gamemode has no gun enabled check implemented" end
		end
	end

	return resultTable
end)

ClientRoundDataUtility.isHacking = scope:Computed(function(use)
	local roundData = ClientState.external.roundData
	local playerData = use(roundData.playerData)

	local clientPlayerData
	do
		for _, data in pairs(playerData) do
			if data.playerId == game.Players.LocalPlayer.UserId then
				clientPlayerData = data
				break
			end
		end
	end

	return clientPlayerData and clientPlayerData.actions.isHacking or false
end)

ClientRoundDataUtility.currentHackingTerminal = scope:Computed(function(use)
	local roundData = ClientState.external.roundData
	local terminalData = use(roundData.terminalData)

	if not terminalData then return nil end

	for _, data in pairs(terminalData) do
		local hackers = data.hackers
		for _, hacker in pairs(hackers) do
			if hacker == game.Players.LocalPlayer then
				return data
			end
		end
	end

	return nil
end)

ClientRoundDataUtility.isHoldingBattery = scope:Computed(function(use)
	local roundData = ClientState.external.roundData
	local batteryData = use(roundData.batteryData)

	for _, data in pairs(batteryData) do
		if data.holder == game.Players.LocalPlayer.UserId then return true end
	end

	return false
end)

ClientServerCommunication.registerActionAsync(
	"MapLoadingFinished",
	function() ClientRoundDataUtility.mapLoadingFinished:Fire() end
)


return ClientRoundDataUtility
