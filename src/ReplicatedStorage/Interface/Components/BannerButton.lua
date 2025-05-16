local SPRING_SPEED = 50

--#region Imports
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local replicatedFirstVendor = ReplicatedFirst:WaitForChild "Vendor"
local componentsFolder = ReplicatedStorage:WaitForChild("Interface"):WaitForChild "Components"

local buttonInput = require(componentsFolder:WaitForChild "ButtonInput")

-- Optional: Remove imports that you don't need
local Fusion = require(replicatedFirstVendor:WaitForChild "Fusion")
local Children = Fusion.Children

type UsedAs<T> = Fusion.UsedAs<T>
--#endregion

export type Props = {
	-- Default props
	Name: UsedAs<string>?,
	LayoutOrder: UsedAs<number>?,
	Position: UsedAs<UDim2>?,
	AnchorPoint: UsedAs<Vector2>?,
	Size: UsedAs<UDim2>?, -- If you want to preserve the aspect ratio of the image, calculate the size as size + BorderSizePixels * 2
	ZIndex: UsedAs<number>?,

	-- Custom props
	RoundnessPixels: UsedAs<number>?, -- Defaults to 24
	BorderSizePixels: UsedAs<number>?, -- Defaults to 4
	BorderColor: UsedAs<Color3>?, -- Defaults to black
	BottomExtraPx: UsedAs<number>?, -- Defaults to 0, adds extra px to the bottom of the button
	BorderHoverColor: UsedAs<Color3>?, -- Defaults to brightened border color
	BorderClickColor: UsedAs<Color3>?, -- Hover color will be used if not provided
	BorderDisabledColor: UsedAs<Color3>?, -- Defaults to slightly darkened border color

	DarkenOnHover: UsedAs<boolean>?, -- Defaults to false
	Darkness: UsedAs<number>?, -- 0 to 1, defaults to 0.1. Decides how dark the button will be when hovered (transparency = 1 - darkness)

	ZoomOnHover: UsedAs<boolean>?, -- Defaults to false
	ZoomScale: UsedAs<number>?, -- Defaults to 1.05

	InputExtraPx: UsedAs<number>?, -- Defaults to 0, adds extra px to the input area

	Children: UsedAs<{}>?, -- Members of this table will be added as children to the canvas group

	Disabled: UsedAs<boolean>?, -- Defaults to false

	Image: UsedAs<string>?, -- Defaults to nil
	ResampleMode: UsedAs<Enum.ResamplerMode>?, -- Defaults to Enum.ResamplerMode.Default

	OnClick: (() -> ())?,
	OnDown: (() -> ())?,
	InputBegan: ((InputObject) -> ())?,

	-- Edited states
	isHovering: UsedAs<boolean>?,
	isHeldDown: UsedAs<boolean>?,
}

--[[
	This component creates an solid image button that can:
	- Be rounded
	- Have a border
	- Have a darken effect on hover
	- Lighten border on hover
]]
local function Component(scope: Fusion.Scope, props: Props)
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
	local borderHoverColor = props.BorderHoverColor
		or scope:Computed(function(use) return brighten(use(borderColor)) end)
	local borderClickColor = props.BorderClickColor or borderHoverColor
	local borderSizePixels = props.BorderSizePixels or 4
	local borderDisabledColor = props.BorderDisabledColor
		or scope:Computed(function(use) return darken(use(borderColor)) end)

	local darkenOnHover = props.DarkenOnHover or false
	local darkness = props.Darkness or 0.1

	local zoomOnHover = props.ZoomOnHover or false
	local zoomScale = props.ZoomScale or 1.05

	local inputExtraPx = props.InputExtraPx or 0

	local isHovering = props.isHovering or scope:Value(false)
	local isHeldDown = props.isHeldDown or scope:Value(false)

	local frame = scope:New "Frame" {
		Name = props.Name or "BannerButton",
		LayoutOrder = props.LayoutOrder,
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		Size = props.Size,
		ZIndex = props.ZIndex,

		BackgroundColor3 = scope:Spring(
			scope:Computed(function(use)
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
			scope:New "UICorner" {
				CornerRadius = scope:Computed(function(use) return UDim.new(0, use(roundnessPixels)) end),
			},

			buttonInput(scope, {
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.new(1, inputExtraPx * 2, 1, inputExtraPx * 2),

				Disabled = props.Disabled,
				OnClick = props.OnClick,
				OnDown = props.OnDown,
				InputBegan = props.InputBegan,

				isHeldDown = isHeldDown,
				isHovering = isHovering,
			}),

			scope:New "CanvasGroup" {
				Name = "ImageContainer",
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromScale(0.5, 0) + UDim2.fromOffset(0, borderSizePixels),
				Size = UDim2.new(1, -borderSizePixels * 2, 1, -borderSizePixels * 2 - inputExtraPx),
				ZIndex = -1,

				BackgroundTransparency = 1,

				[Children] = {
					scope:New "UICorner" {
						CornerRadius = scope:Computed(
							function(use) return UDim.new(0, use(roundnessPixels) - use(borderSizePixels)) end
						),
					},

					scope:New "UIPadding" {
						PaddingBottom = UDim.new(0, -1), -- Hack to fix the image being cut off (stupid roblox)
					},

					scope:New "ImageLabel" {
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
						Size = scope:Spring(
							scope:Computed(function(use)
								local scale = 1

								if use(isHovering) and use(zoomOnHover) and not use(props.Disabled) then
									scale = use(zoomScale)
								end

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

					scope:New "Frame" {
						Name = "Darken",
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
						Size = UDim2.new(1, 0, 1, 0),
						BackgroundColor3 = Color3.new(0, 0, 0),
						BackgroundTransparency = scope:Spring(
							scope:Computed(function(use)
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
