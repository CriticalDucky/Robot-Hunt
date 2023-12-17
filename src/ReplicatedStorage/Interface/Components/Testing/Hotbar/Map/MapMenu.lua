local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local replicatedStorageShared = ReplicatedStorage:WaitForChild "Shared"
local replicatedFirstVendor = ReplicatedFirst:WaitForChild "Vendor"
local replicatedFirstShared = ReplicatedFirst:WaitForChild "Shared"
local utilityFolder = replicatedFirstShared:WaitForChild "Utility"
local serverFolder = replicatedStorageShared:WaitForChild "Server"
local configurationFolder = replicatedFirstShared:WaitForChild "Configuration"
local requestsFolder = replicatedStorageShared:WaitForChild "Requests"
local enumsFolder = replicatedFirstShared:WaitForChild "Enums"

local Component = require(utilityFolder:WaitForChild "GetComponent")
local Fusion = require(replicatedFirstVendor:WaitForChild "Fusion")
local Locations = require(configurationFolder:WaitForChild "LocationConstants")
local ClientTeleport = require(requestsFolder:WaitForChild("Teleportation"):WaitForChild "ClientTeleport")
local ServerTypeGroups = require(configurationFolder:WaitForChild "ServerTypeGroups")
local ServerGroupEnum = require(enumsFolder:WaitForChild "ServerGroup")
local LocalServerInfo = require(serverFolder:WaitForChild "LocalServerInfo")

local Value = Fusion.Value
local New = Fusion.New
local Children = Fusion.Children
local Computed = Fusion.Computed
local OnEvent = Fusion.OnEvent
local peek = Fusion.peek

local component = function(props)
	local locationButtons = {}

	local open = Value(false)
	local enabled = Value(false)

	task.spawn(function()
		if ServerTypeGroups.serverInGroup(ServerGroupEnum.isWorldBased) then
			LocalServerInfo.getServerIdentifier()

			enabled:set(true)
		end
	end)

	for priority, locationEnum in pairs(Locations.priority) do
		local location = Locations.info[locationEnum]

		local hasErrored = Value(false)

		local function onResponse(success, response)
			if not success then
				warn("Failed to teleport to location: " .. tostring(response))

				hasErrored:set(true)
			end
		end

		local button = New "TextButton" {
			BackgroundColor3 = Computed(function(use)
				if use(hasErrored) then
					return Color3.fromRGB(255, 0, 0)
				else
					return Color3.fromRGB(0, 0, 0)
				end
			end),
			LayoutOrder = priority,

			Text = location.name,
			TextSize = 18,
			TextWrapped = true,
			TextColor3 = Color3.fromRGB(255, 255, 255),

			[OnEvent "MouseButton1Click"] = function()
				if ServerTypeGroups.serverInGroup(ServerGroupEnum.isLocation) then
					local serverInfo = LocalServerInfo.getServerIdentifier()

					if not serverInfo then
						return
					end

					if serverInfo.locationEnum == locationEnum then
						open:set(false)
					else
						onResponse(ClientTeleport.toLocation(locationEnum))
					end
				else
					onResponse(ClientTeleport.toLocation(locationEnum))
				end
			end,
		}

		table.insert(locationButtons, button)
	end

	local map = New "Frame" {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.new(0, 400, 0, 400),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Visible = Computed(function(use)
			return use(open) and use(enabled)
		end),

		[Children] = {
			New "Frame" {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,

				[Children] = {
					New "UIGridLayout" {
						CellSize = UDim2.new(0, 100, 0, 100),
						FillDirection = Enum.FillDirection.Horizontal,
						SortOrder = Enum.SortOrder.LayoutOrder,
						StartCorner = Enum.StartCorner.TopLeft,
					},

					locationButtons,
				},
			},

			Component "ExitButton" {
				value = open,
			},
		},
	}

	return map,
		New "TextButton" {
			Size = UDim2.fromOffset(75, 75),
			LayoutOrder = 100,
			Visible = true,

			Text = "Map",
			Font = Enum.Font.Gotham,
			TextSize = 18,

			[OnEvent "MouseButton1Click"] = function()
				open:set(not peek(open))
			end,

			[Children] = {
				New "UICorner" {
					CornerRadius = UDim.new(0, 5),
				},
			},
		}
end

return component
