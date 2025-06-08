local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local Players = game:GetService "Players"

local BannerNotifications =
	require(ReplicatedStorage:WaitForChild("Interface"):WaitForChild("Utility"):WaitForChild "BannerNotifications")
local ClientState = require(ReplicatedStorage:WaitForChild("Data"):WaitForChild "ClientState")
local ClientRoundDataUtility =
	require(ReplicatedStorage:WaitForChild("Data"):WaitForChild("RoundData"):WaitForChild "ClientRoundDataUtility")
local RoundConfiguration = require(ReplicatedStorage:WaitForChild("Configuration"):WaitForChild "RoundConfiguration")
local Enums = require(ReplicatedFirst:WaitForChild "Enums")
local Fusion = require(ReplicatedFirst:WaitForChild("Vendor"):WaitForChild "Fusion")

local scope = Fusion:scoped()
local peek = Fusion.peek
local Children = Fusion.Children
local player = Players.LocalPlayer

local currentPhase = ClientState.external.roundData.currentPhaseType
local currentRound = ClientState.external.roundData.currentRoundType
local terminalDatas = ClientState.external.roundData.terminalData
local numRequiredTerminals = ClientState.external.roundData.numRequiredTerminals
local isGameOver = ClientState.external.roundData.isGameOver
local playerDatas = ClientState.external.roundData.playerData

local function handlePhaseChange()
	local currentPhaseType = peek(currentPhase)
	local isGameOverValue = peek(isGameOver)
	local currentRoundType = peek(currentRound)
	local localPlayerData = peek(playerDatas)[player.UserId]

	local isLobby = if localPlayerData then localPlayerData.isLobby else true

	if currentPhaseType == Enums.PhaseType.NotEnoughPlayers then
		BannerNotifications.addToQueue(
			0,
			"Not Enough Players",
			"Waiting for one more player to join...",
			Color3.fromRGB(120, 155, 230),
			true
		)
	elseif currentPhaseType == Enums.PhaseType.Intermission then
		BannerNotifications.cancelAll()
	elseif currentPhaseType == Enums.PhaseType.Infiltration then
		if isLobby then return end
		local infiltrationLength = RoundConfiguration.timeLengths[currentRoundType][currentPhaseType]

		if localPlayerData.team == Enums.TeamType.hunters then
			BannerNotifications.addToQueue(
				5,
				"You are a Hunter",
				"You will arrive at your destination shortly...",
				Color3.fromRGB(255, 100, 100),
				true
			)
		elseif localPlayerData.team == Enums.TeamType.rebels then
			BannerNotifications.addToQueue(
				5,
				"You are a Rebel",
				("You have %s seconds before the hunters arrive — hack all terminals to win!"):format(
					infiltrationLength
				),
				Color3.fromRGB(127, 214, 250),
				true
			)
		end
	elseif currentPhaseType == Enums.PhaseType.PhaseOne then
		if isLobby or localPlayerData.team == Enums.TeamType.rebels then
			BannerNotifications.addToQueue(3, "The Hunters have arrived!", nil, Color3.fromRGB(255, 100, 100), true)
		elseif localPlayerData.team == Enums.TeamType.hunters then
			BannerNotifications.addToQueue(
				5,
				"Phase One",
				"Eliminate all rebels before they hack the terminals!",
				Color3.fromRGB(255, 100, 100),
				true
			)
		end
	elseif currentPhaseType == Enums.PhaseType.PhaseTwo then
		if isLobby then
			BannerNotifications.addToQueue(
				5,
				"Phase Two",
				"The rebels have hacked all terminals!",
				Color3.fromRGB(250, 175, 0),
				true
			)
		elseif localPlayerData.team == Enums.TeamType.rebels then
			BannerNotifications.addToQueue(
				5,
				"Phase Two",
				"Good work, agent — eliminate all hunters to win!",
				Color3.fromRGB(250, 175, 0),
				true
			)
		elseif localPlayerData.team == Enums.TeamType.hunters then
			BannerNotifications.addToQueue(
				5,
				"Phase Two",
				"The rebels have hacked all terminals — watch out for their guns!",
				Color3.fromRGB(250, 175, 0),
				true
			)
		end
	elseif currentPhaseType == Enums.PhaseType.Purge then -- Happens when rebels dont hack all terminals in time at the end of Phase One
		if isLobby then
			BannerNotifications.addToQueue(
				5,
				"The Purge",
				"The rebels have failed to hack all terminals in time!",
				Color3.fromRGB(255, 100, 100),
				true
			)
		elseif localPlayerData.team == Enums.TeamType.rebels then
			BannerNotifications.addToQueue(
				5,
				"The Purge",
				"Your location has been compromised — hack all terminals quickly!",
				Color3.fromRGB(255, 100, 100),
				true
			)
		elseif localPlayerData.team == Enums.TeamType.hunters then
			BannerNotifications.addToQueue(
				5,
				"The Purge",
				"The rebels have failed to hack all terminals in time — eliminate them to win!",
				Color3.fromRGB(255, 100, 100),
				true
			)
		end
	end
end

local function getTeamColoredName(subjectData)
    local name = Players:GetPlayerByUserId(subjectData.playerId) 
        and Players:GetPlayerByUserId(subjectData.playerId).Name
        or Players:GetNameFromUserIdAsync(subjectData.playerId)
        
    local teamColor = if subjectData.team == Enums.TeamType.hunters 
        then "rgb(255, 100, 100)" 
        else "rgb(127, 214, 250)"
        
    return string.format('<font color="%s">%s</font>', teamColor, name)
end

ClientRoundDataUtility.playerStatusChanged.Event:Connect(function(subjectId, status)
	local subjectData = peek(playerDatas)[subjectId]
	if not subjectData then return end
	local localPlayerData = peek(playerDatas)[player.UserId]

	local isLocalPlayerLobby = if localPlayerData then localPlayerData.isLobby else true

	if subjectId == player.UserId and status == Enums.PlayerStatus.dead then
		BannerNotifications.addToQueue(5, "You have been eliminated!", nil, Color3.fromRGB(255, 100, 100), true)

		return
	end

	local function getSubjectName()
		local id = subjectData.playerId
		return Players:GetPlayerByUserId(id) and Players:GetPlayerByUserId(id).Name
			or Players:GetNameFromUserIdAsync(id)
	end

	if status == Enums.PlayerStatus.dead then
		local teamName = if subjectData.team == Enums.TeamType.hunters then "Hunters" else "Rebels"
		local deathColor = Color3.fromRGB(200, 80, 80) -- Consistent death notification color

		BannerNotifications.addToQueue(
			5,
			string.format("%s has been eliminated!", getTeamColoredName(subjectData)),
			string.format("The %s are down a player!", teamName),
			deathColor
		)
	elseif status == Enums.PlayerStatus.lifeSupport then
		local lifeSupportColor = Color3.fromRGB(85, 129, 242)

		if subjectId == player.UserId then -- runs when player is put into life support. btw, ppl get revived from life support when a teammate brings a battery and revives them.
			local numberOfAliveTeammates = 0
			for _, data in pairs(peek(playerDatas)) do
				if data.status == Enums.PlayerStatus.alive and data.team == subjectData.team then
					numberOfAliveTeammates += 1
				end
			end

			BannerNotifications.addToQueue(
				5,
				"You are now on life support!",
				if numberOfAliveTeammates ~= 0 then "Wait for a teammate to revive you with a battery." else nil,
				lifeSupportColor,
				true
			)
		else
			if isLocalPlayerLobby then
				BannerNotifications.addToQueue(4, string.format("%s is on life support!", getTeamColoredName(subjectData)), nil, lifeSupportColor)
			else
				local isEnemy = subjectData.team ~= localPlayerData.team

				local teammateText = "Bring a battery to revive them!"

				BannerNotifications.addToQueue( -- format string to include team text
					4,
					string.format("%s is on life support!", getTeamColoredName(subjectData)),
					if isEnemy then nil else teammateText,
					lifeSupportColor
				)
			end
		end
	end
end)

ClientRoundDataUtility.terminalCompleted.Event:Connect(function(terminalId)
	local terminalData = peek(terminalDatas)[terminalId]
	if not terminalData then return end
	local numRequiredTerminals = peek(numRequiredTerminals)
	if not numRequiredTerminals then return end

	if terminalData.progress >= 100 then
        local terminalsLeft
        do
            local numCompletedTerminals = 0
    
            for _, terminal in pairs(peek(terminalDatas)) do
                if terminal.progress >= 100 then
                    numCompletedTerminals += 1
                end
            end
    
            terminalsLeft = numRequiredTerminals - numCompletedTerminals
        end
    
        if terminalsLeft <= 0 then return end -- phase two is about to begin and it already has a notification

		BannerNotifications.addToQueue(
			5,
            "Terminal Hacked!",
            string.format("%d Terminal%s Left", terminalsLeft, if terminalsLeft == 1 then "" else "s"),
            Color3.fromRGB(114, 255, 239)
		)
	end
end)

scope:Observer(currentPhase):onChange(handlePhaseChange)

handlePhaseChange()
