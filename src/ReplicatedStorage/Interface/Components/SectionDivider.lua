--#region Imports
local ReplicatedFirst = game:GetService "ReplicatedFirst"

local replicatedFirstVendor = ReplicatedFirst:WaitForChild "Vendor"
local replicatedFirstShared = ReplicatedFirst:WaitForChild "Shared"

local InterfaceConstants = require(replicatedFirstShared:WaitForChild("Configuration"):WaitForChild "InterfaceConstants")

-- Optional: Remove imports that you don't need
local Fusion = require(replicatedFirstVendor:WaitForChild "Fusion")
local New = Fusion.New
local Children = Fusion.Children
local Computed = Fusion.Computed

type CanBeState<T> = Fusion.CanBeState<T>
-- #endregion

export type Props = {
	-- Default props
	LayoutOrder: CanBeState<number>?,
	Position: CanBeState<UDim2>?,
	AnchorPoint: CanBeState<Vector2>?,
	SizeX: CanBeState<UDim>?,
	ZIndex: CanBeState<number>?,

    -- Custom props
    Text: CanBeState<string>?,
    TextColor3: CanBeState<Color3>? -- Can be left alone to use the default menu text color
}

--[[
	This component creates a section divider than can be used to separate sections of a UI.
]]
local function Component(props: Props)
	local frame = New "Frame" {
		Name = "SectionDivider",
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.9,
		AnchorPoint = props.AnchorPoint or Vector2.new(0, 0.5),
		Position = props.Position,
		Size = Computed(function(use)
			local sizeX = use(props.SizeX)
			return UDim2.new(sizeX or UDim.new(1, 0), UDim.new(0, 2))
		end),
		ZIndex = props.ZIndex,
		LayoutOrder = props.LayoutOrder,

		[Children] = {
			New "TextLabel" {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				BackgroundColor3 = InterfaceConstants.colors.menuBackground,
				Text = props.Text or "New Section",
				TextColor3 = props.TextColor3 or InterfaceConstants.colors.menuText,
				TextSize = InterfaceConstants.fonts.header.size,
				FontFace = InterfaceConstants.fonts.header.font,
                AutomaticSize = Enum.AutomaticSize.X,
				Size = UDim2.new(0, 0, 0, 20),
				[Children] = {
					New "UIPadding" {
						PaddingLeft = UDim.new(0, 8),
						PaddingRight = UDim.new(0, 8),
					},
				},
			},
		},
	}

	return frame
end

return Component
