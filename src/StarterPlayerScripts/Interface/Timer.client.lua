local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local Players = game:GetService "Players"

local ClientState = require(ReplicatedStorage:WaitForChild("Data"):WaitForChild "ClientState")
local Enums = require(ReplicatedFirst:WaitForChild "Enums")
local Fusion = require(ReplicatedFirst:WaitForChild("Vendor"):WaitForChild "Fusion")
local Time = require(ReplicatedFirst:WaitForChild("Utility"):WaitForChild "Time")

local scope = Fusion.scoped(Fusion)
local peek = Fusion.peek
local Children = Fusion.Children

local player = Players.LocalPlayer
local playerGui = player:WaitForChild "PlayerGui"

local PHASE_TITLES = {
	[Enums.PhaseType.Intermission] = "Intermission",
	[Enums.PhaseType.Infiltration] = "Infiltration",
	[Enums.PhaseType.PhaseOne] = "Phase One",
	[Enums.PhaseType.PhaseTwo] = "Phase Two",
	[Enums.PhaseType.Purge] = "Purge",
}

local PHASE_TITLE_COLORS = {
	[Enums.PhaseType.Intermission] = Color3.fromRGB(198, 209, 226),
	[Enums.PhaseType.Infiltration] = Color3.fromRGB(188, 183, 255),
	[Enums.PhaseType.PhaseOne] = Color3.fromRGB(127, 214, 250),
	[Enums.PhaseType.PhaseTwo] = Color3.fromRGB(250, 175, 0),
	[Enums.PhaseType.Purge] = Color3.fromRGB(255, 100, 0),
}

local NO_TIMER_PHASES = {
	[Enums.PhaseType.Loading] = true,
	[Enums.PhaseType.NotEnoughPlayers] = true,
	[Enums.PhaseType.Results] = true,
}

local TRANSITION_TIME = 0.5
local OFFSCREEN_SLIDEIN_TIMERGUI_INFO =
	TweenInfo.new(TRANSITION_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, TRANSITION_TIME)
local OFFSCREEN_SLIDEOUT_TIMERGUI_INFO =
	TweenInfo.new(TRANSITION_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, 0)

local currentTitlePhase = scope:Value()
local displayPhase = scope:Value() -- New state for delayed phase display
local isTransitioning = scope:Value(false)

local currentPhase = scope:Computed(function(use) return use(ClientState.external.roundData.currentPhaseType) end)
local isGameOver = scope:Computed(function(use) return use(ClientState.external.roundData.isGameOver) end)

local timerEnabled = scope:Computed(
	function(use)
		return not NO_TIMER_PHASES[use(currentPhase)]
			and use(ClientState.external.roundData.phaseEndTime) ~= nil
			and not use(isGameOver)
			and not use(isTransitioning)
	end
)

local timerPosition = scope:Tween(
	scope:Computed(function(use)
		if use(timerEnabled) then
			return UDim2.fromScale(0.5, 0)
		else
			return UDim2.fromScale(0.5, 0) - UDim2.fromOffset(0, 90)
		end
	end),
	scope:Computed(function(use)
		if use(timerEnabled) then
			return OFFSCREEN_SLIDEIN_TIMERGUI_INFO
		else
			return OFFSCREEN_SLIDEOUT_TIMERGUI_INFO
		end
	end)
)

scope:New "ScreenGui" {
	Name = "TimerGui",
	IgnoreGuiInset = true,
	ScreenInsets = Enum.ScreenInsets.None,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	ResetOnSpawn = false,
	Parent = playerGui,

	[Children] = {
		scope:New "Frame" {
			Name = "Timer",
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1,
			Position = timerPosition,
			Size = UDim2.fromOffset(100, 75),

			[Children] = {
				scope:New "TextLabel" {
					Name = "Time",
					BackgroundTransparency = 1,
					FontFace = Font.new(
						"rbxasset://fonts/families/TitilliumWeb.json",
						Enum.FontWeight.Heavy,
						Enum.FontStyle.Normal
					),
					Position = UDim2.fromOffset(0, 10),
					RichText = true,
					Size = UDim2.new(1, 0, 0, 20),
					Text = scope:Computed(function(use)
						if NO_TIMER_PHASES[use(currentPhase)] then return "0:00" end
						local phaseEndTime = use(ClientState.external.roundData.phaseEndTime)
						if not phaseEndTime then return "0:00" end
						local timeLeft = math.max(0, phaseEndTime - use(Time.unixValue))
						local minutes = math.floor(timeLeft / 60)
						local seconds = timeLeft % 60
						return string.format("%d:%02d", minutes, seconds)
					end),
					TextColor3 = Color3.new(1, 1, 1),
					TextSize = 40,
				},

				scope:New "TextLabel" {
					Name = "Title",
					BackgroundTransparency = 1,
					FontFace = Font.new(
						"rbxasset://fonts/families/TitilliumWeb.json",
						Enum.FontWeight.Heavy,
						Enum.FontStyle.Normal
					),
					Position = UDim2.fromOffset(0, 32),
					Size = UDim2.new(1, 0, 0, 25),
					Text = scope:Computed(function(use)
						local phase = use(currentTitlePhase)
						if not phase then return "" end
						return string.upper(PHASE_TITLES[phase] or "UNKOWN")
					end),
					TextColor3 = scope:Computed(function(use)
						local phase = use(currentTitlePhase)
						if not phase then return Color3.new(1, 1, 1) end
						return PHASE_TITLE_COLORS[phase] or Color3.new(1, 1, 1)
					end),
					TextSize = 30,
				},

				scope:New "TextLabel" {
					Name = "Info",
					BackgroundTransparency = 1,
					FontFace = Font.new(
						"rbxasset://fonts/families/TitilliumWeb.json",
						Enum.FontWeight.Heavy,
						Enum.FontStyle.Normal
					),
					Position = UDim2.fromOffset(0, 56),
					RichText = true,
					Size = UDim2.new(1, 0, 0, 25),
					Text = scope:Computed(function(use)
						local phase = use(displayPhase) or use(currentPhase)
						local playerData = use(ClientState.external.roundData.playerData)[player.UserId]
						local team = playerData and playerData.team

						local function getNumOpposingPlayers()
							local playerDatas = use(ClientState.external.roundData.playerData)
							local numOpposingPlayers = 0

							for _, data in pairs(playerDatas) do
								if data.team ~= team and data.status == Enums.PlayerStatus.alive then
									numOpposingPlayers += 1
								end
							end

							return numOpposingPlayers
						end

						local function getNumRebelsLeft()
							local playerDatas = use(ClientState.external.roundData.playerData)
							local numRebelsLeft = 0

							for _, data in pairs(playerDatas) do
								if data.team == Enums.TeamType.rebels and data.status == Enums.PlayerStatus.alive then
									numRebelsLeft += 1
								end
							end

							return numRebelsLeft
						end

						local terminalsLeft
						do
							local terminals = use(ClientState.external.roundData.terminalData)
							local numCompletedTerminals = 0
							local numRequiredTerminals = use(ClientState.external.roundData.numRequiredTerminals)

							if numRequiredTerminals then
								if terminals then
									for _, terminal in pairs(terminals) do
										if terminal.progress >= 100 then
											numCompletedTerminals += 1
										end
									end
								end

								terminalsLeft = numRequiredTerminals - numCompletedTerminals
							else
								terminalsLeft = 0
							end
						end

						-- Always show terminals during Phase One, even during transition
						if phase == Enums.PhaseType.PhaseOne or use(displayPhase) == Enums.PhaseType.PhaseOne then
							return string.format(
								'<stroke color="rgb(50, 100, 0)" transparency="1" thickness="2"><font size="30">%d </font></stroke> <b>Terminal%s Left</b>',
								terminalsLeft,
								if terminalsLeft == 1 then "" else "s"
							)
						end

						if
							phase == Enums.PhaseType.Infiltration
							or phase == Enums.PhaseType.Purge
							or use(displayPhase) == Enums.PhaseType.Purge
						then
							if terminalsLeft <= 0 then
								local numOpposingPlayers = getNumOpposingPlayers()
								local opposingTeamName = if team == Enums.TeamType.hunters then "Rebel" else "Hunter"
								return string.format(
									'<stroke color="rgb(50, 100, 0)" transparency="1" thickness="2"><font size="30">%d </font></stroke> <b>%s Left</b>',
									numOpposingPlayers,
									opposingTeamName .. (if numOpposingPlayers == 1 then "" else "s")
								)
							end

							return string.format(
								'<stroke color="rgb(50, 100, 0)" transparency="1" thickness="2"><font size="30">%d </font></stroke> <b>Terminal%s Left</b>',
								terminalsLeft,
								if terminalsLeft == 1 then "" else "s"
							)
						elseif phase == Enums.PhaseType.PhaseTwo and playerData and not playerData.isLobby then
							local numOpposingPlayers = getNumOpposingPlayers()
							local opposingTeamName = if team == Enums.TeamType.hunters then "Rebel" else "Hunter"
							return string.format(
								'<stroke color="rgb(50, 100, 0)" transparency="1" thickness="2"><font size="30">%d </font></stroke> <b>%s Left</b>',
								numOpposingPlayers,
								opposingTeamName .. (if numOpposingPlayers == 1 then "" else "s")
							)
						elseif phase == Enums.PhaseType.PhaseTwo and (not playerData or playerData.isLobby) then
							local numRebelsLeft = getNumRebelsLeft()
							return string.format(
								'<stroke color="rgb(50, 100, 0)" transparency="1" thickness="2"><font size="30">%d </font></stroke> <b>Rebel%s Left</b>',
								numRebelsLeft,
								if numRebelsLeft == 1 then "" else "s"
							)
						end

						return ""
					end),
					TextColor3 = Color3.fromRGB(254, 252, 255),
					TextSize = 24,
				},

				scope:New "ImageLabel" {
					Name = "Backdrop",
					AnchorPoint = Vector2.new(0.5, 0),
					BackgroundTransparency = 1,
					Image = "rbxassetid://113725185691376",
					ImageColor3 = Color3.new(),
					ImageTransparency = 0.75,
					Position = UDim2.new(0.5, 0, 0, -10),
					Size = UDim2.fromOffset(220, 80),
					ZIndex = 0,
				},
			},
		},
	},
}

local function manageCurrentTitlePhase(phase)
	if not phase then return end

	if
		phase == Enums.PhaseType.Loading
		or phase == Enums.PhaseType.NotEnoughPlayers
		or phase == Enums.PhaseType.Results
	then
		return
	end

	-- Start transition
	isTransitioning:set(true)

	-- Wait for the GUI to slide out
	task.delay(TRANSITION_TIME, function()
		-- Update the display phase
		displayPhase:set(phase)
		currentTitlePhase:set(phase)
		isTransitioning:set(false)
	end)
end

scope:Observer(currentPhase):onChange(function()
	local phase = peek(currentPhase)
	manageCurrentTitlePhase(phase)
end)

manageCurrentTitlePhase(peek(currentPhase))
