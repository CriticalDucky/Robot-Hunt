--[[
    PlatformDetector Module
    
    This module provides functions to reliably determine a user's platform and predict
    whether the jump button is enabled for their current platform/device.
]]

local PlatformDetector = {}

-- Services
local Players = game:GetService "Players"
local UserInputService = game:GetService "UserInputService"
local GuiService = game:GetService "GuiService"
local ReplicatedFirst = game:GetService "ReplicatedFirst"

local utilityFolder = ReplicatedFirst:WaitForChild("Utility")

-- Modules

local Enums = require(ReplicatedFirst:WaitForChild("Enums"))
local CameraState = require(utilityFolder:WaitForChild("CameraState"))
local Fusion = require(ReplicatedFirst:WaitForChild("Vendor"):WaitForChild("Fusion"))
local peek = Fusion.peek

local scope = Fusion:scoped()

-- Cache the current platform once determined
local _currentPlatform = nil
local _isJumpButtonEnabled = nil
local _jumpButtonHooked = false

PlatformDetector.jumpButtonPressedEvent = Instance.new("BindableEvent")
PlatformDetector.mobileButtonVisibilityChangedEvent = Instance.new("BindableEvent")
PlatformDetector.platformChangedEvent = Instance.new("BindableEvent")

PlatformDetector.onPlatformChanged = PlatformDetector.platformChangedEvent.Event :: RBXScriptSignal<typeof(Enums.PlatformType.Unknown)>
PlatformDetector.onMobileButtonVisibilityChanged = PlatformDetector.mobileButtonVisibilityChangedEvent.Event :: RBXScriptSignal<boolean, number>
PlatformDetector.onJumpButtonPressed = PlatformDetector.jumpButtonPressedEvent.Event :: RBXScriptSignal<Enum.UserInputState>

PlatformDetector.mobileButtonVisibilityState = scope:Value({visible = false, size = 0}) :: Fusion.Value<{visible: boolean, size: number}>
PlatformDetector.isMobileSmallScreen = scope:Computed(function(use)
	local screenSize = use(CameraState).ViewportSize
	if not screenSize then return true end
	local minAxis = math.min(screenSize.X, screenSize.Y)
	return minAxis <= 500
end)
PlatformDetector.platform = scope:Value(Enums.PlatformType.Unknown) :: Fusion.Value<typeof(Enums.PlatformType.Unknown)>

function attemptHookJumpButton()
	local Players = game:GetService("Players")
	local TG = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("TouchGui", 2)
		
	if not TG then return end
		
	local TCF = TG:WaitForChild("TouchControlFrame", 2)
	
	if not TCF then return end
	
	local jumpButton = TCF:WaitForChild("JumpButton", 2)

	local function startedToHold()
		PlatformDetector.jumpButtonPressedEvent:Fire(Enum.UserInputState.Begin)
	end

	local function released()
		PlatformDetector.jumpButtonPressedEvent:Fire(Enum.UserInputState.End)
	end

	jumpButton.MouseButton1Down:Connect(startedToHold)
	jumpButton.MouseButton1Up:Connect(released)
	
	_jumpButtonHooked = true
end

-- Determine if the player is on a touch device (mobile)
local function isTouchDevice()
	return UserInputService.TouchEnabled
		and not UserInputService.KeyboardEnabled
		and not UserInputService.GamepadEnabled
end

-- Determine if the player is on a PC
local function isPC()
	return UserInputService.KeyboardEnabled and not UserInputService.TouchEnabled and not UserInputService.VREnabled
end

-- Determine if the player is on a console
local function isConsole()
    if GuiService:IsTenFootInterface() then -- According to Roblox documentation, this is a reliable way to check for console
        return true
    end

	return UserInputService.GamepadEnabled
		and not UserInputService.KeyboardEnabled
		and not UserInputService.TouchEnabled
end

-- Determine if the player is using VR
local function isVR() return UserInputService.VREnabled end

-- Determine the user's platform with multiple checks for reliability
function PlatformDetector:GetPlatform()
	-- Return cached result if available
	if _currentPlatform then return _currentPlatform end

	-- Determine platform through multiple checks for reliability
	local previousPlatform = _currentPlatform -- Cache the previous platform
	if isVR() then
		_currentPlatform = Enums.PlatformType.VR
	elseif isTouchDevice() then
		_currentPlatform = Enums.PlatformType.Mobile
	elseif isConsole() then
		_currentPlatform = Enums.PlatformType.Console
	elseif isPC() then
		_currentPlatform = Enums.PlatformType.PC
	else
		-- Additional fallback detection methods
		local screenSize = peek(CameraState).ViewportSize

		if not screenSize then
			_currentPlatform = Enums.PlatformType.Unknown
			return _currentPlatform
		end

		-- Small screens are likely mobile devices
		if screenSize.X < 800 or screenSize.Y < 600 then
			_currentPlatform = Enums.PlatformType.Mobile
		else
			_currentPlatform = Enums.PlatformType.Unknown
		end
	end

	-- Trigger the platform changed event if the platform has changed
	if previousPlatform ~= _currentPlatform then
		PlatformDetector.platformChangedEvent:Fire(_currentPlatform)
	end

	-- Update the platform value in Fusion
	PlatformDetector.platform:set(_currentPlatform)

	return _currentPlatform
end

-- Refresh the cached values (useful when something might have changed)
function PlatformDetector:Refresh()
	_currentPlatform = nil
	_isJumpButtonEnabled = nil
	return self:GetPlatform()
end

-- Returns if the current platform shows touch controls
function PlatformDetector:HasTouchControls()
	local platform = self:GetPlatform()
	return platform == Enums.PlatformType.Mobile
end

-- Returns if the current platform uses keyboard for movement
function PlatformDetector:UsesKeyboardMovement()
	local platform = self:GetPlatform()
	return platform == Enums.PlatformType.PC
end

-- Function to get the mobile button visibility and size
function PlatformDetector:GetMobileButtonVisibilityAndSize()
	local platform = self:GetPlatform()
	if platform == Enums.PlatformType.Mobile then
		local screenSize = peek(CameraState).ViewportSize
		if not screenSize then return false, 0 end
		local minAxis = math.min(screenSize.X, screenSize.Y)
		local isSmallScreen = minAxis <= 500 -- Is the screen too small for big mobile buttons?
		local jumpButtonSize = isSmallScreen and 70 or 120 -- Determine the size of the jump button.
		return true, jumpButtonSize
	else
		return false, 0
	end
end

-- Listen for potential platform changes (rare but possible)
local function setupPlatformChangeListeners()
	-- Listen for input type changes that might indicate a platform change
	UserInputService.LastInputTypeChanged:Connect(function(typ)
		local previousPlatform = _currentPlatform
		PlatformDetector:Refresh()
		if previousPlatform ~= _currentPlatform then
			PlatformDetector.platformChangedEvent:Fire(_currentPlatform)
		end

		if _currentPlatform == Enums.PlatformType.Mobile and not _jumpButtonHooked then
			attemptHookJumpButton()
		end
	end)

	local currentPlatform = PlatformDetector:GetPlatform()
	if currentPlatform == Enums.PlatformType.Mobile and not _jumpButtonHooked then
		attemptHookJumpButton()
	end
end

-- Initialize the module
setupPlatformChangeListeners()
PlatformDetector:Refresh() -- Call to set the initial platform

-- Listen for mobile button visibility changes
local function handleMobileButtonVisibility()
	local isVisible, buttonSize = PlatformDetector:GetMobileButtonVisibilityAndSize()
	PlatformDetector.mobileButtonVisibilityChangedEvent:Fire(isVisible, buttonSize)
	PlatformDetector.mobileButtonVisibilityState:set({visible = isVisible, size = buttonSize})
end

PlatformDetector.onPlatformChanged:Connect(handleMobileButtonVisibility)
scope:Observer(scope:Computed(function(use)
	local viewportSize = use(CameraState).ViewportSize
	return viewportSize
end)):onChange(handleMobileButtonVisibility)

handleMobileButtonVisibility() -- Initial call to set the mobile button visibility

return PlatformDetector

