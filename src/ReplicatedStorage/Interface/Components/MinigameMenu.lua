local ICON_SIZE_PX = 100

--#region Imports
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local replicatedStorageShared = ReplicatedStorage:WaitForChild "Shared"
local replicatedFirstVendor = ReplicatedFirst:WaitForChild "Vendor"
local replicatedFirstShared = ReplicatedFirst:WaitForChild "Shared"
local componentsFolder = replicatedStorageShared:WaitForChild("Interface"):WaitForChild "Components"
local enumsFolder = replicatedFirstShared:WaitForChild "Enums"
local serverFolder = replicatedStorageShared:WaitForChild "Server"
local requestsFolder = replicatedStorageShared:WaitForChild "Requests"
local configurationFolder = replicatedFirstShared:WaitForChild "Configuration"

local InterfaceConstants = require(configurationFolder:WaitForChild "InterfaceConstants")
local ServerTypeGroups = require(configurationFolder:WaitForChild "ServerTypeGroups")
local ServerGroupEnum = require(enumsFolder:WaitForChild "ServerGroup")
local MinigameConstants = require(configurationFolder:WaitForChild "MinigameConstants")
local ClientPlayMinigame = require(requestsFolder:WaitForChild("Minigames"):WaitForChild "ClientPlayMinigame")
local LocalServerInfo = require(serverFolder:WaitForChild "LocalServerInfo")
local outlinedMenu = require(componentsFolder:WaitForChild "OutlinedMenu")
local bannerButton = require(componentsFolder:WaitForChild "BannerButton")
local roundCornerMask = require(componentsFolder:WaitForChild "RoundCornerMask")

-- Optional: Remove imports that you don't need
local Fusion = require(replicatedFirstVendor:WaitForChild "Fusion")
local New = Fusion.New
local Children = Fusion.Children
local Value = Fusion.Value
local Computed = Fusion.Computed
local Spring = Fusion.Spring
local peek = Fusion.peek

type CanBeState<T> = Fusion.CanBeState<T>
type Computed<T> = Fusion.Computed<T>
-- #endregion

export type Props = {
	Position: CanBeState<UDim2>?,
	AnchorPoint: CanBeState<Vector2>?,
	Size: CanBeState<UDim2>?,
	ZIndex: CanBeState<number>?,

	onExitRequest: (any) -> nil,
}

--[[
	This component creates a party list.
]]
local function Component(props: Props)
	local minigameColor = InterfaceConstants.colors.minigameBlue

	local function minigameIcon(minigameEnum: string)
		local function brighten(color: Color3)
			local h, s, v = color:ToHSV()
			return Color3.fromHSV(h, s, math.min(v + 40 / 255, 1))
		end

		local minigame = MinigameConstants[minigameEnum]

		local isEnabled = Computed(function(use)
			local enabledTimeRange = minigame.enabledTime
			if not enabledTimeRange then return true end

			return enabledTimeRange:isInRange(nil, use)
		end)

		local isHovering = Value(false)

		local outlineColor = minigame.minigameIcon.color
		local image = minigame.minigameIcon.image

		local springSpeed = InterfaceConstants.animation.bubbleButtonColorSpring.speed
		local springDamping = InterfaceConstants.animation.bubbleButtonColorSpring.damping

		local button = bannerButton {
			Size = Spring(
				Computed(function(use)
					local growthPx = if use(isHovering) then 8 else 0

					return UDim2.new(1, growthPx, 1, growthPx)
				end),
				springSpeed,
				springDamping
			),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),

			RoundnessPixels = Spring(
				Computed(function(use) return 20 + (use(isHovering) and 4 or 0) end),
				springSpeed,
				springDamping
			),
			BorderColor = outlineColor,
			DarkenOnHover = true,
			Image = image,
			BorderHoverColor = Computed(function(use) return brighten(use(outlineColor)) end),

			OnDown = function()
				if peek(isEnabled) then
					if ServerTypeGroups.serverInGroup(ServerGroupEnum.isMinigame) then
						local serverInfo = LocalServerInfo.getServerIdentifier()

						if serverInfo and serverInfo.minigameType == minigameEnum then
							props.onExitRequest()

							return
						end
					end

					local success, response = ClientPlayMinigame.request(minigameEnum)

					if not success then warn("Failed to teleport to party", response) end
				end
			end,
			isHovering = isHovering,
		}

		local frame = New "Frame" {
			Name = "Icon_" .. minigameEnum,
			Size = UDim2.fromOffset(ICON_SIZE_PX, ICON_SIZE_PX),
			LayoutOrder = minigame.layoutOrder,
			BackgroundTransparency = 1,

			[Children] = {
				button,
			},
		}

		return frame
	end

	local icons = {}

	for minigameType, minigame in MinigameConstants do
		if minigame.isBrowsable then
			table.insert(icons, minigameIcon(minigameType))
		end
	end

	local frame = outlinedMenu {
		Name = "PartyMenu",
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		Size = props.Size,
		ZIndex = props.ZIndex,

		OutlineColor = minigameColor,
		TitleText = "Minigames", -- TODO: Make an icon for this

		onExitButtonClicked = props.onExitRequest,

		InnerChildren = {
			New "UIPadding" {
				PaddingLeft = UDim.new(0, 8),
				PaddingRight = UDim.new(0, 4),
				PaddingTop = UDim.new(0, 32),
				PaddingBottom = UDim.new(0, 24),
			},

			New "Frame" {
				Name = "ScrollingFrameContainer",
				Size = UDim2.new(1, 0, 1, 0),
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.fromScale(0.5, 1),
				BackgroundTransparency = 1,

				[Children] = {
					New "ScrollingFrame" {
						Name = "ScrollingFrame",
						Size = UDim2.fromScale(1, 1),
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
						BackgroundTransparency = 1,
						CanvasSize = UDim2.new(0, 0, 0, 0),
						AutomaticCanvasSize = Enum.AutomaticSize.Y,
						TopImage = "rbxassetid://158362307",
						MidImage = "rbxassetid://158362264",
						BottomImage = "rbxassetid://158362221",
						ScrollBarThickness = 8,
						ScrollBarImageColor3 = Color3.new(0, 0, 0),
						ScrollBarImageTransparency = 0.9,
						VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,

						[Children] = {
							New "UIGridLayout" {
								CellSize = UDim2.fromOffset(ICON_SIZE_PX, ICON_SIZE_PX),
								CellPadding = UDim2.fromOffset(8, 8),
								SortOrder = Enum.SortOrder.LayoutOrder,
							},

							New "UIPadding" {
								PaddingLeft = UDim.new(0, 0),
								PaddingRight = UDim.new(0, 8+8),
								PaddingTop = UDim.new(0, 0),
								PaddingBottom = UDim.new(0, 0),
							},

							icons,
						},
					},

					roundCornerMask {
						CornerRadius = 24,
						Color = InterfaceConstants.colors.menuBackground,
						ScrollbarOffset = 12,
					},
				},
			},
		},
	}

	return frame
end

return Component
