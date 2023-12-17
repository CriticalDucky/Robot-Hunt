local ReplicatedFirst = game:GetService("ReplicatedFirst")

local replicatedFirstVendor = ReplicatedFirst:WaitForChild("Vendor")
local replicatedFirstShared = ReplicatedFirst:WaitForChild("Shared")
local utilityFolder = replicatedFirstShared:WaitForChild("Utility")

local Component = require(utilityFolder:WaitForChild("GetComponent"))
local Fusion = require(replicatedFirstVendor:WaitForChild("Fusion"))

local New = Fusion.New
local Children = Fusion.Children

local component = function(props)
    local open = props.open
    local elements = props.elements

	local menu = New "Frame" {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(300, 400),
        BackgroundColor3 = Color3.fromRGB(160, 160, 160),
        Visible = open,

        [Children] = {
            New "UICorner" {
                CornerRadius = UDim.new(0, 10)
            },

            New "ScrollingFrame" {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,

                ClipsDescendants = true,
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                CanvasSize = UDim2.fromOffset(0, 0),
                ScrollBarThickness = 5,
                ScrollingDirection = Enum.ScrollingDirection.Y,
                HorizontalScrollBarInset = Enum.ScrollBarInset.ScrollBar,

                [Children] = {
                    New "UIListLayout" {
                        Padding = UDim.new(0, 5),
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        FillDirection = Enum.FillDirection.Vertical,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        VerticalAlignment = Enum.VerticalAlignment.Top,
                    },

                    New "UIPadding" {
                        PaddingLeft = UDim.new(0, 5),
                        PaddingRight = UDim.new(0, 5),
                        PaddingTop = UDim.new(0, 5),
                        PaddingBottom = UDim.new(0, 5),
                    },

                    elements,
                }
            },

            Component "ExitButton" {
                value = open,
            },
        }
    }

    return menu
end

return component