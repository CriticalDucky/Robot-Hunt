local X_IMAGE_ID = "rbxassetid://13267266385"

--#region Imports
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local replicatedStorageShared = ReplicatedStorage:WaitForChild "Shared"
local replicatedFirstVendor = ReplicatedFirst:WaitForChild "Vendor"
local replicatedFirstShared = ReplicatedFirst:WaitForChild "Shared"
local componentsFolder = replicatedStorageShared:WaitForChild("Interface"):WaitForChild "Components"
local configurationFolder = replicatedFirstShared:WaitForChild "Configuration"

local bubbleButton = require(componentsFolder:WaitForChild "BubbleButton")
local InterfaceConstants = require(configurationFolder:WaitForChild "InterfaceConstants")

-- Optional: Remove imports that you don't need
local Fusion = require(replicatedFirstVendor:WaitForChild "Fusion")

type CanBeState<T> = Fusion.CanBeState<T>
-- #endregion

export type Props = {
	-- Default props
	LayoutOrder: CanBeState<number>?,
	Position: CanBeState<UDim2>?,
	AnchorPoint: CanBeState<Vector2>?,
	ZIndex: CanBeState<number>?,

    -- Custom props
    PrimaryColor: CanBeState<Color3>?, -- background color; defaults to blue
	SecondaryColor: CanBeState<Color3>?, -- outlines, text, icon color; defaults to a darker blue

    OnClick: (() -> ())?,
    OnDown: (() -> ())?,
    Disabled: CanBeState<boolean>?,
}

--[[
	This component creates a stylized bubble exit button.
]]
local function Component(props: Props)
    return bubbleButton {
        Name = "ExitButton",
        LayoutOrder = props.LayoutOrder,
        Position = props.Position,
        AnchorPoint = props.AnchorPoint,
        ZIndex = props.ZIndex,

        PrimaryColor = props.PrimaryColor or InterfaceConstants.colors.buttonBluePrimary,
        SecondaryColor = props.SecondaryColor or InterfaceConstants.colors.buttonBlueSecondary,

        OnClick = props.OnClick,
        OnDown = props.OnDown,
        Disabled = props.Disabled,

        Icon = X_IMAGE_ID,

        Square = true,
    }
end

return Component
