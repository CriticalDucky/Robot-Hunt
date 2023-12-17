local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Players = game:GetService "Players"

local replicatedStorageShared = ReplicatedStorage:WaitForChild "Shared"
local replicatedFirstShared = ReplicatedFirst:WaitForChild "Shared"
local replicatedFirstVendor = ReplicatedFirst:WaitForChild "Vendor"
local utilityFolder = replicatedFirstShared:WaitForChild "Utility"
local configurationFolder = replicatedFirstShared:WaitForChild "Configuration"
local serverFolder = replicatedStorageShared:WaitForChild "Server"
local requestsFolder = replicatedStorageShared:WaitForChild "Requests"
local enumsFolder = replicatedFirstShared:WaitForChild "Enums"

local Fusion = require(replicatedFirstVendor:WaitForChild "Fusion")
local ClientTeleport = require(requestsFolder:WaitForChild("Teleportation"):WaitForChild "ClientTeleport")
local LocalServerInfo = require(serverFolder:WaitForChild "LocalServerInfo")
local ServerTypeGroups = require(configurationFolder:WaitForChild "ServerTypeGroups")
local ServerGroupEnum = require(enumsFolder:WaitForChild "ServerGroup")
local Types = require(utilityFolder:WaitForChild "Types")

type ServerIdentifier = Types.ServerIdentifier

local Value = Fusion.Value
local New = Fusion.New
local Children = Fusion.Children
local Computed = Fusion.Computed
local OnEvent = Fusion.OnEvent

local player = Players.LocalPlayer

local component = function(props)
	local visible = Value(false)
	local errored = Value(false)

	if ServerTypeGroups.serverInGroup(ServerGroupEnum.isHome) then
		task.spawn(function()
			local serverIdentifier = LocalServerInfo.getServerIdentifier()

			if serverIdentifier then
				visible:set(serverIdentifier.homeOwner ~= player.UserId)
			end
		end)
	else
		visible:set "true"
	end

	return New "TextButton" {
		Size = UDim2.fromOffset(75, 75),
		LayoutOrder = 50,
		Visible = visible,
		BackgroundColor3 = Computed(function(use)
			if use(errored) then
				return Color3.fromRGB(255, 102, 102)
			else
				return Color3.fromRGB(255, 255, 255)
			end
		end),

		Text = "Home",
		Font = Enum.Font.Gotham,
		TextSize = 18,

		[OnEvent "MouseButton1Click"] = function()
			local success, response = ClientTeleport.toHome(player.UserId)

			if not success then
				warn("Failed to teleport to home:", response)
				errored:set(true)
			end
		end,

		[Children] = {
			New "UICorner" {
				CornerRadius = UDim.new(0, 5),
			},
		},
	}
end

return component
