local DEFAULT_SIZE_X = 0
local OUTER_ROUNDNESS = 24

--#region Imports
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local replicatedStorageShared = ReplicatedStorage:WaitForChild "Shared"
local replicatedFirstVendor = ReplicatedFirst:WaitForChild "Vendor"
local replicatedFirstShared = ReplicatedFirst:WaitForChild "Shared"
local componentsFolder = replicatedStorageShared:WaitForChild("Interface"):WaitForChild "Components"
local configurationFolder = replicatedFirstShared:WaitForChild "Configuration"

local buttonInput = require(componentsFolder:WaitForChild "ButtonInput")
local InterfaceConstants = require(configurationFolder:WaitForChild "InterfaceConstants")

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
	Size: CanBeState<UDim2>?, -- Consider using SizeX, but can be used to override SizeY and SizeX if you want
	ZIndex: CanBeState<number>?,

	-- Custom props
	Text: CanBeState<string>?,
	Icon: CanBeState<string>?, -- content id
	IconSize: CanBeState<number>?, -- offset size
	PrimaryColor: CanBeState<Color3>?, -- background color
	SecondaryColor: CanBeState<Color3>?, -- outlines, text, icon color
	SizeX: CanBeState<number>?, -- use this so that the Y size remains constant, but if you want to override it, you can use Size
	Square: CanBeState<boolean>?, -- if true, the button will be square

	OnClick: (() -> ())?,
	OnDown: (() -> ())?,
	Disabled: CanBeState<boolean>?,
}

--[[
	This component creates a stylized bubble button that can either hold text or an icon.
    It plays a sound when clicked and hovered over.
]]
local function Component(props: Props)
	local isImageMode = props.Icon ~= nil

	local textSize = InterfaceConstants.fonts.button.size
	local textFont = InterfaceConstants.fonts.button.font

	local springSpeed = InterfaceConstants.animation.bubbleButtonColorSpring.speed
	local springDamping = InterfaceConstants.animation.bubbleButtonColorSpring.damping

	local defaultIconSize = InterfaceConstants.sizes.bubbleButtonIconSize
	local sizeY = InterfaceConstants.sizes.bubbleButtonSizeY

	local isHovering = Value(false)
	local isHeldDown = Value(false)

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
		Name = props.Name or "BubbleButton",
		LayoutOrder = props.LayoutOrder,
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		Size = props.Size or UDim2.new(UDim.new(0, props.SizeX or if props.Square then sizeY else DEFAULT_SIZE_X), UDim.new(0, sizeY)),
		AutomaticSize = if not isImageMode then Enum.AutomaticSize.X else nil,
		ZIndex = props.ZIndex,

		BackgroundColor3 = secondaryColor,

		[Children] = {
			New "UICorner" {
				CornerRadius = UDim.new(0, OUTER_ROUNDNESS),
			},

			New "UIPadding" {
				PaddingLeft = UDim.new(0, 4),
				PaddingRight = UDim.new(0, 4),
				PaddingTop = UDim.new(0, 4),
				PaddingBottom = UDim.new(0, 4),
			},

			New "TextLabel" {
				Name = props.Name or "Text",
				Size = UDim2.fromScale(isImageMode and 1 or 0, 1),
				AutomaticSize = if not isImageMode then Enum.AutomaticSize.X else nil,

				BackgroundColor3 = primaryColor,
				Text = props.Text or "",
				TextColor3 = secondaryColor,
				TextSize = textSize,
				FontFace = textFont,

				[Children] = {
					New "UICorner" {
						CornerRadius = UDim.new(0, OUTER_ROUNDNESS - 4),
					},

					New "UIPadding" {
						PaddingLeft = UDim.new(0, 10),
						PaddingRight = UDim.new(0, 10),
					},

					Computed(function(use)
						if not use(props.Text) then
							return New "ImageLabel" {
								Size = UDim2.fromOffset(
									props.IconSize or defaultIconSize,
									props.IconSize or defaultIconSize
								),
								Position = UDim2.fromScale(0.5, 0.5),
								AnchorPoint = Vector2.new(0.5, 0.5),
								BackgroundTransparency = 1,
								Image = props.Icon,
								ImageColor3 = secondaryColor,
								ZIndex = -1,
							}
						end

						return
					end, Fusion.cleanup),
				},
			},

			buttonInput {
				Size = UDim2.new(1, 8, 1, 8),
				OnClick = props.OnClick,
				OnDown = props.OnDown,
				Disabled = props.Disabled,
				ZIndex = 10,
				AnchorPoint = Vector2.new(0, 0),
				Position = UDim2.fromOffset(-4, -4),
				CornerRadius = UDim.new(0, OUTER_ROUNDNESS),

				isHeldDown = isHeldDown,
				isHovering = isHovering,
			},
		},
	}

	return frame
end

return Component
