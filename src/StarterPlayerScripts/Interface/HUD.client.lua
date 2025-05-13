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
	Name = "HUD",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = playerGui,

	[Children] = {
		scope:New "Frame" {
			Name = "HUD",
			AnchorPoint = Vector2.new(0.5, 1),
			BackgroundTransparency = 1,
			Position = UDim2.new(0.5, 0, 1, -20),
			Size = UDim2.new(1, -400, 0, 70),

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
			},
		},
	},
}
