--#region Imports
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local replicatedStorageShared = ReplicatedStorage:WaitForChild "Shared"
local replicatedFirstVendor = ReplicatedFirst:WaitForChild "Vendor"
local replicatedFirstShared = ReplicatedFirst:WaitForChild "Shared"
local componentsFolder = replicatedStorageShared:WaitForChild("Interface"):WaitForChild "Components"

local InterfaceConstants =
	require(replicatedFirstShared:WaitForChild("Configuration"):WaitForChild "InterfaceConstants")
local outlinedFrame = require(componentsFolder:WaitForChild "OutlinedFrame")
local bubbleText = require(componentsFolder:WaitForChild "BubbleText")
local exitButton = require(componentsFolder:WaitForChild "ExitButton")

-- Optional: Remove imports that you don't need
local Fusion = require(replicatedFirstVendor:WaitForChild "Fusion")

type CanBeState<T> = Fusion.CanBeState<T>
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
	OutlineColor: CanBeState<Color3>?, -- Color of the outline
	BackgroundColor: CanBeState<Color3>?, -- Should be left to default to remain consistent unless making a special UI
	TitleTextColor: CanBeState<Color3>?, -- Should also be left to default unless you want to make a special UI

	OuterChildren: CanBeState<{}>?, -- Children of the outer frame
	InnerChildren: CanBeState<{}>?, -- Children of the inner frame

	TitleText: CanBeState<string>?, -- Text of the title
	RemoveExitButton: boolean?, -- Removes the exit button. This cant be a state.

	onExitButtonClicked: (() -> ())?, -- Called when the exit button is clicked
}

--[[
	This component creates a stylized outlined menu.
]]
local function Component(props: Props)
	local frame = outlinedFrame {
		Name = props.Name,
		LayoutOrder = props.LayoutOrder,
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		Size = props.Size,
		ZIndex = props.ZIndex,

		OutlineColor = props.OutlineColor or InterfaceConstants.colors.menuGreen1,
		BackgroundColor = props.BackgroundColor or InterfaceConstants.colors.menuBackground,

		OuterChildren = {
			props.OuterChildren,

			bubbleText {
				Position = UDim2.new(0.5, 0, 0, 10),
				AnchorPoint = Vector2.new(0.5, 0.5),
				ZIndex = props.ZIndex,

				Text = props.TitleText,
				TextOutlineColor = props.OutlineColor or InterfaceConstants.colors.menuGreen1,
				TextColor = props.TitleTextColor or InterfaceConstants.colors.menuTitle,
			},

			if not props.RemoveExitButton
				then exitButton {
					Position = UDim2.new(1, -12, 0, 12),
					AnchorPoint = Vector2.new(0.5, 0.5),
					ZIndex = props.ZIndex,

					OnDown = props.onExitButtonClicked,
				}
				else nil,
		},
		Children = props.InnerChildren,
	}

	return frame
end

return Component
