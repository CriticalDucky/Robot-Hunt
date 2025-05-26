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
local Platform = require(ReplicatedFirst:WaitForChild ("Utility"):WaitForChild "Platform")

local Fusion = require(replicatedFirstVendor:WaitForChild "Fusion")
local Children = Fusion.Children

local scope = Fusion.scoped(Fusion)

local playerGui = game:GetService("Players").LocalPlayer:WaitForChild "PlayerGui"

local RoundType = Enums.RoundType
local PhaseType = Enums.PhaseType

local roundData = ClientState.external.roundData

local HUDGUI_TRANSITION_TIME = 0.5
local OFFSCREEN_HEALTH_LIFESUPPORT_OFFSET = 100
local OFFSCREEN_SLIDEIN_HUDGUI_INFO = TweenInfo.new(HUDGUI_TRANSITION_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, HUDGUI_TRANSITION_TIME)
local OFFSCREEN_SLIDEOUT_HUDGUI_INFO = TweenInfo.new(HUDGUI_TRANSITION_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, 0)

local isHealthGuiEnabled = scope:Computed(function(use)
	local isGameOver = use(roundData.isGameOver)

	if isGameOver then return false end

	local playerDatas = use(roundData.playerData)
	local playerData = playerDatas[Players.LocalPlayer.UserId]

	if playerData then
		if playerData.isLobby then return false end

		return playerData.status == Enums.PlayerStatus.alive
	else
		return false
	end
end)

local isLifeSupportGuiEnabled = scope:Computed(function(use)
	local isGameOver = use(roundData.isGameOver)

	if isGameOver then return false end

	local playerDatas = use(roundData.playerData)
	local playerData = playerDatas[Players.LocalPlayer.UserId]

	if playerData then
		if playerData.isLobby then return false end

		return playerData.status == Enums.PlayerStatus.lifeSupport
	else
		return false
	end
end)

scope:New "ScreenGui" {
	Name = "HUD",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = playerGui,

	[Children] = {
		scope:New "Frame" {
			Name = "HUD",
			AnchorPoint = Vector2.new(0, 1),
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 50, 1, -20),
			Size = UDim2.new(1, -100, 0, 70),

			[Children] = {
				scope:New "Frame" {
					Name = "Health",
					AnchorPoint = Vector2.new(0, 1),
					BackgroundTransparency = 1,
					Position = scope:Tween(
						scope:Computed(function(use)
							local isHealthGuiEnabled = use(isHealthGuiEnabled)

							if isHealthGuiEnabled then
								return UDim2.fromScale(0, 1)
							else
								return UDim2.fromScale(0, 1)
									+ UDim2.fromOffset(0, OFFSCREEN_HEALTH_LIFESUPPORT_OFFSET)
							end
						end),
						scope:Computed(function(use)
							local isHealthGuiEnabled = use(isHealthGuiEnabled)

							if isHealthGuiEnabled then
								return OFFSCREEN_SLIDEIN_HUDGUI_INFO
							else
								return OFFSCREEN_SLIDEOUT_HUDGUI_INFO
							end
						end)
					),
					Size = UDim2.fromOffset(200, 60),

					[Children] = {
						scope:New "Frame" {
							Name = "HealthBar",
							AnchorPoint = Vector2.new(0, 1),
							BackgroundTransparency = 1,
							LayoutOrder = 1,
							Position = UDim2.fromOffset(0, 60),
							Size = UDim2.fromOffset(192, 32),

							[Children] = {
								scope:New "TextLabel" {
									Name = "Amount",
									AutomaticSize = Enum.AutomaticSize.X,
									BackgroundTransparency = 1,
									FontFace = Font.new(
										"rbxasset://fonts/families/TitilliumWeb.json",
										Enum.FontWeight.Heavy,
										Enum.FontStyle.Normal
									),
									Position = UDim2.fromOffset(48, 0),
									Size = UDim2.fromScale(0, 1),
									Text = scope:Computed(function(use)
										local playerDatas = use(roundData.playerData)
										local playerData = playerDatas[Players.LocalPlayer.UserId]

										if playerData then
											return tostring(math.ceil(playerData.health or 100))
										else
											return "0"
										end
									end),
									TextColor3 = Color3.fromRGB(255, 236, 202),
									TextScaled = true,
									TextXAlignment = Enum.TextXAlignment.Left,
									ZIndex = 3,

									[Children] = {
										scope:New "UIPadding" {
											Name = "UIPadding",
											PaddingLeft = UDim.new(0, 6),
										},
									},
								},

								scope:New "ImageLabel" {
									Name = "Background",
									AnchorPoint = Vector2.new(0, 1),
									BackgroundTransparency = 1,
									Image = "rbxassetid://7952769553",
									ImageColor3 = Color3.new(),
									ImageTransparency = 0.75,
									Position = UDim2.fromScale(0, 1),
									ScaleType = Enum.ScaleType.Slice,
									Size = UDim2.fromScale(1, 1),
									SliceCenter = Rect.new(127, 0, 173, 0),
									SliceScale = 10,
									ZIndex = 0,
								},

								scope:New "ImageLabel" {
									Name = "Content",
									AnchorPoint = Vector2.new(0, 1),
									BackgroundTransparency = 1,
									Image = "rbxassetid://7952769553",
									ImageColor3 = Color3.fromRGB(250, 175, 0),
									Position = UDim2.fromScale(0, 1),
									ScaleType = Enum.ScaleType.Slice,
									Size = scope:Computed(function(use)
										local playerDatas = use(roundData.playerData)
										local playerData = playerDatas[Players.LocalPlayer.UserId]

										local scaleOfHealthBarAtZeroHealth = 0.24

										if playerData then
											return UDim2.fromScale(
												scaleOfHealthBarAtZeroHealth
													+ (1 - scaleOfHealthBarAtZeroHealth)
														* (playerData.health or 100)
														/ 100,
												1
											)
										else
											return UDim2.fromScale(scaleOfHealthBarAtZeroHealth, 1)
										end
									end),
									SliceCenter = Rect.new(127, 0, 173, 0),
									SliceScale = 10,
								},
							},
						},

						scope:New "Frame" {
							Name = "ShieldsBar",
							AnchorPoint = Vector2.new(0, 1),
							BackgroundTransparency = 1,
							LayoutOrder = 1,
							Position = UDim2.fromOffset(9, 24),
							Size = UDim2.fromOffset(189, 17),

							[Children] = {
								scope:New "TextLabel" {
									Name = "Amount",
									AutomaticSize = Enum.AutomaticSize.X,
									BackgroundTransparency = 1,
									FontFace = Font.new(
										"rbxasset://fonts/families/TitilliumWeb.json",
										Enum.FontWeight.Heavy,
										Enum.FontStyle.Normal
									),
									Position = UDim2.fromOffset(40, 0),
									Size = UDim2.fromScale(0, 1),
									Text = scope:Computed(function(use)
										local playerDatas = use(roundData.playerData)
										local playerData = playerDatas[Players.LocalPlayer.UserId]

										if playerData then
											return tostring(math.ceil(playerData.shield or 0))
										else
											return "0"
										end
									end),
									TextColor3 = Color3.fromRGB(158, 241, 255),
									TextScaled = true,
									TextXAlignment = Enum.TextXAlignment.Left,
									ZIndex = 3,

									[Children] = {
										scope:New "UIPadding" {
											Name = "UIPadding",
											PaddingLeft = UDim.new(0, 6),
										},
									},
								},

								scope:New "ImageLabel" {
									Name = "Content",
									AnchorPoint = Vector2.new(0, 1),
									BackgroundTransparency = 1,
									Image = "rbxassetid://7952769553",
									ImageColor3 = Color3.fromRGB(0, 183, 255),
									Position = UDim2.fromScale(0, 1),
									ScaleType = Enum.ScaleType.Slice,
									Size = scope:Computed(function(use)
										local playerDatas = use(roundData.playerData)
										local playerData = playerDatas[Players.LocalPlayer.UserId]

										local scaleOfShieldsBarAtZeroShields = 0.195

										if playerData then
											return UDim2.fromScale(
												scaleOfShieldsBarAtZeroShields
													+ (1 - scaleOfShieldsBarAtZeroShields)
														* (playerData.shield or 0)
														/ RoundConfiguration.shieldBaseAmount,
												1
											)
										else
											return UDim2.fromScale(scaleOfShieldsBarAtZeroShields, 1)
										end
									end),
									SliceCenter = Rect.new(127, 0, 173, 0),
									SliceScale = 10,
								},

								scope:New "ImageLabel" {
									Name = "Background",
									AnchorPoint = Vector2.new(0, 1),
									BackgroundTransparency = 1,
									Image = "rbxassetid://7952769553",
									ImageColor3 = Color3.new(),
									ImageTransparency = 0.75,
									Position = UDim2.fromScale(0, 1),
									ScaleType = Enum.ScaleType.Slice,
									Size = UDim2.fromScale(1, 1),
									SliceCenter = Rect.new(127, 0, 173, 0),
									SliceScale = 10,
									ZIndex = 0,
								},
							},
						},

						scope:New "ImageLabel" {
							Name = "Battery",
							BackgroundTransparency = 1,
							Image = "rbxassetid://114349003995827",
							Position = UDim2.fromOffset(-9, -4),
							Size = UDim2.fromOffset(57, 71),
							ZIndex = 2,
						},
					},
				},

				scope:New "Frame" {
					Name = "LifeSupport",
					AnchorPoint = Vector2.new(0, 1),
					BackgroundTransparency = 1,
					Position = scope:Tween(
						scope:Computed(function(use)
							local isLifeSupportGuiEnabled = use(isLifeSupportGuiEnabled)

							if isLifeSupportGuiEnabled then
								return UDim2.fromScale(0, 1)
							else
								return UDim2.fromScale(0, 1)
									+ UDim2.fromOffset(0, OFFSCREEN_HEALTH_LIFESUPPORT_OFFSET)
							end
						end),
						scope:Computed(function(use)
							local isLifeSupportGuiEnabled = use(isLifeSupportGuiEnabled)

							if isLifeSupportGuiEnabled then
								return OFFSCREEN_SLIDEIN_HUDGUI_INFO
							else
								return OFFSCREEN_SLIDEOUT_HUDGUI_INFO
							end
						end)
					),
					Size = UDim2.fromOffset(200, 60),

					[Children] = {
						scope:New "Frame" {
							Name = "LifeSupportBar",
							AnchorPoint = Vector2.new(0, 1),
							BackgroundTransparency = 1,
							LayoutOrder = 1,
							Position = UDim2.fromOffset(0, 45),
							Size = UDim2.fromOffset(192, 32),

							[Children] = {
								scope:New "TextLabel" {
									Name = "Amount",
									AutomaticSize = Enum.AutomaticSize.X,
									BackgroundTransparency = 1,
									FontFace = Font.new(
										"rbxasset://fonts/families/TitilliumWeb.json",
										Enum.FontWeight.Heavy,
										Enum.FontStyle.Normal
									),
									Position = UDim2.fromOffset(48, 0),
									Size = UDim2.fromScale(0, 1),
									Text = scope:Computed(function(use)
										local playerDatas = use(roundData.playerData)
										local playerData = playerDatas[Players.LocalPlayer.UserId]

										if playerData then
											return tostring(math.ceil(playerData.lifeSupport or 0))
										else
											return "0"
										end
									end),
									TextColor3 = Color3.fromRGB(206, 200, 255),
									TextScaled = true,
									TextXAlignment = Enum.TextXAlignment.Left,
									ZIndex = 3,

									[Children] = {
										scope:New "UIPadding" {
											Name = "UIPadding",
											PaddingLeft = UDim.new(0, 6),
										},
									},
								},

								scope:New "ImageLabel" {
									Name = "Background",
									AnchorPoint = Vector2.new(0, 1),
									BackgroundTransparency = 1,
									Image = "rbxassetid://7952769553",
									ImageColor3 = Color3.new(),
									ImageTransparency = 0.75,
									Position = UDim2.fromScale(0, 1),
									ScaleType = Enum.ScaleType.Slice,
									Size = UDim2.fromScale(1, 1),
									SliceCenter = Rect.new(127, 0, 173, 0),
									SliceScale = 10,
									ZIndex = 0,
								},

								scope:New "ImageLabel" {
									Name = "Content",
									AnchorPoint = Vector2.new(0, 1),
									BackgroundTransparency = 1,
									Image = "rbxassetid://7952769553",
									ImageColor3 = Color3.fromRGB(85, 129, 242),
									Position = UDim2.fromScale(0, 1),
									ScaleType = Enum.ScaleType.Slice,
									Size = scope:Computed(function(use)
										local playerDatas = use(roundData.playerData)
										local playerData = playerDatas[Players.LocalPlayer.UserId]

										local scaleOfLifeSupportBarAtZeroLifeSupport = 0.146

										if playerData then
											return UDim2.fromScale(
												scaleOfLifeSupportBarAtZeroLifeSupport
													+ (1 - scaleOfLifeSupportBarAtZeroLifeSupport)
														* (playerData.lifeSupport or 0)
														/ 100,
												1
											)
										else
											return UDim2.fromScale(scaleOfLifeSupportBarAtZeroLifeSupport, 1)
										end
									end),
									SliceCenter = Rect.new(127, 0, 173, 0),
									SliceScale = 10,
								},
							},
						},

						scope:New "ImageLabel" {
							Name = "Battery",
							BackgroundTransparency = 1,
							Image = "rbxassetid://134771512295274",
							Position = UDim2.fromOffset(-9, 2),
							Size = UDim2.fromOffset(43, 54),
							ZIndex = 2,
						},
					},
				},

				scope:New "Frame" {
					Name = "Terminal",
					AnchorPoint = Vector2.new(0.5, 1),
					BackgroundTransparency = 1,
					Position = scope:Tween(
						scope:Computed(function(use)
							local isHacking = use(ClientRoundDataUtility.isHacking)

							if isHacking then
								return UDim2.fromScale(0.5, 1)
							else
								return UDim2.fromScale(0.5, 1)
									+ UDim2.fromOffset(0, OFFSCREEN_HEALTH_LIFESUPPORT_OFFSET)
							end
						end),
						scope:Computed(function(use)
							local isHacking = use(ClientRoundDataUtility.isHacking)

							if isHacking then
								return OFFSCREEN_SLIDEIN_HUDGUI_INFO
							else
								return OFFSCREEN_SLIDEOUT_HUDGUI_INFO
							end
						end)
					),
					Size = UDim2.fromOffset(180, 60),
					ZIndex = 3,
				
					[Children] = {
						scope:New "Frame" {
							Name = "TerminalBar",
							AnchorPoint = Vector2.new(0, 1),
							BackgroundTransparency = 1,
							LayoutOrder = 1,
							Position = UDim2.fromOffset(0, 40),
							Size = UDim2.fromOffset(180, 24),
				
							[Children] = {
								scope:New "ImageLabel" {
									Name = "Background",
									AnchorPoint = Vector2.new(0, 1),
									BackgroundTransparency = 1,
									Image = "rbxassetid://7952769553",
									ImageColor3 = Color3.new(),
									ImageTransparency = 0.75,
									Position = UDim2.fromScale(0, 1),
									ScaleType = Enum.ScaleType.Slice,
									Size = UDim2.fromScale(1, 1),
									SliceCenter = Rect.new(127, 0, 173, 0),
									SliceScale = 10,
									ZIndex = 0,
								},
				
								scope:New "ImageLabel" {
									Name = "Content",
									AnchorPoint = Vector2.new(0, 1),
									BackgroundTransparency = 1,
									Image = "rbxassetid://7952769553",
									ImageColor3 = Color3.fromRGB(127, 214, 250),
									Position = UDim2.fromScale(0, 1),
									ScaleType = Enum.ScaleType.Slice,
									Size = scope:Computed(function(use)
										local terminalData = use(ClientRoundDataUtility.currentHackingTerminal)
										if not terminalData then
											return UDim2.fromScale(0, 1)
										end

										local scaleOfTerminalBarAtZeroProgress = 0.24
										return UDim2.fromScale(
											scaleOfTerminalBarAtZeroProgress
												+ (1 - scaleOfTerminalBarAtZeroProgress)
													* (terminalData.progress or 0)
													/ 100,
											1
										)
									end),
									SliceCenter = Rect.new(127, 0, 173, 0),
									SliceScale = 10,
								},
							}
						},
				
						scope:New "ImageLabel" {
							Name = "TerminalImage",
							BackgroundTransparency = 1,
							Image = "rbxassetid://107341936047436",
							Position = UDim2.fromOffset(-12, -1),
							Size = UDim2.fromOffset(60, 60),
							ZIndex = 2,
						},
				
						scope:New "Frame" {
							Name = "Puzzle",
							AnchorPoint = Vector2.new(0.5, 1),
							BackgroundColor3 = Color3.new(1, 1, 1),
							BackgroundTransparency = 1,
							Position = UDim2.new(0.5, 0, 0, -10),
							Size = UDim2.fromOffset(70, 70),
						},
					}
				}
			},
		},
	},
}

-- Left-side buttons
scope:New "ScreenGui" {
    Name = "MobileControls",
    ClipToDeviceSafeArea = false,
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Enabled = scope:Computed(function(use)
		return use(Platform.mobileButtonVisibilityState).visible
	end),
	Parent = playerGui,

	[Children] = {
		scope:New "Frame" {
			Name = "MobileButtons",
			AnchorPoint = Vector2.new(1, 1),
			BackgroundTransparency = 1,
			Position = scope:Computed(function(use)
				local isSmallScreen = use(Platform.isMobileSmallScreen)
				local jumpButtonSize = use(Platform.mobileButtonVisibilityState).size
				return isSmallScreen and UDim2.new(1, -(jumpButtonSize*0.5-10), 1, - 20) or UDim2.new(1, -(jumpButtonSize*0.5-10), 1, -jumpButtonSize * 0.75)
			end),
			Size = scope:Computed(function(use)
				local jumpButtonSize = use(Platform.mobileButtonVisibilityState).size
				return UDim2.fromOffset(jumpButtonSize, jumpButtonSize)
			end),
		
			[Children] = {
				scope:New "ImageButton" {
					Name = "ParkourButton",
					BackgroundTransparency = 1,
					Image = "rbxassetid://14242992621",
					Position = UDim2.fromScale(-1.1, 0),
					PressedImage = "rbxassetid://14242994214",
					Size = UDim2.fromScale(1, 1),
				},
		
				scope:New "TextButton" {
					Name = "Context",
					AnchorPoint = Vector2.new(0.5, 1),
					BackgroundColor3 = Color3.fromRGB(40, 40, 40),
					BackgroundTransparency = 0.4,
					FontFace = Font.new(
						"rbxasset://fonts/families/TitilliumWeb.json",
						Enum.FontWeight.Bold,
						Enum.FontStyle.Normal
					),
					Position = UDim2.fromScale(-0.05, -0.1),
					Size = UDim2.fromScale(1.4, 0.7),
					Text = scope:Computed(function(use)
						local isHoldingBattery = use(ClientRoundDataUtility.isHoldingBattery)
						local isGunEnabled = use(ClientRoundDataUtility.isGunEnabled)[Players.LocalPlayer.UserId]

						if not isHoldingBattery and not isGunEnabled then
							return ""
						end

						if isHoldingBattery then
							return "DROP"
						end

						if isGunEnabled then
							return "SHOOT"
						end

						return ""
					end),
					TextColor3 = Color3.fromRGB(125, 147, 196),
					TextScaled = true,
					Visible = scope:Computed(function(use)
						local isHoldingBattery = use(ClientRoundDataUtility.isHoldingBattery)
						local isGunEnabled = use(ClientRoundDataUtility.isGunEnabled)[Players.LocalPlayer.UserId]

						return isHoldingBattery or isGunEnabled
					end),
					Active = false,
		
					[Children] = {
						scope:New "UICorner" {
							Name = "UICorner",
							CornerRadius = UDim.new(0.2, 0),
						},
		
						scope:New "UIPadding" {
							Name = "UIPadding",
							PaddingBottom = UDim.new(0.1, 0),
							PaddingLeft = UDim.new(0.1, 0),
							PaddingRight = UDim.new(0.1, 0),
							PaddingTop = UDim.new(0.1, 0),
						},
					}
				},
			}
		}
	}
}