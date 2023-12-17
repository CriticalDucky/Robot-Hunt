local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local replicatedStorageShared = ReplicatedStorage:WaitForChild "Shared"
local replicatedFirstVendor = ReplicatedFirst:WaitForChild "Vendor"
local replicatedFirstShared = ReplicatedFirst:WaitForChild "Shared"
local utilityFolder = replicatedFirstShared:WaitForChild "Utility"
local serverFolder = replicatedStorageShared:WaitForChild "Server"
local enumsFolder = replicatedFirstShared:WaitForChild "Enums"
local requestsFolder = replicatedStorageShared:WaitForChild "Requests"
local configurationFolder = replicatedFirstShared:WaitForChild "Configuration"

local Component = require(utilityFolder:WaitForChild "GetComponent")
local Fusion = require(replicatedFirstVendor:WaitForChild "Fusion")
local ReplicatedServerData = require(serverFolder:WaitForChild "ReplicatedServerData")
local LiveServerData = require(serverFolder:WaitForChild "LiveServerData")
local LocalServerInfo = require(serverFolder:WaitForChild "LocalServerInfo")
local WorldNames = require(configurationFolder:WaitForChild "WorldNames")
local ServerGroupEnum = require(enumsFolder:WaitForChild "ServerGroup")
local ServerTypeGroups = require(configurationFolder:WaitForChild "ServerTypeGroups")
local ClientTeleport = require(requestsFolder:WaitForChild("Teleportation"):WaitForChild "ClientTeleport")
local WorldOrigin = require(serverFolder:WaitForChild "WorldOrigin")
local Promise = require(replicatedFirstVendor:WaitForChild "Promise")

local Value = Fusion.Value
local New = Fusion.New
local Children = Fusion.Children
local Computed = Fusion.Computed
local OnEvent = Fusion.OnEvent
local Observer = Fusion.Observer
local peek = Fusion.peek

local component = function(props)
	local open = Value(false)
	local enabled = Value(false)

	local worldButtons = {}

	Promise.all({
		Promise.new(function(resolve)
			if ServerTypeGroups.serverInGroup(ServerGroupEnum.isWorldBased) then
				LocalServerInfo.getServerIdentifier()
			end

			resolve()
		end),

		Promise.new(function(resolve)
			LiveServerData.initialWait()
			resolve()
		end),
	}):andThen(function()
		enabled:set(true)
	end)

	local function button(buttonProps)
		return New "TextButton" {
			Size = buttonProps.size or UDim2.fromOffset(50, 50),
			LayoutOrder = buttonProps.layoutOrder or 1,
			Visible = buttonProps.visible or true,

			Text = buttonProps.text or "Worlds",
			Font = Enum.Font.Gotham,
			TextSize = 18,

			[OnEvent "MouseButton1Click"] = function()
				local onClick = buttonProps.onClick
				local enabled = buttonProps.enabled

				if onClick then onClick() end

				if enabled then enabled:set(not peek(enabled)) end
			end,

			[Children] = {
				New "UICorner" {
					CornerRadius = UDim.new(0, 5),
				},

				buttonProps.children,
			},
		}
	end

	local function worldButton(worldIndex)
		local errored = Value(false)
		local layoutOrder = Value(0)

		Observer(open):onChange(function()
			if peek(open) then layoutOrder:set(worldIndex - LiveServerData.getWorldPopulation(worldIndex) * 10000) end
		end)

		local button = button {
			onClick = function()
				local success, response = ClientTeleport.toWorld(worldIndex)

				if not success then
					errored:set(true)
					warn("Failed to teleport to world " .. worldIndex .. ": ", response)
				end
			end,
			layoutOrder = layoutOrder,
			text = WorldNames.get(worldIndex),
			size = UDim2.new(1, 0, 0, 50),
			visible = Computed(function(use)
				if not use(enabled) then return false end

				local serverDataValue = use(ReplicatedServerData.value)
				local liveServerDataValue = use(LiveServerData.value)

				local currentWorlds = ReplicatedServerData.withData.getWorlds(serverDataValue)

				if not currentWorlds then return false end

				local isFirstThreeEmptyWorlds = false
				do
					local emptyWorlds = 0

					for index, _ in ipairs(currentWorlds) do
						if LiveServerData.withData.getWorldPopulation(liveServerDataValue, index) == 0 then
							emptyWorlds += 1
						end

						if index == worldIndex then
							isFirstThreeEmptyWorlds = true
							break
						end

						if emptyWorlds >= 3 then break end
					end
				end

				local isDifferentWorld
				do
					if ServerTypeGroups.serverInGroup(ServerGroupEnum.isLocation) then
						local serverIdentifier = LocalServerInfo.getServerIdentifier()

						if serverIdentifier then
							isDifferentWorld = serverIdentifier.worldIndex ~= worldIndex
						else
							isDifferentWorld = true
						end
					elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.hasWorldOrigin) then
						local worldOrigin = WorldOrigin.get()

						if worldOrigin then
							isDifferentWorld = worldOrigin ~= worldIndex
						else
							isDifferentWorld = true
						end
					else
						isDifferentWorld = true
					end
				end

				return (
					(isFirstThreeEmptyWorlds or (LiveServerData.withData.getWorldPopulation(liveServerDataValue, worldIndex) ~= 0))
					and isDifferentWorld
					and true
				) or false
			end),

			children = {
				New "TextLabel" {
					Size = UDim2.new(0, 50, 1, 0),
					Position = UDim2.new(1, 0, 0, 0),
					AnchorPoint = Vector2.new(1, 0),
					BackgroundTransparency = 1,

					Text = Computed(function(use)
						local liveServerDataValue = use(LiveServerData.value)

						return LiveServerData.withData.getWorldPopulation(liveServerDataValue, worldIndex)
					end),
					TextColor3 = Computed(function(use)
						return if use(errored) then Color3.fromRGB(255, 0, 0) else Color3.fromRGB(0, 0, 0)
					end),
					Font = Enum.Font.Gotham,
				},
			},
		}

		return button
	end

	local newWorldButtons = Computed(function(use)
		local data = use(ReplicatedServerData.value)
		local currentWorlds = ReplicatedServerData.withData.getWorlds(data)

		if currentWorlds then
			for i, _ in ipairs(currentWorlds) do
				worldButtons[i] = worldButtons[i] or worldButton(i)
			end
		end

		return worldButtons
	end)

	local menu = Component "DefaultElementList" {
		open = open,
		elements = newWorldButtons,
	}

	local newButton = button {
		onClick = function()
			open:set(not peek(open))
		end,
		text = "Worlds",
		size = UDim2.fromOffset(75, 75),
		layoutOrder = props.layoutOrder or 1,
		visible = enabled,
	}

	return menu, newButton
end

return component
