--!strict

local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local RunService = game:GetService "RunService"
local Players = game:GetService "Players"

local replicatedFirstVendor = ReplicatedFirst:WaitForChild "Vendor"

local RoundConfiguration = require(ReplicatedStorage:WaitForChild("Configuration"):WaitForChild "RoundConfiguration")
local ClientState = require(ReplicatedStorage:WaitForChild("Data"):WaitForChild "ClientState")
local ClientRoundDataUtility =
	require(ReplicatedStorage:WaitForChild("Data"):WaitForChild("RoundData"):WaitForChild "ClientRoundDataUtility")
local Enums = require(ReplicatedFirst:WaitForChild "Enums")

local Fusion = require(replicatedFirstVendor:WaitForChild "Fusion")
local Children = Fusion.Children

local scope = Fusion.scoped(Fusion)

local playerGui = game:GetService("Players").LocalPlayer:WaitForChild "PlayerGui"

local RoundType = Enums.RoundType
local PhaseType = Enums.PhaseType

local roundData = ClientState.external.roundData

local HEALTH_COLOR = Color3.fromRGB(250, 175, 0)
local HEALTH_COLOR_BACKGROUND = Color3.fromRGB(130, 59, 0)
local SHIELD_COLOR = Color3.fromRGB(0, 183, 255)
local SHIELD_COLOR_BACKGROUND = Color3.fromRGB(39, 85, 191)
local LIFESUPPORT_COLOR = Color3.fromRGB(36, 87, 228)
local LIFESUPPORT_COLOR_BACKGROUND = Color3.fromRGB(32, 57, 126)
local BACKGROUND = Color3.fromRGB(44, 48, 58)
local BACKGROUND_LIGHT = Color3.fromRGB(73, 80, 97)

--[[
scope:New "ScreenGui" {
	Parent = playerGui,

	[Children] = {
		scope:New "Frame" { -- Health bar
			Name = "HealthBar",
			BackgroundTransparency = 0,
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			Size = UDim2.new(0.2, 0, 0.05, 0),
			Position = UDim2.new(0.5, 0, 0.9, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Visible = scope:Computed(function(use)
				local playerDatas = use(roundData.playerData)
				local playerData = playerDatas[Players.LocalPlayer.UserId]

				if playerData then
					if playerData.isLobby then return false end

					return playerData.status == Enums.PlayerStatus.alive
						or playerData.status == Enums.PlayerStatus.lifeSupport
				else
					return false
				end
			end),
			[Children] = {
				scope:New "Frame" {
					Name = "Fill",
					BackgroundColor3 = scope:Computed(function(use) -- red if alive, blue if life support
						local playerDatas = use(roundData.playerData)
						local playerData = playerDatas[Players.LocalPlayer.UserId]

						if playerData then
							if playerData.status == Enums.PlayerStatus.alive then
                                if playerData.shield > 0 then
                                    return Color3.fromRGB(17, 164, 255)
                                end

								return Color3.fromRGB(248, 221, 14)
							elseif playerData.status == Enums.PlayerStatus.lifeSupport then
								return Color3.fromRGB(51, 0, 255)
							else
								return Color3.fromRGB(100, 0, 0)
							end
						else
							return Color3.fromRGB(100, 0, 0)
						end
					end),
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 0, 0.5, 0),
					BorderSizePixel = 0,
					Size = scope:Computed(function(use)
						local playerDatas = use(roundData.playerData)
						local playerData = playerDatas[Players.LocalPlayer.UserId]

						if playerData then
							if playerData.status == Enums.PlayerStatus.alive then
								local health = playerData.health or 100
                                local shield = playerData.shield or 0
                                if shield > 0 then
                                    return UDim2.new(shield / RoundConfiguration.shieldBaseAmount, 0, 1, 0)
                                end

								return UDim2.new(health / 100, 0, 1, 0)
							elseif playerData.status == Enums.PlayerStatus.lifeSupport then
								local lifeSupport = playerData.lifeSupport
								return UDim2.new(lifeSupport and lifeSupport / 100 or 0, 0, 1, 0)
							else
								return UDim2.new(0, 0, 1, 0)
							end
						else
							return UDim2.new(0, 0, 1, 0)
						end
					end),
				},
			},
		},
	},
}

]]

scope:New "ScreenGui" {
    Name = "Health",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = playerGui,

    [Children] = {
        scope:New "Frame" {
            Name = "Frame",
            AnchorPoint = Vector2.new(0.5, 1),
            BackgroundColor3 = BACKGROUND,
            Position = UDim2.new(0.5, 0, 1, -20),
            Size = UDim2.fromOffset(140, 70),
			Visible = scope:Computed(function(use)
				local playerDatas = use(roundData.playerData)
				local playerData = playerDatas[Players.LocalPlayer.UserId]

				if playerData then
					if playerData.isLobby then return false end

					return playerData.status == Enums.PlayerStatus.alive
						or playerData.status == Enums.PlayerStatus.lifeSupport
				else
					return false
				end
			end),

            [Children] = {
                scope:New "UICorner" {
                    Name = "UICorner",
                    CornerRadius = UDim.new(0, 28),
                },

                scope:New "Frame" {
                    Name = "Decoration",
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundColor3 = BACKGROUND,
                    Position = UDim2.fromScale(1, 0.5),
                    Size = UDim2.fromOffset(10, 25),
                    ZIndex = 0,

                    [Children] = {
                        scope:New "UICorner" {
                            Name = "UICorner",
                            CornerRadius = UDim.new(0, 4),
                        },
                    }
                },

                scope:New "Frame" {
                    Name = "Frame",
                    BackgroundTransparency = 1,
                    Size = UDim2.fromScale(1, 1),

                    [Children] = {
                        scope:New "Frame" {
                            Name = "HealthContainer",
                            AnchorPoint = Vector2.new(0.5, 0.5),
                            BackgroundColor3 = BACKGROUND,
                            Position = UDim2.fromScale(0.5, 0.5),
                            Size = UDim2.new(1, -24, 1, -24),
                            ZIndex = 10,

                            [Children] = {
                                scope:New "UICorner" {
                                    Name = "UICorner",
                                    CornerRadius = UDim.new(0, 12),
                                },

                                scope:New "Frame" {
                                    Name = "HealthForeground",
                                    BackgroundTransparency = 1,
                                    ClipsDescendants = true,
                                    Size = scope:Computed(function(use)
										local playerDatas = use(roundData.playerData)
										local playerData = playerDatas[Players.LocalPlayer.UserId]

										if playerData then
											if playerData.status == Enums.PlayerStatus.alive then
												local health = playerData.health or 100
												return UDim2.new(health / 100, 0, 1, 0)
											elseif playerData.status == Enums.PlayerStatus.lifeSupport then
												local lifeSupport = playerData.lifeSupport
												return UDim2.new(lifeSupport and lifeSupport / 100 or 0, 0, 1, 0)
											else
												return UDim2.new(0, 0, 1, 0)
											end
										else
											return UDim2.new(0, 0, 1, 0)
										end
									end),
                                    ZIndex = 2,

                                    [Children] = {
                                        scope:New "Frame" {
                                            Name = "Content",
                                            BackgroundColor3 = scope:Computed(function(use) -- red if alive, blue if life support
												local playerDatas = use(roundData.playerData)
												local playerData = playerDatas[Players.LocalPlayer.UserId]

												if playerData then
													if playerData.status == Enums.PlayerStatus.alive then
														return HEALTH_COLOR
													elseif playerData.status == Enums.PlayerStatus.lifeSupport then
														return LIFESUPPORT_COLOR
													else
														return BACKGROUND
													end
												else
													return BACKGROUND
												end
											end),
                                            Size = UDim2.new(0, 96, 1, 0),
                                            ZIndex = 2,

                                            [Children] = {
                                                scope:New "UICorner" {
                                                    Name = "UICorner",
                                                },
                                            }
                                        },
                                    }
                                },

                                scope:New "Frame" {
                                    Name = "HealthBackground",
                                    BackgroundColor3 = scope:Computed(function(use) -- life support / health color / background
										local playerDatas = use(roundData.playerData)
										local playerData = playerDatas[Players.LocalPlayer.UserId]

										if playerData then
											if playerData.status == Enums.PlayerStatus.alive then
												return HEALTH_COLOR_BACKGROUND
											elseif playerData.status == Enums.PlayerStatus.lifeSupport then
												return LIFESUPPORT_COLOR_BACKGROUND
											else
												return BACKGROUND
											end
										else
											return BACKGROUND
										end
									end),
                                    Size = UDim2.fromScale(1, 1),

                                    [Children] = {
                                        scope:New "UICorner" {
                                            Name = "UICorner",
                                        },
                                    }
                                },

                                scope:New "UIPadding" {
                                    Name = "UIPadding",
                                    PaddingBottom = UDim.new(0, 4),
                                    PaddingLeft = UDim.new(0, 4),
                                    PaddingRight = UDim.new(0, 4),
                                    PaddingTop = UDim.new(0, 4),
                                },
                            }
                        },

                        scope:New "Frame" {
                            Name = "ShieldBackground",
                            BackgroundColor3 = scope:Computed(function(use) -- if in life support, BACKGROUND_LIGHT, else SHIELD_COLOR_BACKGROUND
								local playerDatas = use(roundData.playerData)
								local playerData = playerDatas[Players.LocalPlayer.UserId]

								if playerData then
									if playerData.status == Enums.PlayerStatus.alive then
										return SHIELD_COLOR_BACKGROUND
									elseif playerData.status == Enums.PlayerStatus.lifeSupport then
										return BACKGROUND_LIGHT
									else
										return BACKGROUND
									end
								else
									return BACKGROUND
								end
							end),
                            Size = UDim2.fromScale(1, 1),

                            [Children] = {
                                scope:New "UICorner" {
                                    Name = "UICorner",
                                    CornerRadius = UDim.new(0, 22),
                                },
                            }
                        },

                        scope:New "Frame" {
                            Name = "ShieldForeground",
                            BackgroundTransparency = 1,
                            ClipsDescendants = true,
                            Size = scope:Computed(function(use)
								local playerDatas = use(roundData.playerData)
								local playerData = playerDatas[Players.LocalPlayer.UserId]

								if playerData then
									if playerData.status == Enums.PlayerStatus.alive then
										local shield = playerData.shield or 0
										return UDim2.new(shield / RoundConfiguration.shieldBaseAmount, 0, 1, 0)
									else
										return UDim2.new(0, 0, 1, 0)
									end
								else
									return UDim2.new(0, 0, 1, 0)
								end
							end),
                            ZIndex = 2,

                            [Children] = {
                                scope:New "Frame" {
                                    Name = "Content",
                                    BackgroundColor3 = SHIELD_COLOR,
                                    Size = UDim2.new(0, 128, 1, 0),
                                    ZIndex = 2,

                                    [Children] = {
                                        scope:New "UICorner" {
                                            Name = "UICorner",
                                            CornerRadius = UDim.new(0, 22),
                                        },
                                    }
                                },
                            }
                        },

                        scope:New "UIPadding" {
                            Name = "UIPadding",
                            PaddingBottom = UDim.new(0, 6),
                            PaddingLeft = UDim.new(0, 6),
                            PaddingRight = UDim.new(0, 6),
                            PaddingTop = UDim.new(0, 6),
                        },
                    }
                },
            }
        },
    }
}