--#region Imports
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local replicatedStorageShared = ReplicatedStorage:WaitForChild "Shared"
local replicatedFirstVendor = ReplicatedFirst:WaitForChild "Vendor"
local replicatedFirstShared = ReplicatedFirst:WaitForChild "Shared"
local componentsFolder = replicatedStorageShared:WaitForChild("Interface"):WaitForChild "Components"

local outlinedMenu = require(componentsFolder:WaitForChild "OutlinedMenu")
local bubbleButton = require(componentsFolder:WaitForChild "BubbleButton")
local bubbleToggle = require(componentsFolder:WaitForChild "BubbleToggle")
local bubbleSlider = require(componentsFolder:WaitForChild "BubbleSlider")
local roundCornerMask = require(componentsFolder:WaitForChild "RoundCornerMask")
local InterfaceConstants = require(replicatedFirstShared:WaitForChild("Configuration"):WaitForChild "InterfaceConstants")

-- Optional: Remove imports that you don't need
local Fusion = require(replicatedFirstVendor:WaitForChild "Fusion")
local New = Fusion.New
local Children = Fusion.Children
local Out = Fusion.Out
local Value = Fusion.Value
local Computed = Fusion.Computed
local peek = Fusion.peek

---@diagnostic disable-next-line: undefined-type uhguhguhgughguhgh
type CanBeState<T> = Fusion.CanBeState<T>
type StateObject<T> = Fusion.StateObject<T>
-- #endregion

export type Props = {
	Position: CanBeState<UDim2>?,
	AnchorPoint: CanBeState<Vector2>?,
	Size: CanBeState<UDim2>?,
	ZIndex: CanBeState<number>?,

	onExitRequest: (any) -> nil,
}

type PelletProps = {
	-- Text and ImageId are mutually exclusive. ImageSize is optional and only relevant if ImageId is set.
	Text: CanBeState<string>?,
	ImageId: CanBeState<string>?,
	ImageSize: CanBeState<UDim2>?,
	ImageColor3: CanBeState<Color3>?,
	InputType: "toggle" | "slider",
	Disabled: CanBeState<boolean>?,

	State: StateObject<boolean | number>, -- The state of the toggle or slider or other input.

	listener: ((any) -> ()), -- Should edit the player settings, or in other words the state.
}

--[[
	This component creates the settings menu.
]]
local function Component(props: Props)
	local toggleType = "toggle"
	local sliderType = "slider"

	local absoluteWindowSize = Value(Vector2.new(0, 0))
	local absoluteCanvasSize = Value(Vector2.new(0, 0))

	local isScrollingMode = Computed(function(use) return use(absoluteWindowSize).Y < use(absoluteCanvasSize).Y end)

	local function pellet(pelletProps: PelletProps)
		local inputType = pelletProps.InputType
		local listener = pelletProps.listener
		local state = pelletProps.State

		local frame = New "Frame" {
			Size = Computed(function(use) return UDim2.new(1, use(isScrollingMode) and -12, 0, 64) end),
			BackgroundColor3 = InterfaceConstants.colors.menuShaded,

			[Children] = {
				New "UICorner" {
					CornerRadius = UDim.new(0, 24),
				},

				peek(pelletProps.Text) and New "TextLabel" {
					Size = UDim2.fromScale(0.5, 1),
					BackgroundTransparency = 1,

					Text = pelletProps.Text,
					TextColor3 = InterfaceConstants.colors.menuText,
					FontFace = InterfaceConstants.fonts.body.font,
					TextSize = InterfaceConstants.fonts.body.size,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Center,
					TextWrapped = true,

					[Children] = {
						New "UIPadding" {
							PaddingLeft = UDim.new(0, 16),
						},
					},
				},

				peek(pelletProps.ImageId) and New "ImageLabel" {
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.fromScale(0, 0.5) + UDim2.fromOffset(16, 0),
					Size = Computed(function(use)
						local imageSize = use(pelletProps.ImageSize) or UDim2.fromOffset(32, 32)

						return imageSize
					end),
					BackgroundTransparency = 1,
					ImageColor3 = Computed(
						function(use) return use(pelletProps.ImageColor3) or InterfaceConstants.colors.menuText end
					),
					Image = pelletProps.ImageId,
				},

				inputType == toggleType and bubbleToggle {
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.fromScale(1, 0.5) + UDim2.fromOffset(-16, 0),
					State = state,
					OnClick = listener,
					Disabled = pelletProps.Disabled,
				} or inputType == sliderType and bubbleSlider {
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.fromScale(1, 0.5) + UDim2.fromOffset(-16, 0),
					SizeX = UDim.new(0.5, -16),
					ProgressAlpha = state,
					InputProgressChanged = listener,
					Disabled = pelletProps.Disabled,
				} or nil,
			},
		}

		return frame
	end

	local pellets = {
		pellet {
			Text = "Find Open World",
			InputType = toggleType,
			State = Value(false),
			listener = function() print "hey i exist" end,
		},

		pellet {
			Text = "Music",
			InputType = sliderType,
			State = Value(0.5),
			listener = function() end,
		},

        pellet {
			Text = "Sound Effects",
			InputType = sliderType,
			State = Value(1),
			listener = function() end,
		},
	}

	local frame = outlinedMenu {
		Name = "SettingsMenu",
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		Size = props.Size,
		ZIndex = props.ZIndex,

		OutlineColor = InterfaceConstants.colors.settingsBlue,

		TitleText = "Settings",
		RemoveExitButton = true,

		onExitButtonClicked = props.onExitRequest,

		InnerChildren = {
			New "UIPadding" {
				PaddingLeft = UDim.new(0, 4),
				PaddingRight = UDim.new(0, 4),
				PaddingTop = UDim.new(0, 32),
				PaddingBottom = UDim.new(0, 8),
			},

			bubbleButton {
				Name = "ExitButton",
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.fromScale(0.5, 1),
				Text = "EXIT",

				OnDown = function() props.onExitRequest() end,
			},

			New "Frame" {
				Name = "ScrollingFrameContainer",
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromScale(0.5, 0),
				Size = UDim2.new(1, 0, 1, -InterfaceConstants.sizes.bubbleButtonSizeY - 8),
				BackgroundTransparency = 1,

				[Children] = {
					roundCornerMask {
						CornerRadius = 24,
						Color = InterfaceConstants.colors.menuBackground,
						ScrollbarOffset = 12,
						Disabled = Computed(function(use) return not use(isScrollingMode) end),
					},

					New "ScrollingFrame" {
						Name = "ScrollingFrame",
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 1,
						CanvasSize = UDim2.new(0, 0, 0, 0),
						AutomaticCanvasSize = Enum.AutomaticSize.Y,
						TopImage = "rbxassetid://158362307",
						MidImage = "rbxassetid://158362264",
						BottomImage = "rbxassetid://158362221",
						ScrollBarThickness = 8,
						ScrollBarImageColor3 = Color3.new(0, 0, 0),
                        ScrollBarImageTransparency = 0.9,
						VerticalScrollBarInset = Enum.ScrollBarInset.None,

						[Out "AbsoluteWindowSize"] = absoluteWindowSize,
						[Out "AbsoluteCanvasSize"] = absoluteCanvasSize,

						[Children] = {
							New "UIListLayout" {
								SortOrder = Enum.SortOrder.LayoutOrder,
								Padding = UDim.new(0, 4),
							},

							pellets,
						},
					},
				},
			},
		},
	}

	return frame
end

return Component
