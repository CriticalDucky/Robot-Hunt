local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ContextActionService = game:GetService "ContextActionService"

local utilityFolder = ReplicatedFirst:WaitForChild "Utility"
local componentsFolder = ReplicatedStorage:WaitForChild("Interface"):WaitForChild "Components"

local ClientState = require(ReplicatedStorage:WaitForChild("Data"):WaitForChild "ClientState")
local ClientRoundDataUtility =
	require(ReplicatedStorage:WaitForChild("Data"):WaitForChild("RoundData"):WaitForChild "ClientRoundDataUtility")
local ClientServerCommunication =
	require(ReplicatedStorage:WaitForChild("Data"):WaitForChild "ClientServerCommunication")
local Platform = require(utilityFolder:WaitForChild "Platform")
local Enums = require(ReplicatedFirst:WaitForChild "Enums")
local RadialProgress = require(componentsFolder:WaitForChild "RadialProgress")
local Fusion = require(ReplicatedFirst:WaitForChild("Vendor"):WaitForChild "Fusion")
local Children = Fusion.Children
local OnEvent = Fusion.OnEvent

local scope = Fusion:scoped()
local peek = Fusion.peek

local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild "PlayerGui"
local puzzleGui = playerGui:WaitForChild("HUD"):WaitForChild("HUD"):WaitForChild("Terminal"):WaitForChild "Puzzle"

local MIN_OK_DISTANCE_FROM_ENDS = 0.25
local MIN_OK_SIZE = 0.15
local MAX_OK_SIZE = 0.3
local START_DELAY_TIME = 0.25 -- Time before the puzzle starts after being requested
local TRAVEL_TIME = 2.75
local TWEEN_INFO = TweenInfo.new(TRAVEL_TIME, Enum.EasingStyle.Linear, Enum.EasingDirection.In)
local RESET_TWEEN_INFO = TweenInfo.new(0)
local RESPONSE_ACTION = "RespondToPuzzle"
local RED_COLOR = Color3.fromRGB(255, 100, 0)
local PROGRESS_THICKNESS = 12
local TICKER_OVERFLOW = 4
local TICKER_WIDTH = 12 -- degrees

local puzzleComplete = scope:Value(true)

local tickerGoalPosition = scope:Value(0)
local tickerPositionAlpha = scope:Tween(
	tickerGoalPosition,
	scope:Computed(function(use)
		if use(tickerGoalPosition) == 0 then
			return RESET_TWEEN_INFO
		else
			return TWEEN_INFO
		end
	end)
)
local okZoneLowerAlpha = scope:Value(0)
local okZoneUpperAlpha = scope:Value(0)

local isInOKZone = scope:Computed(function(use)
	local okZoneLower = use(okZoneLowerAlpha)
	local okZoneUpper = use(okZoneUpperAlpha)
	local currentPosition = use(tickerPositionAlpha)

	return currentPosition >= okZoneLower and currentPosition <= okZoneUpper
end)

local function onResponse()
	puzzleComplete:set(true) -- Hide the puzzle GUI
	local success = peek(isInOKZone)
	ClientServerCommunication.replicateAsync("PromptTerminalPuzzle", {
		success = success,
	})
	if success then
		print "Puzzle completed successfully!"
	else
		print "Puzzle failed! Try again."
	end
end

local function bindResponseAction()
	ContextActionService:BindAction(RESPONSE_ACTION, function(_, inputState)
		if inputState == Enum.UserInputState.Begin then onResponse() end
	end, false, Enum.KeyCode.E, Enum.KeyCode.ButtonA) -- Bind to 'E' and console button 'A'
end

local function unbindResponseAction() ContextActionService:UnbindAction(RESPONSE_ACTION) end

local function onPuzzleRequest()
	puzzleComplete:set(false) -- Show the puzzle GUI
	tickerGoalPosition:set(0) -- Reset the ticker position
	local okSize = MIN_OK_SIZE + math.random() * (MAX_OK_SIZE - MIN_OK_SIZE)
	local okZoneLower = math.random() * (1 - okSize - MIN_OK_DISTANCE_FROM_ENDS * 2) + MIN_OK_DISTANCE_FROM_ENDS
	local okZoneUpper = okZoneLower + okSize
	okZoneLowerAlpha:set(okZoneLower)
	okZoneUpperAlpha:set(okZoneUpper)
	task.wait(START_DELAY_TIME) -- Wait before starting the puzzle
	tickerGoalPosition:set(1) -- Move the ticker to the end
	bindResponseAction() -- Bind the response action when the puzzle starts
	task.delay(TRAVEL_TIME, function()
		unbindResponseAction()

		if not peek(puzzleComplete) then
			onResponse() -- Automatically respond if the time runs out
		end
	end)
end

scope:Hydrate(puzzleGui) {
	Visible = scope:Computed(function(use)
		if use(puzzleComplete) then return false end
		local terminalData = use(ClientRoundDataUtility.currentHackingTerminal)
		if not terminalData then return false end
		return terminalData.isPuzzleMode
	end),

	[OnEvent "InputBegan"] = function(input, gameProcessedEvent) onResponse() end,

	[Children] = {
		scope:New "UICorner" {
			Name = "UICorner",
			CornerRadius = UDim.new(1, 0),
		},

		scope:New "Frame" {
			Name = "InteractInfo",
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(26, 26),

			[Children] = {
				scope:New "UICorner" {
					Name = "UICorner",
					CornerRadius = UDim.new(0, 4),
				},

				scope:New "ImageLabel" {
					Name = "Touch",
					BackgroundTransparency = 1,
					Image = "rbxassetid://17539902850",
					ImageColor3 = scope:Computed(
						function(use) return if use(isInOKZone) then Color3.new(1, 1, 1) else RED_COLOR end
					),
					Size = UDim2.fromScale(1, 1),
					Visible = scope:Computed(
						function(use) return use(Platform.platform) == Enums.PlatformType.Mobile end
					),
				},

				scope:New "TextLabel" {
					Name = "Keyboard",
					BackgroundColor3 = Color3.new(),
					BackgroundTransparency = 0.75,
					FontFace = Font.new(
						"rbxasset://fonts/families/TitilliumWeb.json",
						Enum.FontWeight.Heavy,
						Enum.FontStyle.Normal
					),
					Size = UDim2.fromScale(1, 1),
					Text = scope:Computed(function(use)
						local platform = use(Platform.platform)

						if platform == Enums.PlatformType.Console then
							return "A"
						else
							return "E"
						end
					end),
					TextColor3 = scope:Computed(
						function(use) return if use(isInOKZone) then Color3.new(1, 1, 1) else RED_COLOR end
					),
					TextScaled = true,
					Visible = scope:Computed(
						function(use) return use(Platform.platform) ~= Enums.PlatformType.Mobile end
					),

					[Children] = {
						scope:New "UICorner" {
							Name = "UICorner",
							CornerRadius = UDim.new(0, 4),
						},

						scope:New "UIStroke" {
							Name = "UIStroke",
							Thickness = 2,
						},
					},
				},
			},
		},

		RadialProgress(scope, {
			Name = "Ticker",
			Progress = TICKER_WIDTH / 360 * 100,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1) + UDim2.fromOffset(TICKER_OVERFLOW, TICKER_OVERFLOW),

			ProgressThickness = PROGRESS_THICKNESS + TICKER_OVERFLOW,
			ProgressColor = RED_COLOR,
			BackgroundTransparency = 1,

			Rotation = scope:Computed(function(use)
				local offset = TICKER_WIDTH / 2
				local position = use(tickerPositionAlpha) * 360
				return position - offset
			end),

			ZIndex = 5,
		}),

		RadialProgress(scope, {
			Name = "OKZoneAndBackground",
			Progress = scope:Computed(function(use)
				local lower = use(okZoneLowerAlpha)
				local upper = use(okZoneUpperAlpha)
				return (upper - lower) * 100
			end),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),

			ProgressThickness = PROGRESS_THICKNESS,
			ProgressColor = Color3.new(1, 1, 1),
			BackgroundTransparency = 0.75,
			BackgroundColor = Color3.new(),
			Rotation = scope:Computed(function(use) return use(okZoneLowerAlpha) * 360 end),
			ZIndex = 4,
		}),
	},
}

ClientServerCommunication.registerActionAsync("PromptTerminalPuzzle", function()
	onPuzzleRequest()
end)
