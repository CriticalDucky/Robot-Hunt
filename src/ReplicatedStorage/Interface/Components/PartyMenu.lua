local PELLET_SIZE_Y = 80
local LIST_LENGTH = 7

--#region Imports
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local replicatedStorageShared = ReplicatedStorage:WaitForChild "Shared"
local replicatedFirstVendor = ReplicatedFirst:WaitForChild "Vendor"
local replicatedFirstShared = ReplicatedFirst:WaitForChild "Shared"
local utilityFolder = replicatedFirstShared:WaitForChild "Utility"
local componentsFolder = replicatedStorageShared:WaitForChild("Interface"):WaitForChild "Components"
local enumsFolder = replicatedFirstShared:WaitForChild "Enums"
local serverFolder = replicatedStorageShared:WaitForChild "Server"
local requestsFolder = replicatedStorageShared:WaitForChild "Requests"
local teleportationFolder = requestsFolder:WaitForChild "Teleportation"
local configurationFolder = replicatedFirstShared:WaitForChild "Configuration"

local InterfaceConstants = require(configurationFolder:WaitForChild "InterfaceConstants")
local ServerTypeGroups = require(configurationFolder:WaitForChild "ServerTypeGroups")
local ServerGroupEnum = require(enumsFolder:WaitForChild "ServerGroup")
local ActiveParties = require(serverFolder:WaitForChild "ActiveParties")
local PartyConstants = require(configurationFolder:WaitForChild "PartyConstants")
local ClientTeleport = require(teleportationFolder:WaitForChild "ClientTeleport")
local LocalServerInfo = require(serverFolder:WaitForChild "LocalServerInfo")
local Types = require(utilityFolder:WaitForChild "Types")
local outlinedMenu = require(componentsFolder:WaitForChild "OutlinedMenu")
local bannerButton = require(componentsFolder:WaitForChild "BannerButton")
local sectionDivider = require(componentsFolder:WaitForChild "SectionDivider")
local roundCornerMask = require(componentsFolder:WaitForChild "RoundCornerMask")

-- Optional: Remove imports that you don't need
local Fusion = require(replicatedFirstVendor:WaitForChild "Fusion")
local New = Fusion.New
local Children = Fusion.Children
local Computed = Fusion.Computed
local peek = Fusion.peek

---@diagnostic disable-next-line: undefined-type
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

type PartyPelletProps = {
	Index: number,
}

type PartyUnit = Types.PartyUnit

--[[
	This component creates a party list.
]]
local function Component(props: Props)
	local partiesPink = InterfaceConstants.colors.partiesPink

	local partyList = Computed(function(use)
		local list = ActiveParties.generatePartyList(LIST_LENGTH + 1, nil, use)

		if list[1].time:distanceToClosing(nil, use) <= 0 then
			table.remove(list, 1)
		else
			table.remove(list, LIST_LENGTH + 1)
		end

		return list
	end)

	local activePartyUnit = Computed(function(use) return ActiveParties.getActiveParty(use) end)

	local function partyPellet(index: number)
		local indexPartyUnit = Computed(function(use) return use(partyList)[index] end)

		local partyEnum = Computed(function(use) return use(indexPartyUnit).partyType end)

		local indexPartyConstantsTable = Computed(function(use) return PartyConstants[use(partyEnum)] end)

		local isJoinable = Computed(function(use) return use(indexPartyUnit).time:isInRange(nil, use) end)

		local distanceToIntroduction = Computed(
			function(use) return use(indexPartyUnit).time:distanceToIntroduction(nil, use) end
		)

		local outlineColor = Computed(function(use) return use(indexPartyConstantsTable).partyPellet.outlineColor end)
		local textColor = Computed(function(use) return use(indexPartyConstantsTable).partyPellet.textColor end)

		local button = bannerButton {
			Size = UDim2.fromScale(1, 1),

			RoundnessPixels = 24,
			BorderColor = outlineColor,
			DarkenOnHover = true,
			ZoomOnHover = true,
			InputExtraPx = 2,
			ZIndex = -1,
			Disabled = Computed(function(use) return not use(isJoinable) end),
			Image = Computed(function(use) return use(indexPartyConstantsTable).partyPellet.image end),
			BorderDisabledColor = outlineColor,
			BorderHoverColor = textColor, --Computed(function(use) return brighten(use(outlineColor)) end),

			OnDown = function()
				if peek(isJoinable) then
					if ServerTypeGroups.serverInGroup(ServerGroupEnum.isParty) then
						local serverInfo = LocalServerInfo.getServerIdentifier()

						if serverInfo and serverInfo.partyType == peek(activePartyUnit).partyType then
							props.onExitRequest()

							return
						end
					end

					local success, response = ClientTeleport.toParty(peek(partyEnum))

					if not success then warn("Failed to teleport to party", response) end
				end
			end,
		}

		local frame = New "Frame" {
			Name = "PartyPellet" .. index,
			Size = UDim2.new(1, 0, 0, PELLET_SIZE_Y),
			LayoutOrder = index,
			BackgroundTransparency = 1,

			[Children] = {
				button,

				New "TextLabel" {
					Name = "Title",
					Position = UDim2.fromOffset(16, 8),
					Size = UDim2.fromOffset(0, InterfaceConstants.fonts.partyTitle.size),
					BackgroundTransparency = 1,
					Text = Computed(function(use) return use(indexPartyConstantsTable).name end),
					TextColor3 = textColor,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Center,
					AutomaticSize = Enum.AutomaticSize.X,
					TextSize = InterfaceConstants.fonts.partyTitle.size,
					FontFace = InterfaceConstants.fonts.partyTitle.font,

					[Children] = {
						New "UIStroke" {
							Thickness = 4,
							ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
							Color = outlineColor,
						}
					}
				},

				New "TextLabel" {
					Name = "Time",
					AnchorPoint = Vector2.new(1, 1),
					Position = UDim2.fromScale(1, 1) - UDim2.fromOffset(8, 8),
					Size = UDim2.fromOffset(0, 32),
					AutomaticSize = Enum.AutomaticSize.X,
					BackgroundColor3 = outlineColor,

					TextXAlignment = Enum.TextXAlignment.Right,
					TextColor3 = textColor,
					TextSize = InterfaceConstants.fonts.partyTime.size,
					FontFace = InterfaceConstants.fonts.partyTime.font,
					Text = Computed(function(use)
						local secondsUntil = use(distanceToIntroduction)

						if secondsUntil <= 0 then
							return "GO NOW!"
						else
							--[[
								If the party is not available at this time, the time should display in the following
								formats:

								- 0 minutes
								- 1 minute
								- 24 minutes
								- 1 hr 9 mins
								- 2 hrs 1 min
							]]
							local minutes = math.ceil(secondsUntil / 60)
							local hours = math.floor(minutes / 60)

							if hours > 0 then minutes = minutes - (hours * 60) end

							local minutesString = ""
							local hoursString = ""

							if hours == 0 and minutes ~= 0 then -- 1-59 minutes
								minutesString = minutes .. " minute"
							elseif hours ~= 0 and minutes == 0 then -- on the hour
								hoursString = hours .. " hour"
							else -- 1-59 minutes and hours
								minutesString = minutes .. " min"
								hoursString = hours .. " hr"
							end

							if minutes > 1 then
								minutesString ..= "s"
							end

							if hours > 1 then
								hoursString ..= "s"
							end

							return ({ (hoursString .. " " .. minutesString):gsub("^%s*(.-)%s*$", "%1") })[1] -- remove spaces
						end
					end),

					[Children] = {
						New "UICorner" {
							CornerRadius = UDim.new(0, 16),
						},

						New "UIPadding" {
							PaddingLeft = UDim.new(0, 8),
							PaddingRight = UDim.new(0, 8),
						},
					},
				},
			},
		}

		return frame
	end

	local pellets = {}

	for i = 1, LIST_LENGTH do
		pellets[i] = partyPellet(i)
	end

	local upcomingPellets = { select(2, unpack(pellets)) }

	local frame = outlinedMenu {
		Name = "PartyMenu",
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		Size = props.Size,
		ZIndex = props.ZIndex,

		OutlineColor = partiesPink,
		TitleText = "Parties",

		onExitButtonClicked = props.onExitRequest,

		InnerChildren = {
			New "UIPadding" {
				PaddingLeft = UDim.new(0, 4),
				PaddingRight = UDim.new(0, 4),
				PaddingTop = UDim.new(0, 32),
				PaddingBottom = UDim.new(0, 24),
			},

			pellets[1],

			sectionDivider {
				Position = UDim2.fromOffset(0, PELLET_SIZE_Y + 18),
				Text = "Upcoming",
			},

			New "Frame" {
				Name = "ScrollingFrameContainer",
				Size = UDim2.new(1, 0, 1, -PELLET_SIZE_Y - 36),
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
							New "UIListLayout" {
								SortOrder = Enum.SortOrder.LayoutOrder,
								Padding = UDim.new(0, 4),
							},

							New "UIPadding" {
								PaddingLeft = UDim.new(0, 0),
								PaddingRight = UDim.new(0, 4),
								PaddingTop = UDim.new(0, 0),
								PaddingBottom = UDim.new(0, 0),
							},

							upcomingPellets,
						}
					},

					roundCornerMask {
						CornerRadius = 24,
						Color = InterfaceConstants.colors.menuBackground,
						ScrollbarOffset = 12,
					}
				}
			}

		},
	}

	return frame
end

return Component
