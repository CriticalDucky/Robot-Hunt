local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local replicatedStorageShared = ReplicatedStorage:WaitForChild "Shared"
local replicatedFirstVendor = ReplicatedFirst:WaitForChild "Vendor"
local replicatedFirstShared = ReplicatedFirst:WaitForChild "Shared"
local configurationFolder = replicatedFirstShared:WaitForChild "Configuration"
local utilityFolder = replicatedFirstShared:WaitForChild "Utility"
local serverFolder = replicatedStorageShared:WaitForChild "Server"
local enumsFolder = replicatedFirstShared:WaitForChild "Enums"
local requestsFolder = replicatedStorageShared:WaitForChild "Requests"
local teleportationFolder = requestsFolder:WaitForChild "Teleportation"

local Fusion = require(replicatedFirstVendor:WaitForChild "Fusion")
local ServerGroupEnum = require(enumsFolder:WaitForChild "ServerGroup")
local ServerTypeGroups = require(configurationFolder:WaitForChild "ServerTypeGroups")
local ClientTeleport = require(teleportationFolder:WaitForChild "ClientTeleport")
local LocalServerInfo = require(serverFolder:WaitForChild "LocalServerInfo")
local ActiveParties = require(serverFolder:WaitForChild "ActiveParties")
local Parties = require(configurationFolder:WaitForChild "PartyConstants")
local Component = require(utilityFolder:WaitForChild "GetComponent")
local Types = require(utilityFolder:WaitForChild "Types")

local Value = Fusion.Value
local New = Fusion.New
local Children = Fusion.Children
local Computed = Fusion.Computed
local OnEvent = Fusion.OnEvent
local peek = Fusion.peek

type ServerIdentifier = Types.ServerIdentifier
type Computed<T> = Fusion.Computed<T>
type PartyUnit = Types.PartyUnit
type TimeRange = Types.TimeRange

local component = function(props)
	local LIST_LENGTH = 12 -- The list will display this many parties

	local open = Value(false)

	local partyListComputed = Computed(function(use)
		local list = ActiveParties.generatePartyList(LIST_LENGTH + 1, nil, use)

		if list[1].time:distanceToClosing(nil, use) <= 0 then
			table.remove(list, 1)
		else
			table.remove(list, LIST_LENGTH + 1)
		end

		return list
	end)

	local function button(buttonProps)
		return New "TextButton" {
			Size = buttonProps.size or UDim2.fromOffset(50, 50),
			LayoutOrder = buttonProps.layoutOrder or 1,
			Visible = buttonProps.visible or true,

			Text = buttonProps.text or "Parties",
			TextXAlignment = buttonProps.textXAlignment or Enum.TextXAlignment.Center,
			Font = Enum.Font.Gotham,
			TextSize = 18,

			[OnEvent "MouseButton1Click"] = function()
				local onClick = buttonProps.onClick
				local enabled = buttonProps.enabled

				if onClick then
					onClick()
				end

				if enabled then
					enabled:set(not peek(enabled))
				end
			end,

			[Children] = {
				New "UICorner" {
					CornerRadius = UDim.new(0, 5),
				},

				buttonProps.children,
			},
		}
	end

	local function partyButton(index)
		local currentParty: Computed<PartyUnit> = Computed(function(use)
			return use(partyListComputed)[index]
		end)

		local errored = Value(false)

		local button = button {
			onClick = function()
				local activeParty = ActiveParties.getActiveParty()

				if peek(currentParty).halfHourId == activeParty.halfHourId then
					if ServerTypeGroups.serverInGroup(ServerGroupEnum.isParty) then
						local serverInfo = LocalServerInfo.getServerIdentifier()

						if serverInfo and serverInfo.partyType == activeParty.partyType then
							open:set(false)

							return
						end
					end

					if activeParty.time:isInRange() then
						local success, response = ClientTeleport.toParty(activeParty.partyType)

						if not success then
							warn("Failed to teleport to party", response)

							errored:set(true)
						end
					end
				end
			end,
			layoutOrder = index,
			text = Computed(function(use)
				return Parties[use(currentParty).partyType].name
			end),
			textXAlignment = Enum.TextXAlignment.Left,
			size = UDim2.new(1, 0, 0, 50),

			children = {
				New "TextLabel" {
					Size = UDim2.new(0, 75, 1, 0),
					Position = UDim2.new(1, 0, 0, 0),
					AnchorPoint = Vector2.new(1, 0),
					BackgroundTransparency = 1,

					Text = Computed(function(use)
						local timeUntil = (use(currentParty).time :: TimeRange):distanceToIntroduction(nil, use)

						if timeUntil == 0 then
							return "GO NOW!"
						else
							local minutes = math.ceil(timeUntil / 60)

							-- If minutes is less than an hour, display minutes + "minutes," otherwise display hours + "hr(s)" + minutes + "min(s)"

							local function addS(number, string)
								if number == 1 then
									return string
								else
									return string .. "s"
								end
							end

							if minutes < 60 then
								return minutes .. addS(minutes, " minute")
							else
								local hours = math.floor(minutes / 60)
								local newMinutes = minutes % 60

								return hours .. addS(hours, " hr") .. " " .. newMinutes .. addS(newMinutes, " min")
							end
						end
					end),
					TextColor3 = Computed(function(use)
						local errored = use(errored)

						if errored then
							return Color3.fromRGB(180, 54, 54)
						else
							return Color3.fromRGB(0, 0, 0)
						end
					end),
					TextXAlignment = Enum.TextXAlignment.Right,
					Font = Enum.Font.Gotham,
				},
			},
		}

		return button
	end

	local partyButtons = {}
	do
		for i = 1, LIST_LENGTH do
			partyButtons[i] = partyButton(i)
		end
	end

	local menu = Component "DefaultElementList" {
		open = open,
		elements = partyButtons,
	}

	local newButton = button {
		onClick = function()
			open:set(not peek(open))
		end,
		size = UDim2.fromOffset(75, 50),
		layoutOrder = props.layoutOrder or 5,
	}

	return menu, newButton
end

return component
