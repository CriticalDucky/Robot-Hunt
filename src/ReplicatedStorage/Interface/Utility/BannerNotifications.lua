--#region Imports
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local Players = game:GetService "Players"

local replicatedFirstVendor = ReplicatedFirst:WaitForChild "Vendor"

-- Optional: Remove imports that you don't need
local Fusion = require(replicatedFirstVendor:WaitForChild "Fusion")

type UsedAs<T> = Fusion.UsedAs<T>
--#endregion

--#region Constants
local TWEEN_INFO = {
	BANNER_SLIDE = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	TITLE_FADE = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	INFO_FADE = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	FADE_OUT = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
}

local TIMING = {
	TITLE_DELAY = 0.2,
	INFO_DELAY = 0.3,
	DISPLAY_TIME = 4,
}

local POSITIONS = {
	BANNER_START = UDim2.fromOffset(0, 100),
	BANNER_END = UDim2.fromOffset(0, 80),
	BANNER_EXIT = UDim2.fromOffset(0, 100),
}
--#endregion

local scope = Fusion:scoped()
local Children = Fusion.Children

local player = Players.LocalPlayer
local playerGui = player:WaitForChild "PlayerGui"

-- State values
local activeBanner = scope:Value(false)
local bannerGoalPosition = scope:Value(POSITIONS.BANNER_START)
local bannerGoalTransparency = scope:Value(1)
local titleGoalTransparency = scope:Value(1)
local infoGoalTransparency = scope:Value(1)
local titleText = scope:Value("")
local infoText = scope:Value("")
local titleTextColor = scope:Value(Color3.fromRGB(214, 249, 142))

-- Add new computed value for title position
local titlePosition = scope:Computed(function(use)
    return UDim2.new(0.5, 0, 0, if use(infoText) == "" then 28 else 16)
end)

-- Tween values
local bannerPosition = scope:Tween(bannerGoalPosition, TWEEN_INFO.BANNER_SLIDE)
local bannerTransparency = scope:Tween(bannerGoalTransparency, TWEEN_INFO.BANNER_SLIDE)
local titleTransparency = scope:Tween(titleGoalTransparency, TWEEN_INFO.TITLE_FADE)
local infoTransparency = scope:Tween(infoGoalTransparency, TWEEN_INFO.INFO_FADE)

local queue: { { id: string, title: string, displayTime: number, info: string?, priority: boolean, titleColor: Color3? } } = {}
local currentNotificationId = nil
local processingQueue = false

local function processNextNotification()
	if processingQueue or #queue == 0 then return end
	
	processingQueue = true
	local notification = table.remove(queue, 1)
	currentNotificationId = notification.id
	
	-- Set text content and color
	titleText:set(notification.title)
	titleTextColor:set(notification.titleColor)
	infoText:set(notification.info or "")
	
	-- Reset states
	bannerGoalPosition:set(POSITIONS.BANNER_START)
	bannerGoalTransparency:set(1)
	titleGoalTransparency:set(1)
	infoGoalTransparency:set(1)
	activeBanner:set(true)
	
	-- Slide in banner
	task.delay(0, function()
		bannerGoalPosition:set(POSITIONS.BANNER_END)
		bannerGoalTransparency:set(0.75)
	end)
	
	-- Fade in title
	task.delay(TIMING.TITLE_DELAY, function()
		if currentNotificationId ~= notification.id then return end
		titleGoalTransparency:set(0)
	end)
	
	-- Fade in info
	task.delay(TIMING.INFO_DELAY, function()
		if currentNotificationId ~= notification.id then return end
		infoGoalTransparency:set(0)
	end)

	if not notification.displayTime or notification.displayTime <= 0 then
		return -- The user wants indefinite display time, so we don't set a timer
	end
	
	-- Start exit sequence after display time
	task.delay(notification.displayTime, function()
		if currentNotificationId ~= notification.id then return end
		
		-- Fade out everything
		bannerGoalPosition:set(POSITIONS.BANNER_EXIT)
		bannerGoalTransparency:set(1)
		titleGoalTransparency:set(1)
		infoGoalTransparency:set(1)
		
		-- Reset after fade out
		task.delay(TWEEN_INFO.FADE_OUT.Time, function()
			if currentNotificationId ~= notification.id then return end
			activeBanner:set(false)
			currentNotificationId = nil
			processingQueue = false
			
			-- Process next notification if available
			task.delay(0, processNextNotification)
		end)
	end)
end

scope:New "ScreenGui" {
	Name = "BannerNotifications",
	IgnoreGuiInset = true,
	ScreenInsets = Enum.ScreenInsets.None,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	ResetOnSpawn = false,
	Parent = playerGui,

	[Children] = {
		scope:New "Frame" {
			Name = "Banner",
			BackgroundColor3 = Color3.new(),
			BackgroundTransparency = bannerTransparency,
			BorderColor3 = Color3.new(),
			BorderSizePixel = 0,
			Position = bannerPosition,
			Size = UDim2.new(1, 0, 0, 80),
			Visible = activeBanner,

			[Children] = {
				scope:New "UIGradient" {
					Name = "UIGradient",
					Rotation = 90,
					Transparency = NumberSequence.new {
						NumberSequenceKeypoint.new(0, 1),
						NumberSequenceKeypoint.new(0.125, 0),
						NumberSequenceKeypoint.new(0.875, 0),
						NumberSequenceKeypoint.new(1, 1),
					},
				},

				scope:New "TextLabel" {
					Name = "Title",
					AnchorPoint = Vector2.new(0.5, 0),
					BackgroundTransparency = 1,
					FontFace = Font.new(
						"rbxasset://fonts/families/TitilliumWeb.json",
						Enum.FontWeight.Heavy,
						Enum.FontStyle.Normal
					),
					Position = titlePosition,
					Size = UDim2.new(1, 0, 0, 25),
					Text = titleText,
					TextColor3 = titleTextColor,
					TextSize = 48,
					TextTransparency = titleTransparency,
					RichText = true,

					[Children] = {
						scope:New "UIStroke" {
							Name = "UIStroke",
							Color = Color3.fromRGB(106, 70, 23),
							Enabled = false,
							Thickness = 2,
						},
					},
				},

				scope:New "TextLabel" {
					Name = "Info",
					AnchorPoint = Vector2.new(0.5, 0),
					BackgroundTransparency = 1,
					FontFace = Font.new(
						"rbxasset://fonts/families/TitilliumWeb.json",
						Enum.FontWeight.Bold,
						Enum.FontStyle.Normal
					),
					Position = UDim2.new(0.5, 0, 0, 40),
					Size = UDim2.new(1, 0, 0, 25),
					Text = infoText,
					TextColor3 = Color3.fromRGB(239, 251, 249),
					TextSize = 24,
					TextTransparency = infoTransparency,
					RichText = true,

					[Children] = {
						scope:New "UIStroke" {
							Name = "UIStroke",
							Color = Color3.fromRGB(106, 70, 23),
							Enabled = false,
							Thickness = 2,
						},
					},
				},
			},
		},
	},
}

local BannerNotifications = {}

function BannerNotifications.addToQueue(displayTime: number, title: string, info: string?, titleColor: Color3?, priority: boolean?): string
	local id = game:GetService("HttpService"):GenerateGUID(false)
	local notification = { 
		id = id, 
		title = title, 
		displayTime = displayTime,
		info = info or "", 
		titleColor = titleColor or Color3.fromRGB(214, 249, 142),
		priority = priority
	}

	if priority then
		table.insert(queue, 1, notification)
	else
		table.insert(queue, notification)
	end
	
	-- Start processing if not already running
	task.delay(0, processNextNotification)
	
	return id
end

function BannerNotifications.cancelAll()
	queue = {}
	if currentNotificationId then
		local oldId = currentNotificationId
		currentNotificationId = nil
		
		-- Force hide everything
		bannerGoalPosition:set(POSITIONS.BANNER_EXIT)
		bannerGoalTransparency:set(1)
		titleGoalTransparency:set(1)
		infoGoalTransparency:set(1)
		
		task.delay(TWEEN_INFO.FADE_OUT.Time, function()
			if oldId == currentNotificationId then return end
			activeBanner:set(false)
			processingQueue = false
		end)
	end
end

function BannerNotifications.cancelNotification(id: string)
	-- Remove from queue if present
	for i, notification in ipairs(queue) do
		if notification.id == id then
			table.remove(queue, i)
			break
		end
	end
	
	-- Cancel active notification if it matches
	if currentNotificationId == id then
		BannerNotifications.cancelAll()
	end
end

return BannerNotifications