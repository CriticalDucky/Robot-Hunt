local SPRING_SPEED = 60

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
	Size: UsedAs<UDim2>?,
	ZIndex: UsedAs<number>?,

	-- Custom props
	Image: UsedAs<string>,
	OutlineImage: UsedAs<string>,
	InputExtraPx: UsedAs<number>?, -- Extra pixels to add to the input area from the center
	HoverScaleIncrease: UsedAs<number>?, -- How much to increase the size of the image when hovering (default 1.2)

	ImageColor: UsedAs<Color3>?,
	OutlineColor: UsedAs<Color3>?,
	OutlineHoveColor: UsedAs<Color3>?,
	OutlinePressColor: UsedAs<Color3>?,

	OnClick: UsedAs<() -> ()>?,
}

--[[
	This component creates a floating icon button, similar to the ones in Animal Jam at the top of the screen.
    The user of this component provides an image and an outline image that will highlight on hover/click.
    Both images need to be the same size (so there will need to be some white space around the image).
    The outline should be a solid white color, gone though pixelfix.
]]
local function Component(scope: Fusion.Scope, props: Props)
	local isHovering = scope:Value(false)
	local isHeldDown = scope:Value(false)

	local frame = scope:New "Frame" {
		Name = props.Name,
		LayoutOrder = props.LayoutOrder,
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		Size = props.Size,
		ZIndex = props.ZIndex,

		BackgroundTransparency = 1,

		[Children] = {
			-- The outline image
			scope:New "ImageLabel" {
				Name = "Outline",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = scope:Spring(
					scope:Computed(function(use)
						local scale = 1

						if use(isHovering) then scale = (props.HoverScaleIncrease or 1.2) end

						return UDim2.fromScale(scale, scale)
					end),
					SPRING_SPEED,
					1
				),
				BackgroundTransparency = 1,
				Image = props.OutlineImage,
				ImageColor3 = scope:Spring(
					scope:Computed(function(use)
						local constantColors = InterfaceConstants.colors

						local color = props.OutlineColor or constantColors.floatingIconButtonNormal

						if use(isHovering) then
							color = props.OutlineHoveColor or constantColors.floatingIconButtonHover
						end

						if use(isHeldDown) then
							color = props.OutlinePressColor or constantColors.floatingIconButtonPress
						end

						return color
					end),
					SPRING_SPEED,
					1
				),

				-- the main image
				[Children] = scope:New "ImageLabel" {
					Name = "Image",
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Image = props.Image,
					ImageTransparency = 0,
					ZIndex = 1,
				},
			},

			-- The button input
			buttonInput(scope, {
				Name = "ButtonInput",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = scope:Computed(function(use)
					local computedPx = 2 * (use(props.InputExtraPx) or 0)

					return UDim2.new(1, computedPx, 1, computedPx)
				end),
				ZIndex = 300,

				isHovering = isHovering,
				isHeldDown = isHeldDown,

				OnClick = props.OnClick,
			}),
		},
	}

	return frame
end

return Component
