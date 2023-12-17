local SPRING_SPEED = 50

--#region Imports
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local replicatedStorageShared = ReplicatedStorage:WaitForChild "Shared"
local replicatedFirstVendor = ReplicatedFirst:WaitForChild "Vendor"
local componentsFolder = replicatedStorageShared:WaitForChild("Interface"):WaitForChild "Components"

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
	Size: CanBeState<UDim2>?, -- If you want to preserve the aspect ratio of the image, calculate the size as size + BorderSizePixels * 2
	ZIndex: CanBeState<number>?,

	-- Custom props
	RoundnessPixels: CanBeState<number>?, -- Defaults to 24
	BorderSizePixels: CanBeState<number>?, -- Defaults to 4
	BorderColor: CanBeState<Color3>?, -- Defaults to black
	BottomExtraPx: CanBeState<number>?, -- Defaults to 0, adds extra px to the bottom of the button
	BorderHoverColor: CanBeState<Color3>?, -- Defaults to brightened border color
	BorderClickColor: CanBeState<Color3>?, -- Hover color will be used if not provided
	BorderDisabledColor: CanBeState<Color3>?, -- Defaults to slightly darkened border color

	DarkenOnHover: CanBeState<boolean>?, -- Defaults to false
	Darkness: CanBeState<number>?, -- 0 to 1, defaults to 0.1. Decides how dark the button will be when hovered (transparency = 1 - darkness)

	ZoomOnHover: CanBeState<boolean>?, -- Defaults to false
	ZoomScale: CanBeState<number>?, -- Defaults to 1.05

	InputExtraPx: CanBeState<number>?, -- Defaults to 0, adds extra px to the input area

	Children: CanBeState<{}>?, -- Members of this table will be added as children to the canvas group

	Disabled: CanBeState<boolean>?, -- Defaults to false

	Image: CanBeState<string>?, -- Defaults to nil
	ResampleMode: CanBeState<Enum.ResamplerMode>?, -- Defaults to Enum.ResamplerMode.Default

	OnClick: (() -> ())?,
	OnDown: (() -> ())?,
	InputBegan: ((InputObject) -> ())?,

	-- Edited states
	isHovering: CanBeState<boolean>?,
	isHeldDown: CanBeState<boolean>?,
}

--[[
	This component creates an solid image button that can:
	- Be rounded
	- Have a border
	- Have a darken effect on hover
	- Lighten border on hover
]]
local function Component(props: Props)
	local function brighten(color: Color3)
		local h, s, v = color:ToHSV()
		return Color3.fromHSV(h, s, math.min(v + 40 / 255, 1))
	end

	local function darken(color: Color3)
		local h, s, v = color:ToHSV()
		return Color3.fromHSV(h, s, math.max(v - 40 / 255, 0))
	end

	local roundnessPixels = props.RoundnessPixels or 24
	local borderColor = props.BorderColor or Color3.new(0, 0, 0)
	local borderHoverColor = props.BorderHoverColor or Computed(function(use)
		return brighten(use(borderColor))
	end)
	local borderClickColor = props.BorderClickColor or borderHoverColor
	local borderSizePixels = props.BorderSizePixels or 4
	local borderDisabledColor = props.BorderDisabledColor or Computed(function(use)
		return darken(use(borderColor))
	end)

	local darkenOnHover = props.DarkenOnHover or false
	local darkness = props.Darkness or 0.1

	local zoomOnHover = props.ZoomOnHover or false
	local zoomScale = props.ZoomScale or 1.05

	local inputExtraPx = props.InputExtraPx or 0

	local isHovering = props.isHovering or Value(false)
	local isHeldDown = props.isHeldDown or Value(false)

	local frame = New "Frame" {
		Name = props.Name or "BannerButton",
		LayoutOrder = props.LayoutOrder,
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		Size = props.Size,
		ZIndex = props.ZIndex,

		BackgroundColor3 = Spring(
			Computed(function(use)
				local color = borderColor

				if use(props.Disabled) then return use(borderDisabledColor) end

				if use(isHeldDown) then
					color = borderClickColor
				elseif use(isHovering) then
					color = borderHoverColor
				end

				return use(color)
			end),
			SPRING_SPEED,
			1
		),

		[Children] = {
			New "UICorner" {
				CornerRadius = Computed(function(use)
					return UDim.new(0, use(roundnessPixels))
				end),
			},

			buttonInput {
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.new(1, inputExtraPx * 2, 1, inputExtraPx * 2),

				Disabled = props.Disabled,
				OnClick = props.OnClick,
				OnDown = props.OnDown,
				InputBegan = props.InputBegan,

				isHeldDown = isHeldDown,
				isHovering = isHovering,
			},

			New "CanvasGroup" {
				Name = "ImageContainer",
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromScale(0.5, 0) + UDim2.fromOffset(0, borderSizePixels),
				Size = UDim2.new(1, -borderSizePixels * 2, 1, -borderSizePixels * 2 - inputExtraPx),
				ZIndex = -1,

				BackgroundTransparency = 1,

				[Children] = {
					New "UICorner" {
						CornerRadius = Computed(function(use)
							return UDim.new(0, use(roundnessPixels) - use(borderSizePixels))
						end)
					},

					New "UIPadding" {
						PaddingBottom = UDim.new(0, -1), -- Hack to fix the image being cut off (stupid roblox)
					},

					New "ImageLabel" {
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
						Size = Spring(
							Computed(function(use)
								local scale = 1

								if use(isHovering) and use(zoomOnHover) and not use(props.Disabled) then scale = use(zoomScale) end

								return UDim2.fromScale(scale, scale)
							end),
							SPRING_SPEED,
							1
						),
						BackgroundTransparency = 1,
						ZIndex = -100,

						Image = props.Image,
						ResampleMode = props.ResampleMode or Enum.ResamplerMode.Default,
						ScaleType = Enum.ScaleType.Crop,
					},

					New "Frame" {
						Name = "Darken",
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
						Size = UDim2.new(1, 0, 1, 0),
						BackgroundColor3 = Color3.new(0, 0, 0),
						BackgroundTransparency = Spring(
							Computed(function(use)
								local transparency = 1

								if use(props.Disabled) then return transparency end

								if use(isHovering) and use(darkenOnHover) then transparency = 1 - use(darkness) end

								return transparency
							end),
							SPRING_SPEED,
							1
						),
						ZIndex = -1,
					},

					props.Children,
				},
			},
		},
	}

	return frame
end

return Component
