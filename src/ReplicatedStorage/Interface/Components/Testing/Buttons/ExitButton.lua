local ReplicatedFirst = game:GetService("ReplicatedFirst")

local replicatedFirstVendor = ReplicatedFirst:WaitForChild("Vendor")

local Fusion = require(replicatedFirstVendor:WaitForChild("Fusion"))

local New = Fusion.New
local Children = Fusion.Children
local OnEvent = Fusion.OnEvent

local component = function(props)
	local state = props.value

    local button = New "TextButton" {
        Size = UDim2.fromOffset(30, 30),
        AnchorPoint = Vector2.new(0, 0),
        Position = UDim2.new(1, 10, 0, 0),
        Visible = true,

        Text = "X",
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        Font = Enum.Font.GothamBlack,
        TextSize = 18,
        TextColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,

        [OnEvent "MouseButton1Down"] = function()
            state:set(false)
        end,

        [Children] = {
            New "UICorner" {
                CornerRadius = UDim.new(1, 0),
            },
        }
    }

    return button
end

return component