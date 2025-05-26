local ReplicatedFirst = game:GetService "ReplicatedFirst"

local Fusion = require(ReplicatedFirst:WaitForChild("Vendor"):WaitForChild "Fusion")

local Children = Fusion.Children

type UsedAs<T> = Fusion.UsedAs<T>

export type Props = {
	Name: string?,
	Progress: UsedAs<number>,
	Size: UsedAs<UDim2>?,
	Position: UsedAs<UDim2>?,
	AnchorPoint: UsedAs<Vector2>?,
	Rotation: UsedAs<number>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,

	IsPie: boolean?, -- if true, the radial progress will be a pie instead of a ring
	ProgressThickness: UsedAs<number>?,
	ProgressImageId: UsedAs<number>?,
	ProgressColor: UsedAs<Color3>?,
	ProgressTransparency: UsedAs<number>?,
	Flip: UsedAs<boolean>?, -- counter‑clockwise fill

	BackgroundColor: UsedAs<Color3>?,
	BackgroundTransparency: UsedAs<number>?,

	CompletedProgressColor: UsedAs<Color3>?,
	CompletedProgressTransparency: UsedAs<number>?,
	CompletedBackgroundColor: UsedAs<Color3>?,
	CompletedBackgroundTransparency: UsedAs<number>?,

	-- PRIVATE (injected later)
	__deg: Fusion.StateObject<number>?,
}

-- Default sprite (a simple white ring mask)
local DEFAULT_ID = 2763450503

local function RadialProgress(scope: Fusion.Scope, props: Props)
	local isPie = props.IsPie or nil
	local thickness = props.ProgressThickness

	assert(props.Progress, "RadialProgress: Progress is required")

	local percentNumber = scope:Computed(function(use) return math.clamp(use(props.Progress) * 3.6, 0, 360) end)

	local halfTransparency = scope:Computed(function(use)
		local progress = use(props.Progress) or 0

		local progressTransparency = use(props.ProgressTransparency) or 0
		local backgroundTransparency = use(props.BackgroundTransparency) or 0.75

		if progress >= 1 then
			progressTransparency = use(props.CompletedProgressTransparency) or progressTransparency
			backgroundTransparency = use(props.CompletedBackgroundTransparency) or backgroundTransparency
		end

		return NumberSequence.new {
			NumberSequenceKeypoint.new(0, progressTransparency),
			NumberSequenceKeypoint.new(0.5, progressTransparency),
			NumberSequenceKeypoint.new(0.501, backgroundTransparency),
			NumberSequenceKeypoint.new(1, backgroundTransparency),
		}
	end)

	local halfColor = scope:Computed(function(use)
		local progressColor = use(props.ProgressColor) or Color3.fromRGB(255, 255, 255)
		local backgroundColor = use(props.BackgroundColor) or Color3.fromRGB(0, 0, 0)

		if use(props.Progress) >= 1 then
			progressColor = use(props.CompletedProgressColor) or progressColor
			backgroundColor = use(props.CompletedBackgroundColor) or props.BackgroundColor or progressColor
		end

		return ColorSequence.new {
			ColorSequenceKeypoint.new(0, progressColor),
			ColorSequenceKeypoint.new(0.5, progressColor),
			ColorSequenceKeypoint.new(0.501, backgroundColor),
			ColorSequenceKeypoint.new(1, backgroundColor),
		}
	end)

	local gradientRotationLeft = scope:Computed(function(use)
		if not use(props.Flip) then
			return math.clamp(use(percentNumber), 180, 360)
		else
			return 180 - math.clamp(use(percentNumber), 0, 180)
		end
	end)
	local gradientRotationRight = scope:Computed(function(use)
		if not use(props.Flip) then
			return math.clamp(use(percentNumber), 0, 179.99)
		else
			return math.clamp((180 - math.clamp(use(percentNumber), 180, 360)), 0, 179.99)
		end
	end)

	return scope:New "Frame" {
		Name = props.Name or "RadialProgress",
		AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = props.Position or UDim2.fromScale(0.5, 0.5),
		Rotation = props.Rotation or 0,
		Size = props.Size or UDim2.fromScale(1, 1),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		ZIndex = props.ZIndex or 1,
		Visible = props.Visible or true,

		[Children] = {
			scope:New (if props.Rotation then "CanvasGroup" else "Frame") {
				Name = "Left",
				BackgroundTransparency = 1,
				ClipsDescendants = true,
				Size = UDim2.fromScale(0.5, 1),

				[Children] = {
					scope:New(if isPie or thickness then "Frame" else "ImageLabel") {
						BackgroundTransparency = if isPie then 0 else 1,
						Image = if isPie or thickness
							then nil
							else "rbxassetid://" .. tostring(props.ProgressImageId or DEFAULT_ID),
						Size = UDim2.fromScale(2, 1),

						[Children] = {
							if not thickness
								then scope:New "UIGradient" {
									Transparency = halfTransparency,
									Color = halfColor,
									Rotation = gradientRotationLeft,
								}
								else nil,

							if isPie
								then scope:New "UICorner" {
									CornerRadius = UDim.new(1, 0),
								}
								else nil,

							if thickness
								then scope:New "Frame" {
									AnchorPoint = Vector2.new(0.5, 0.5),
									Position = UDim2.fromScale(0.5, 0.5),
									Size = scope:Computed(function(use)
										local thickness = use(thickness)

										return UDim2.fromScale(1, 1) - UDim2.fromOffset(thickness * 2, thickness * 2)
									end),
									BackgroundTransparency = 1,

									[Children] = {
										scope:New "UIStroke" {
											Thickness = thickness,
											Color = Color3.new(1, 1, 1),
											ApplyStrokeMode = Enum.ApplyStrokeMode.Border,

											[Children] = {
												scope:New "UIGradient" {
													Transparency = halfTransparency,
													Color = halfColor,
													Rotation = gradientRotationLeft,
												},
											},
										},

										scope:New "UICorner" {
											CornerRadius = UDim.new(1, 0),
										},
									},
								}
								else nil,
						},
					},
				},
			},

			scope:New (if props.Rotation then "CanvasGroup" else "Frame") {
				Name = "Right",
				AnchorPoint = Vector2.new(1, 0),
				BackgroundTransparency = 1,
				ClipsDescendants = true,
				Position = UDim2.fromScale(1, 0),
				Size = UDim2.fromScale(0.5, 1),

				[Children] = {
					scope:New(if isPie or thickness then "Frame" else "ImageLabel") {
						BackgroundTransparency = if isPie then 0 else 1,
						Image = if isPie or thickness
							then nil
							else "rbxassetid://" .. tostring(props.ProgressImageId or DEFAULT_ID),
						Position = UDim2.fromScale(-1, 0),
						Size = UDim2.fromScale(2, 1),

						[Children] = {
							if not thickness
								then scope:New "UIGradient" {
									Transparency = halfTransparency,
									Color = halfColor,
									Rotation = gradientRotationRight,
								}
								else nil,

							if isPie
								then scope:New "UICorner" {
									CornerRadius = UDim.new(1, 0),
								}
								else nil,

							if thickness
								then scope:New "Frame" {
									AnchorPoint = Vector2.new(0.5, 0.5),
									Position = UDim2.fromScale(0.5, 0.5),
									Size = scope:Computed(function(use)
										local thickness = use(thickness)

										return UDim2.fromScale(1, 1) - UDim2.fromOffset(thickness * 2, thickness * 2)
									end),
									BackgroundTransparency = 1,

									[Children] = {
										scope:New "UIStroke" {
											Thickness = thickness,
											Color = Color3.new(1, 1, 1),
											ApplyStrokeMode = Enum.ApplyStrokeMode.Border,

											[Children] = {
												scope:New "UIGradient" {
													Transparency = halfTransparency,
													Color = halfColor,
													Rotation = gradientRotationRight,
												},
											},
										},

										scope:New "UICorner" {
											CornerRadius = UDim.new(1, 0),
										},
									},
								}
								else nil,
						},
					},
				},
			},
		},
	}
end

return RadialProgress
