local HEALTH_0_GRADIENT_LOCATION = 0.13
local HEALTH_FULL_GRADIENT_LOCATION = 0.794

local LOCATOR_VISIBILITY_MODE = {
	OFF = 0,
	LIFE_SUPPORT = 1,
	HEALTH = 2,
	TRACKER = 3,
}

local Players = game:GetService "Players"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local components = ReplicatedStorage:WaitForChild("Interface"):WaitForChild "Components"

local ClientState = require(ReplicatedStorage:WaitForChild("Data"):WaitForChild "ClientState")
local ClientRoundDataUtility =
	require(ReplicatedStorage:WaitForChild("Data"):WaitForChild("RoundData"):WaitForChild "ClientRoundDataUtility")
local RadialProgress = require(components:WaitForChild "RadialProgress")
local Enums = require(ReplicatedFirst:WaitForChild "Enums")

local Fusion = require(ReplicatedFirst:WaitForChild("Vendor"):WaitForChild "Fusion")
local Children = Fusion.Children

local localPlayer = Players.LocalPlayer

local function onPlayerAdded(player: Player)
	if player == localPlayer then return end

	local playerScope = Fusion:scoped()

	local playerData = playerScope:Computed(
		function(use) return use(ClientState.external.roundData.playerData)[player.UserId] end
	)
	local localPlayerData = playerScope:Computed(
		function(use) return use(ClientState.external.roundData.playerData)[localPlayer.UserId] end
	)

	local isSelectedPlayerOnOpposingTeam = playerScope:Computed(function(use)
		local playerData = use(playerData)
		local localPlayerData = use(localPlayerData)

		if not playerData or not localPlayerData then return false end

		local opposingTeam = Enums.TeamType.rebels
		if localPlayerData.team == Enums.TeamType.rebels then opposingTeam = Enums.TeamType.hunters end
		return playerData.team == opposingTeam
	end)

	local locatorVisibilityMode = playerScope:Computed(function(use)
		local playerData = use(playerData)
		local localPlayerData = use(localPlayerData)
		local currentPhaseType = use(ClientState.external.roundData.currentPhaseType)

		if not playerData then return LOCATOR_VISIBILITY_MODE.OFF end

		if playerData.isLobby then return LOCATOR_VISIBILITY_MODE.OFF end

		if not use(ClientState.actions.isSpectating) then
			if localPlayerData and localPlayerData.isLobby then
				return LOCATOR_VISIBILITY_MODE.OFF
			elseif not localPlayerData then
				return LOCATOR_VISIBILITY_MODE.OFF
			end
		end

		if playerData.status == Enums.PlayerStatus.lifeSupport then return LOCATOR_VISIBILITY_MODE.LIFE_SUPPORT end

		if playerData.status == Enums.PlayerStatus.alive then
			if use(isSelectedPlayerOnOpposingTeam) then
                local roundPlayerData = use(ClientState.external.roundData.playerData)

                for _, data in pairs(roundPlayerData) do
                    if data.victims[player.UserId] and data.playerId == localPlayer.UserId then
                        return LOCATOR_VISIBILITY_MODE.HEALTH
                    end
                end

				if currentPhaseType == Enums.PhaseType.Purge then return LOCATOR_VISIBILITY_MODE.TRACKER end
			else
				if use(ClientRoundDataUtility.isHoldingBattery) then return LOCATOR_VISIBILITY_MODE.HEALTH end

				return LOCATOR_VISIBILITY_MODE.TRACKER
			end
		end

		return LOCATOR_VISIBILITY_MODE.OFF
	end)

	local function onCharacterAdded(character: Model)
		local characterScope = playerScope:innerScope()

		local head = character:WaitForChild "Head"

		characterScope:New "BillboardGui" {
			Name = "Locator",
			Active = true,
			Size = UDim2.fromScale(0, 0),
			ClipsDescendants = false,
			AlwaysOnTop = true,
			LightInfluence = 1,
			StudsOffset = Vector3.new(0, 2, 0),
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			Parent = head,

			[Children] = {
				characterScope:New "Frame" {
					Name = "LocatorBackground",
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.new(),
					BackgroundTransparency = characterScope:Spring(
						characterScope:Computed(function(use)
							local locatorVisibilityMode = use(locatorVisibilityMode)

							if
								locatorVisibilityMode == LOCATOR_VISIBILITY_MODE.LIFE_SUPPORT
								or locatorVisibilityMode == LOCATOR_VISIBILITY_MODE.HEALTH
							then
								return 0.75
							end

							return 1
						end),
						25,
						1
					),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromOffset(42, 42),

					[Children] = {
						characterScope:New "UICorner" {
							CornerRadius = UDim.new(1, 0),
						},

						characterScope:New "UIPadding" {
							PaddingTop = UDim.new(0, 4),
							PaddingBottom = UDim.new(0, 4),
							PaddingLeft = UDim.new(0, 4),
							PaddingRight = UDim.new(0, 4),
						},

						RadialProgress(characterScope, {
							Name = "LifeSupportRadialProgress",
							Progress = characterScope:Computed(function(use)
								local locatorVisibilityMode = use(locatorVisibilityMode)

								if locatorVisibilityMode == LOCATOR_VISIBILITY_MODE.LIFE_SUPPORT then
									return use(playerData).lifeSupport
								end

								return 0
							end),

							ProgressColor = characterScope:Computed(function(use)
								local playerData = use(playerData)

								if not playerData then return Color3.fromRGB(255, 255, 255) end

								if playerData.team == Enums.TeamType.hunters then
									return Color3.fromRGB(251, 94, 121)
								elseif playerData.team == Enums.TeamType.rebels then
									return Color3.fromRGB(77, 196, 255)
								end

								return Color3.fromRGB(255, 255, 255)
							end),

							IsPie = true,

							ProgressTransparency = characterScope:Spring(
								characterScope:Computed(function(use)
									local locatorVisibilityMode = use(locatorVisibilityMode)

									if locatorVisibilityMode == LOCATOR_VISIBILITY_MODE.LIFE_SUPPORT then return 0 end

									return 1
								end),
								25,
								1
							),
							BackgroundTransparency = 1,
						}),

						characterScope:New "Frame" {
							Name = "Locator",
							AnchorPoint = Vector2.new(0.5, 0.5),
							BackgroundColor3 = characterScope:Computed(function(use)
								local playerData = use(playerData)

								if not playerData then return Color3.fromRGB(255, 255, 255) end

								if playerData.team == Enums.TeamType.hunters then
									return Color3.fromRGB(251, 94, 121)
								elseif playerData.team == Enums.TeamType.rebels then
									return Color3.fromRGB(77, 196, 255)
								end

								return Color3.fromRGB(255, 255, 255)
							end),
							BackgroundTransparency = characterScope:Spring(
								characterScope:Computed(function(use)
									local locatorVisibilityMode = use(locatorVisibilityMode)

									if locatorVisibilityMode == LOCATOR_VISIBILITY_MODE.TRACKER then return 0 end

									return 1
								end),
								25,
								1
							),
							Position = UDim2.fromScale(0.5, 0.5),
							Rotation = 45,
							Size = UDim2.fromOffset(10, 10),

							[Children] = {
								characterScope:New "UICorner" {
									Name = "UICorner",
									CornerRadius = UDim.new(0.2, 0),
								},
							},
						},

						characterScope:New "ImageLabel" {
							Name = "BatteryExterior",
							AnchorPoint = Vector2.new(0.5, 0.5),
							BackgroundTransparency = 1,
                            ImageTransparency = characterScope:Spring(
								characterScope:Computed(function(use)
									local locatorVisibilityMode = use(locatorVisibilityMode)

									if locatorVisibilityMode == LOCATOR_VISIBILITY_MODE.HEALTH then return 0 end

									return 1
								end),
								25,
								1
							),
							Image = "rbxassetid://116197655955445",
							ImageColor3 = characterScope:Computed(function(use)
								local playerData = use(playerData)

								if not playerData then return Color3.fromRGB(255, 255, 255) end

								if playerData.team == Enums.TeamType.hunters then
									return Color3.fromRGB(251, 94, 121)
								elseif playerData.team == Enums.TeamType.rebels then
									return Color3.fromRGB(77, 196, 255)
								end

								return Color3.fromRGB(255, 255, 255)
							end),
							Position = UDim2.fromScale(0.5, 0.5),
							Size = UDim2.fromOffset(24, 24),
						},

						characterScope:New "ImageLabel" {
							Name = "BatteryInterior",
							AnchorPoint = Vector2.new(0.5, 0.5),
							BackgroundTransparency = 1,
                            ImageTransparency = characterScope:Spring(
                                characterScope:Computed(function(use)
                                    local locatorVisibilityMode = use(locatorVisibilityMode)

                                    if locatorVisibilityMode == LOCATOR_VISIBILITY_MODE.HEALTH then return 0 end

                                    return 1
                                end),
                                25,
                                1
                            ),
							Image = "rbxassetid://94759543399004",
							ImageColor3 = characterScope:Computed(function(use)
                                local playerData = use(playerData)

                                if not playerData then return Color3.fromRGB(255, 255, 255) end

                                if playerData.team == Enums.TeamType.hunters then
                                    return Color3.fromRGB(251, 94, 121)
                                elseif playerData.team == Enums.TeamType.rebels then
                                    return Color3.fromRGB(77, 196, 255)
                                end

                                return Color3.fromRGB(255, 255, 255)
                            end),
							Position = UDim2.fromScale(0.5, 0.5),
							Size = UDim2.fromOffset(24, 24),

							[Children] = {
								characterScope:New "UIGradient" {
									Name = "UIGradient",
                                    Transparency = characterScope:Computed(function(use)
                                        local playerData = use(playerData)

                                        if not playerData then return NumberSequence.new(0) end

                                        local healthAlpha = playerData.health / 100

                                        if healthAlpha <= 0 then return NumberSequence.new(1) end

                                        local gradientLocation = HEALTH_0_GRADIENT_LOCATION + (HEALTH_FULL_GRADIENT_LOCATION - HEALTH_0_GRADIENT_LOCATION) * healthAlpha

                                        return NumberSequence.new {
                                            NumberSequenceKeypoint.new(0, 0),
                                            NumberSequenceKeypoint.new(gradientLocation, 0),
                                            NumberSequenceKeypoint.new(gradientLocation + 0.001, 1),
                                            NumberSequenceKeypoint.new(1, 1),
                                        }
                                    end),
								},
							},
						},
					},
				},
			},
		}
	end

	if player.Character then onCharacterAdded(player.Character) end

	player.CharacterAdded:Connect(function(character) onCharacterAdded(character) end)

	-- when player is leaving, destroy the scope

	table.insert(
		playerScope,
		Players.PlayerRemoving:Connect(function(removedPlayer)
			if removedPlayer == player then playerScope:destroy() end
		end)
	)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end
