--#region Imports
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local replicatedStorageShared = ReplicatedStorage:WaitForChild "Shared"
local replicatedFirstVendor = ReplicatedFirst:WaitForChild "Vendor"
local componentsFolder = replicatedStorageShared:WaitForChild("Interface"):WaitForChild "Components"

local Fusion = require(replicatedFirstVendor:WaitForChild "Fusion")
local New = Fusion.New
local Children = Fusion.Children
local Value = Fusion.Value
local Computed = Fusion.Computed
local Observer = Fusion.Observer
local peek = Fusion.peek

--#endregion

local playerGui = game:GetService("Players").LocalPlayer:WaitForChild "PlayerGui"
local partyMenu = require(componentsFolder:WaitForChild "PartyMenu")

local a = Value(1)
local b = Value(2)

local computed = Computed(function(use)
	return use(a) * use(b)
end)

Observer(computed):onChange(function()
	print("Computed value changed to", peek(computed))
end)

task.spawn(function()
	while true do
		task.wait(3)
		-- disabled:set(not peek(disabled))
		a:set(peek(a) + 1)
		b:set(peek(b) + 3)
	end
end)

New "ScreenGui" {
	Name = "TestGui",
	Parent = playerGui,

	[Children] = {
		-- outlinedFrame {
		-- 	Position = UDim2.new(0.5, 0, 0.5, 0),
		-- 	Size = UDim2.new(0, 400, 0, 250),
		-- 	AnchorPoint = Vector2.new(0.5, 0.5),

		-- 	OutlineColor = InterfaceConstants.colors.menuGreen1,
		-- 	BackgroundColor = InterfaceConstants.colors.menuBackground,

		-- 	PaddingTop = UDim.new(0, 20),

		-- 	Children = {
		-- 		bubbleButton {
		-- 			Position = UDim2.fromScale(0.5, 0.5),
		-- 			AnchorPoint = Vector2.new(0.5, 0.5),
		-- 			SizeX = 50,
		-- 			Text = "Hello world!",
		-- 			OnClick = function() end,
		-- 			Disabled = disabled,
		-- 		},

		-- 		bannerButton {
		-- 			BorderColor = InterfaceConstants.colors.menuGreen1,
		-- 			Size = UDim2.fromOffset(250, 150),
		-- 			Position = UDim2.fromScale(0.5, 0.5),
		-- 			AnchorPoint = Vector2.new(0.5, 0.5),
		-- 			ZoomOnHover = true,
		-- 			Image = "rbxassetid://3317811687",
		-- 		},

		-- 		floatingIconButton {
		-- 			AnchorPoint = Vector2.new(0.5, 0.5),
		-- 			Position = UDim2.fromScale(0.5, 0.5),
		-- 			Size = UDim2.fromOffset(48, 48),

		-- 			Image = "rbxassetid://13370286402",
		-- 			OutlineImage = "rbxassetid://13370286263",
		-- 		},

		-- 		sliderBase {
		-- 			AnchorPoint = Vector2.new(0.5, 0.5),
		-- 			Position = UDim2.fromScale(0.5, 0.5),
		-- 			Size = UDim2.fromOffset(200, 20),

		-- 			BackgroundBody = New "Frame" {
		-- 				AnchorPoint = Vector2.new(0.5, 0.5),
		-- 				Position = UDim2.fromScale(0.5, 0.5),
		-- 				Size = UDim2.fromScale(1, 1),

		-- 				BackgroundColor3 = Color3.new(0.678431, 0.678431, 0.678431),
		-- 			},
		-- 			SliderBody = New "Frame" {
		-- 				AnchorPoint = Vector2.new(0.5, 0.5),
		-- 				Position = UDim2.fromScale(0.5, 0.5),
		-- 				Size = UDim2.fromScale(1, 1),
		-- 				BackgroundTransparency = 0.2,

		-- 				BackgroundColor3 = Color3.new(1, 1, 1),
		-- 			},
		-- 			SliderSize = UDim2.fromOffset(24, 24),
		-- 			ProgressAlpha = progressAlpha,
		-- 			InputProgressChanged = sliderFunction,
		-- 			BackgroundInputShrink = Vector2.new(32, 8),
		-- 		},

		-- 		bubbleSlider {
		-- 			AnchorPoint = Vector2.new(0.5, 0.5),
		-- 			Position = UDim2.fromScale(0.5, 0.5),
		-- 			SizeX = UDim.new(0, 250),
		-- 			Disabled = disabled,

		-- 			ProgressAlpha = progressAlpha,
		-- 			InputProgressChanged = sliderFunction,
		-- 		},

		-- 		bubbleToggle {
		-- 			AnchorPoint = Vector2.new(0.5, 0.5),
		-- 			Position = UDim2.fromScale(0.5, 0.5),

		-- 			State = state,
		-- 			OnClick = function() state:set(not peek(state)) end,
		-- 			Disabled = disabled,
		-- 		},
		-- 	},
		-- },

		-- outlinedMenu {
		-- 	AnchorPoint = Vector2.new(0.5, 0.5),
		-- 	Position = UDim2.fromScale(0.5, 0.5),
		-- 	Size = UDim2.fromOffset(400, 350),

		-- 	TitleText = "LETS GO!",
		-- 	onExitButtonClicked = function() print "Exit button clicked!" end,
		-- },

		-- settingsMenu {
		-- 	AnchorPoint = Vector2.new(0.5, 0.5),
		-- 	Position = UDim2.fromScale(0.5, 0.5),
		-- 	Size = UDim2.fromOffset(325, 400),

		-- 	onExitRequest = function() print "Exit button clicked!" end,
		-- }

		partyMenu {
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(400, 400),

			onExitRequest = function() print "Exit button clicked!" end,
		}
	},
}
