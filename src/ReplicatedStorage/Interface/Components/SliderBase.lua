local SELECT_INPUTS = {
	[Enum.UserInputType.MouseButton1] = true,
	[Enum.UserInputType.Touch] = true,
}

local MOVEMENT_INPUTS = {
	[Enum.UserInputType.MouseButton1] = true,
	[Enum.UserInputType.MouseMovement] = true,
	[Enum.UserInputType.Touch] = true,
}

--#region Imports
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local UserInputService = game:GetService "UserInputService"

local replicatedStorageShared = ReplicatedStorage:WaitForChild "Shared"
local replicatedFirstVendor = ReplicatedFirst:WaitForChild "Vendor"
local componentsFolder = replicatedStorageShared:WaitForChild("Interface"):WaitForChild "Components"

local buttonInput = require(componentsFolder:WaitForChild "ButtonInput")

-- Optional: Remove imports that you don't need
local Fusion = require(replicatedFirstVendor:WaitForChild "Fusion")
local New = Fusion.New
local Children = Fusion.Children
local Cleanup = Fusion.Cleanup
local Out = Fusion.Out
local Value = Fusion.Value
local Computed = Fusion.Computed
local peek = Fusion.peek

---@diagnostic disable-next-line: undefined-type oh my godddd
type CanBeState<T> = Fusion.CanBeState<T>
type Value<T> = Fusion.Value<T>
-- #endregion

export type Props = {
	-- Default props
	Name: CanBeState<string>?,
	LayoutOrder: CanBeState<number>?,
	Position: CanBeState<UDim2>?,
	AnchorPoint: CanBeState<Vector2>?,
	Size: CanBeState<UDim2>?,
	ZIndex: CanBeState<number>?,

	-- Custom props
	BackgroundInputShrink: CanBeState<Vector2>?, -- This size will be subtracted from the background input's size to create a smaller hitbox/draggable area.
	BackgroundBody: CanBeState<GuiObject>?, -- The actual design of the slider background
	SliderBody: CanBeState<GuiObject>?, -- The actual design of the slider
	SliderSize: CanBeState<UDim2>?, -- The size of the slider, which centers with the input body
	ProgressAlpha: CanBeState<number>?, -- Between 0 and 1, what the slider displays.
	Disabled: CanBeState<boolean>?, -- Whether or not the slider is disabled
	InputProgressChanged: (number) -> (), -- Inexpensive, unyielding callback that runs every frame and updates ProgressAlpha called when the slider is changed

	isHoveringBackground: Value<boolean>?,
	isHoveringSlider: Value<boolean>?,
	isHeldDownBackground: Value<boolean>?,
	isHeldDownSlider: Value<boolean>?,
	draggingMode: Value<("Background" | "Slider" | nil)>?,
}

--[[
	This component creates an unstyled slider frame
]]
local function Component(props: Props)
	local mousePosition: Vector2? = nil -- Mouse position in screen space
	local selected: Value<("Background" | "Slider" | nil)> = props.draggingMode or Value(nil) -- Which part of the slider is selected
	local sliderInputOffset: Vector2? -- Only relevant when selected == "Slider"

	local sliderAbsolutePosition = Value(Vector2.new(0, 0))
	local sliderAbsoluteSize = Value(Vector2.new(0, 0))

	local backgroundAbsolutePosition = Value(Vector2.new(0, 0))
	local backgroundAbsoluteSize = Value(Vector2.new(0, 0))
	local backgroundAbsoluteSizeComputed = Computed(
		function(use) return use(backgroundAbsoluteSize) - (use(props.BackgroundInputShrink) or Vector2.new(0, 0)) end
	)
	local backgroundAbsolutePositionComputed = Computed(
		function(use)
			return use(backgroundAbsolutePosition) + ((use(props.BackgroundInputShrink) or Vector2.new(0, 0)) / 2)
		end
	)

	local function updateProgress(input: InputObject)
		mousePosition = Vector2.new(input.Position.X, input.Position.Y)

		if MOVEMENT_INPUTS[input.UserInputType] and peek(selected) and not peek(props.Disabled) then
			local backgroundPosition = peek(backgroundAbsolutePositionComputed)
			local backgroundSize = peek(backgroundAbsoluteSizeComputed)

			local offset = if peek(selected) == "Slider"
				then (sliderInputOffset + peek(sliderAbsoluteSize) / 2)
				else Vector2.new(0, 0)

			local relativePosition = (mousePosition + offset - backgroundPosition) / backgroundSize
			local clampedRelativePosition =
				Vector2.new(math.clamp(relativePosition.X, 0, 1), math.clamp(relativePosition.Y, 0, 1))

			-- Update the slider position
			props.InputProgressChanged(math.clamp(clampedRelativePosition.X, 0, 1))
		end
	end

	local inputChangedConnection = UserInputService.InputChanged:Connect(updateProgress)

	local inputEndedConnection = UserInputService.InputEnded:Connect(function(input)
		if SELECT_INPUTS[input.UserInputType] then
			selected:set(nil)
			sliderInputOffset = nil
		end
	end)

	local frame = New "Frame" {
		Size = props.Size,
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		LayoutOrder = props.LayoutOrder,
		ZIndex = props.ZIndex,
		BackgroundTransparency = 1,
		Name = props.Name or "SliderBase",

		[Cleanup] = {
			inputChangedConnection,
			inputEndedConnection,
		},

		[Out "AbsolutePosition"] = backgroundAbsolutePosition,
		[Out "AbsoluteSize"] = backgroundAbsoluteSize,

		[Children] = {
			buttonInput {
				Name = "BackgroundInput",
				Size = Computed(function(use)
					local inputShrinkVector2 = use(props.BackgroundInputShrink) or Vector2.new(0, 0)
					return UDim2.fromScale(1, 1) - UDim2.fromOffset(inputShrinkVector2.X, inputShrinkVector2.Y)
				end),
				ZIndex = 10000,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),

				Disabled = props.Disabled,

				InputBegan = function(input: InputObject)
					if SELECT_INPUTS[input.UserInputType] then
						selected:set("Background")
						updateProgress(input)
					end
				end,

				isHeldDown = props.isHeldDownBackground,
				isHovering = props.isHoveringBackground,
			},

			props.BackgroundBody,

			New "Frame" {
				Name = "SliderContainer",
				BackgroundTransparency = 1,
				Size = Computed(function(use)
					local BackgroundInputShrink = use(props.BackgroundInputShrink) or Vector2.new(0, 0)
					return UDim2.fromScale(1, 1) - UDim2.fromOffset(BackgroundInputShrink.X, BackgroundInputShrink.Y)
				end),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				ZIndex = 20000,

				[Children] = {
					New "Frame" {
						Name = "SliderFrame",
						BackgroundTransparency = 1,
						Size = props.SliderSize or UDim2.fromOffset(20, 20),
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = Computed(
							function(use) return UDim2.fromScale(use(props.ProgressAlpha) or 0, 0.5) end
						),

						[Out "AbsolutePosition"] = sliderAbsolutePosition,
						[Out "AbsoluteSize"] = sliderAbsoluteSize,

						[Children] = {
							buttonInput {
								Name = "SliderInput",
								Size = UDim2.fromScale(1, 1),
								ZIndex = 10000,

								Disabled = props.Disabled,

								InputBegan = function(input: InputObject)
									if SELECT_INPUTS[input.UserInputType] then
										selected:set("Slider")
										sliderInputOffset = peek(sliderAbsolutePosition)
											- Vector2.new(math.round(input.Position.X), math.round(input.Position.Y))
										updateProgress(input)
									end
								end,

								isHeldDown = props.isHeldDownSlider,
								isHovering = props.isHoveringSlider,
							},

							props.SliderBody,
						},
					},
				},
			},
		},
	}

	return frame
end

return Component
