local ReplicatedFirst = game:GetService "ReplicatedFirst"
local Players = game:GetService "Players"

local replicatedFirstVendor = ReplicatedFirst:WaitForChild "Vendor"
local replicatedFirstShared = ReplicatedFirst:WaitForChild "Shared"
local utilityFolder = replicatedFirstShared:WaitForChild "Utility"
local enumsFolder = replicatedFirstShared:WaitForChild "Enums"
local configurationFolder = replicatedFirstShared:WaitForChild "Configuration"

local ServerGroupEnum = require(enumsFolder:WaitForChild "ServerGroup")
local ServerTypeGroups = require(configurationFolder:WaitForChild "ServerTypeGroups")

if not ServerTypeGroups.serverInGroup(ServerGroupEnum.isRouting) then
	local Component = require(utilityFolder:WaitForChild "GetComponent")
	local Fusion = require(replicatedFirstVendor:WaitForChild "Fusion")

	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild "PlayerGui"

	local New = Fusion.New
	local Children = Fusion.Children

	local worldMenu, worldButton = Component "WorldMenu" {}
	local map, mapButton = Component "MapMenu" {}
	local partyList, partyListButton = Component "PartyList" {}
	local homeButton = Component "HomeButton" {}
	local minigameBrowser, minigameButton = Component "MinigameBrowser" {}

	local emptyTable = {}

	local function useUI(element, group, groupExcluded)
		if
			ServerTypeGroups.serverInGroup(group)
			and (if groupExcluded then ServerTypeGroups.serverInGroup(groupExcluded) else true)
		then
			return element
		else
			return emptyTable
		end
	end

	New "ScreenGui" {
		Name = "TestUI",
		IgnoreGuiInset = true,
		Parent = playerGui,

		[Children] = {
			New "Frame" { -- A list that contains all the buttons on the right side of the screen
				Name = "RightButtonList",
				Size = UDim2.fromScale(0, 0.5),
				Position = UDim2.fromScale(1, 0.5),
				AnchorPoint = Vector2.new(1, 0),

				BackgroundTransparency = 1,

				[Children] = {
					New "UIListLayout" {
						SortOrder = Enum.SortOrder.LayoutOrder,
						Padding = UDim.new(0, 5),
						FillDirection = Enum.FillDirection.Vertical,
						VerticalAlignment = Enum.VerticalAlignment.Top,
						HorizontalAlignment = Enum.HorizontalAlignment.Right,
					},

					useUI(worldButton, ServerGroupEnum.isWorldBased),
				},
			},

			New "Frame" { -- A list that contains all buttons on the top of the screen
				Name = "TopButtonList",
				Size = UDim2.fromScale(0, 0),
				Position = UDim2.fromOffset(150, 0),
				AnchorPoint = Vector2.new(0, 0),

				BackgroundTransparency = 1,

				[Children] = {
					New "UIListLayout" {
						SortOrder = Enum.SortOrder.LayoutOrder,
						Padding = UDim.new(0, 5),
						FillDirection = Enum.FillDirection.Horizontal,
						VerticalAlignment = Enum.VerticalAlignment.Top,
						HorizontalAlignment = Enum.HorizontalAlignment.Left,
					},

					useUI(partyListButton, ServerGroupEnum.isWorldBased),
					useUI(minigameButton, ServerGroupEnum.isWorldBased),
				},
			},

			New "Frame" { -- The hotbar, centered on the vertical axis
				Name = "Hotbar",
				Size = UDim2.fromOffset(0, 0),
				Position = UDim2.fromScale(0.5, 1),
				AnchorPoint = Vector2.new(0.5, 1),
				AutomaticSize = Enum.AutomaticSize.X,

				BackgroundTransparency = 1,

				[Children] = {
					New "UIListLayout" {
						SortOrder = Enum.SortOrder.LayoutOrder,
						Padding = UDim.new(0, 5),
						FillDirection = Enum.FillDirection.Horizontal,
						VerticalAlignment = Enum.VerticalAlignment.Bottom,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
					},

					useUI(mapButton, ServerGroupEnum.isWorldBased),
					useUI(homeButton, ServerGroupEnum.isWorldBased),
				},
			},

			useUI(worldMenu, ServerGroupEnum.isWorldBased),
			useUI(map, ServerGroupEnum.isWorldBased),
			useUI(partyList, ServerGroupEnum.isWorldBased),
			useUI(minigameBrowser, ServerGroupEnum.isWorldBased),
		},
	}
end
