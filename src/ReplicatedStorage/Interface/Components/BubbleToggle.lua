local SIZE_Y = 28

--#region Imports
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local replicatedStorageShared = ReplicatedStorage:WaitForChild "Shared"
local replicatedFirstVendor = ReplicatedFirst:WaitForChild "Vendor"
local replicatedFirstShared = ReplicatedFirst:WaitForChild "Shared"
local componentsFolder = replicatedStorageShared:WaitForChild("Interface"):WaitForChild "Components"
local configurationFolder = replicatedFirstShared:WaitForChild "Configuration"

local InterfaceConstants = require(configurationFolder:WaitForChild "InterfaceConstants")
local buttonInput = require(componentsFolder:WaitForChild "ButtonInput")

-- Optional: Remove imports that you don't need
local Fusion = require(replicatedFirstVendor:WaitForChild "Fusion")
local New = Fusion.New
local Children = Fusion.Children
local Value = Fusion.Value
local Computed = Fusion.Computed
local Spring = Fusion.Spring

type CanBeState<T> = Fusion.CanBeState<T>
-- #endregion

export type Props = {
	-- Default props
	Name: CanBeState<string>?,
	LayoutOrder: CanBeState<number>?,
	Position: CanBeState<UDim2>?,
	AnchorPoint: CanBeState<Vector2>?,
	ZIndex: CanBeState<number>?,

	-- Custom props
	Disabled: CanBeState<boolean>?,
	OnClick: (() -> ())?, -- Edits the state of the button
	State: CanBeState<boolean>?, -- true = on, false = off

	PrimaryColor: CanBeState<Color3>?,
	SecondaryColor: CanBeState<Color3>?,
}

--[[
	This component creates a stylized bubble toggle button.

	Example usage:
	```lua

	```
]]
local function Component(props: Props)
	local state = props.State or Value(false)
    local isHovering = Value(false)

	local sizeX = SIZE_Y * 2

	local springSpeed = InterfaceConstants.animation.bubbleButtonColorSpring.speed
	local springDamping = InterfaceConstants.animation.bubbleButtonColorSpring.damping

    local function brighten(color: Color3)
		local h, s, v = color:ToHSV()
		return Color3.fromHSV(h, s, math.min(v + 40 / 255, 1))
	end

	local function desaturate(color: Color3)
		local h, s, v = color:ToHSV()
		return Color3.fromHSV(h, math.max(s - 0.2, 0), v)
	end

	local primaryColor = Spring(
		Computed(function(use)
			local color = use(props.PrimaryColor or InterfaceConstants.colors.buttonBluePrimary)

			if use(props.Disabled) then
				return desaturate(color)
			else
				return if use(isHovering) then brighten(color) else color
			end
		end),
		springSpeed,
		springDamping
	)

	local secondaryColor = Spring(
		Computed(function(use)
			local color = use(props.SecondaryColor or InterfaceConstants.colors.buttonBlueSecondary)

			if use(props.Disabled) then
				return desaturate(color)
			else
				return if use(isHovering) then brighten(color) else color
			end
		end),
		springSpeed,
		springDamping
	)

	local frame = New "Frame" {
		Name = props.Name or "BubbleToggle",
		LayoutOrder = props.LayoutOrder,
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		ZIndex = props.ZIndex,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(sizeX, SIZE_Y),

		[Children] = {
			New "Frame" {
				Name = "Background",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				BackgroundColor3 = secondaryColor,
				Size = UDim2.fromScale(1, 1),

				[Children] = {
					New "UIPadding" {
						PaddingLeft = UDim.new(0, 4),
						PaddingRight = UDim.new(0, 4),
					},

					New "UICorner" {
						CornerRadius = UDim.new(0, InterfaceConstants.sizes.bubbleButtonRoundness),
					},

					New "Frame" {
						Name = "Bubble",
						AnchorPoint = Spring(
							Computed(function(use) return use(state) and Vector2.new(1, 0.5) or Vector2.new(0, 0.5) end),
							springSpeed,
							springDamping
						),
						Position = Spring(
							Computed(
								function(use) return use(state) and UDim2.fromScale(1, 0.5) or UDim2.fromScale(0, 0.5) end
							),
							springSpeed,
							springDamping
						),
						BackgroundColor3 = primaryColor,
						Size = UDim2.fromOffset(SIZE_Y - 8, SIZE_Y - 8),

						[Children] = {
							New "UICorner" {
								CornerRadius = UDim.new(0, InterfaceConstants.sizes.bubbleButtonRoundness - 4),
							},
						},
					},
				},
			},

			buttonInput {
				ZIndex = 2,
				Size = UDim2.fromScale(1, 1),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				CornerRadius = UDim.new(0, InterfaceConstants.sizes.bubbleButtonRoundness),

				OnDown = props.OnClick,
				Disabled = props.Disabled,

                isHovering = isHovering,
			},
		},
	}

	return frame
end

return Component
