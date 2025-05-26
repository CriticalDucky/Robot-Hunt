-- Roblox Parkour Movement System v4.6-r4 (Delivery Edition)
--------------------------------------------------------------------
--  SERVICES & SHORTCUTS
--------------------------------------------------------------------
local Players, RunService = game:GetService "Players", game:GetService "RunService"
local UserInputService = game:GetService "UserInputService"
local CAS = game:GetService "ContextActionService"
local Workspace = game:GetService "Workspace"
local SoundService = game:GetService "SoundService"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

-- Delivery place specific dependencies
local ClientState = require(ReplicatedStorage:WaitForChild("Data"):WaitForChild "ClientState")
local Enums = require(ReplicatedFirst.Enums)
local ParkourState = Enums.ParkourState
local parkourState = ClientState.actions.parkourState
local RoundConfig = require(ReplicatedStorage:WaitForChild("Configuration"):WaitForChild "RoundConfiguration")
local Platform = require(ReplicatedFirst:WaitForChild("Utility"):WaitForChild("Platform"))
local Fusion = require(ReplicatedFirst:WaitForChild("Vendor"):WaitForChild "Fusion")
local scope = Fusion.scoped(Fusion)
local peek = Fusion.peek

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild "PlayerGui"
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild "Humanoid"
local HRP = Character:WaitForChild "HumanoidRootPart"
local UpperTorso = Character:WaitForChild "UpperTorso"
local Head = Character:WaitForChild "Head"

--------------------------------------------------------------------
--  ANIMATIONS
--------------------------------------------------------------------
local AnimIds = {
	Roll = "rbxassetid://132857544330790",
	Dive = "rbxassetid://80794143376440",
	Jump = "rbxassetid://121811864551864",
}
local Anim = {}
for n, id in pairs(AnimIds) do
	local a = Instance.new "Animation"
	a.Name, a.AnimationId = n, id
	Anim[n] = Humanoid:LoadAnimation(a)
end

--------------------------------------------------------------------
--  SOUNDS
--------------------------------------------------------------------
local Sounds = {}
for _, n in ipairs { "bounce", "dive", "doublejump", "jump", "roll" } do
	local s = HRP:FindFirstChild(n)
	if s and s:IsA "Sound" then Sounds[n] = s end
end
local function play(tag)
	if Sounds[tag] then SoundService:PlayLocalSound(Sounds[tag]) end
end

--------------------------------------------------------------------
--  CONSTANTS
--------------------------------------------------------------------
local BASE_WALK_SPEED = RoundConfig.walkSpeed
local JUMP_POWER = RoundConfig.jumpPower
local DOUBLE_JUMP_POWER = 45
local DIVE_FORCE = 35
local DIVE_UPWARD_NUDGE = 40
local DIVE_MIN_HEIGHT = 3
local ROLL_SPEED_MULTIPLIER = 2.1
local ROLL_DURATION = 0.45
local DIVE_OBSTACLE_DIST = 2
local ROLL_OBSTACLE_DIST = 1.0
local DIVE_END_BUFFER = 0.3
local TERRAIN_VOXEL_SIZE = 4
local GROUND_LOCK_TIME = 0.20 -- grace air-lock after ladder / water exit

--------------------------------------------------------------------
--  STATE
--------------------------------------------------------------------
local currentState = ParkourState.grounded
local hasDoubleJumped, hasDived = false, false
local isDiving, isRolling = false, false
local stateDebounce = false
local rollDir, rollStartTime = Vector3.zero, 0

local fluidExitGrace = false -- first jump treated as grounded
local groundLockUntil = 0 -- ignore ground contact until this time
local jumpHeld = false -- gate against key-repeat

local function ResetAirFlags()
	hasDoubleJumped, hasDived = false, false
end

local playerState = scope:Computed(function(use)
	local playerData = use(ClientState.external.roundData.playerData)[Player.UserId]

	if not playerData then return end

	return playerData.status
end)

--------------------------------------------------------------------
--  DEBUG GUI (restored)
--------------------------------------------------------------------
local function EnsureDebugGui()
	if not Player:FindFirstChild "PlayerGui" then return end
	local gui = Player.PlayerGui:FindFirstChild "ParkourDebug"
	if gui then return gui end
	gui = Instance.new("ScreenGui", Player.PlayerGui)
	gui.Name = "ParkourDebug"
	local t = Instance.new("TextLabel", gui)
	t.Name = "StateText"
	t.Size = UDim2.fromOffset(340, 150)
	t.BackgroundTransparency = 0.4
	t.BackgroundColor3 = Color3.new()
	t.TextColor3 = Color3.new(1, 1, 1)
	t.Font = Enum.Font.Code
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.TextYAlignment = Enum.TextYAlignment.Top
	return gui
end

--------------------------------------------------------------------
--  UTILITY
--------------------------------------------------------------------
local function FeetRay(d)
	local origin = HRP.Position - Vector3.new(0, Humanoid.HipHeight + HRP.Size.Y * 0.5, 0)
	local p = RaycastParams.new()
	p.FilterDescendantsInstances = { Character }
	p.FilterType = Enum.RaycastFilterType.Exclude
	-- Set collision filter to respect collision groups
	p.CollisionGroup = "Character"

	local result = Workspace:Raycast(origin, Vector3.new(0, -d, 0), p)
	-- Check if the hit part can actually collide with the player
	if result and result.Instance then
		-- Ignore parts with CanCollide set to false
		if not result.Instance.CanCollide then return nil end
	end
	return result
end
local function IsHighEnoughForDive() return not FeetRay(DIVE_MIN_HEIGHT) end
local function GroundIsClose() return FeetRay(DIVE_END_BUFFER) end

local function ForwardHit(origin, dist)
	local p = RaycastParams.new()
	p.FilterDescendantsInstances = { Character }
	p.FilterType = Enum.RaycastFilterType.Exclude
	-- Set collision filter to respect collision groups
	p.CollisionGroup = "Character"

	local result = Workspace:Raycast(origin, HRP.CFrame.LookVector * dist, p)
	-- Check if the hit part can actually collide with the player
	if result and result.Instance then
		-- Ignore parts with CanCollide set to false
		if not result.Instance.CanCollide then return nil end
	end
	return result
end
local function TerrainWaterCheck()
	local t, h = Workspace.Terrain, TERRAIN_VOXEL_SIZE * 0.5
	local region = Region3.new(HRP.Position - Vector3.new(h, h, h), HRP.Position + Vector3.new(h, h, h))
		:ExpandToGrid(TERRAIN_VOXEL_SIZE)
	for _, col in ipairs(t:ReadVoxels(region, TERRAIN_VOXEL_SIZE)) do
		for _, row in ipairs(col) do
			for _, mat in ipairs(row) do
				if mat == Enum.Material.Water then return true end
			end
		end
	end
	return false
end
-- Use Humanoid state for ground detection
local function IsGrounded()
	if tick() < groundLockUntil then return false end
	local st = Humanoid:GetState()
	return st == Enum.HumanoidStateType.Running or st == Enum.HumanoidStateType.Landed
end
local function InFluid() return currentState == ParkourState.climb or currentState == ParkourState.swim end

local function isParkourEnabled()
	local playerData = peek(ClientState.external.roundData.playerData)[Player.UserId]
	if not playerData then return true end

	if peek(playerState) == Enums.PlayerStatus.lifeSupport and not playerData.isLobby then
		return false
	end

	return true
end

--------------------------------------------------------------------
--  HUMANOID STATE CHANGES
--------------------------------------------------------------------
Humanoid.StateChanged:Connect(function(old, new)
	-- Stop roll or dive if we start Climbing
	if new == Enum.HumanoidStateType.Climbing then
		if isRolling then
			isRolling, stateDebounce = false, false
			Humanoid.WalkSpeed = BASE_WALK_SPEED
			HRP.CanCollide, UpperTorso.CanCollide = true, true
			Anim.Roll:Stop()
		end
		if isDiving then
			isDiving = false
			Humanoid.AutoRotate, HRP.CanCollide = true, true
			Anim.Dive:Stop()
		end
		currentState = ParkourState.climb
		return
	end

	-- Stop a dive the instant we actually land
	if isDiving and (new == Enum.HumanoidStateType.Landed or new == Enum.HumanoidStateType.Running) then
		isDiving = false
		Humanoid.AutoRotate, HRP.CanCollide = true, true
		Anim.Dive:Stop()
		currentState = ParkourState.grounded
		ResetAirFlags()
		return
	end

	if old == Enum.HumanoidStateType.Climbing and currentState == ParkourState.climb then
		currentState, fluidExitGrace = ParkourState.jump, true
		ResetAirFlags()
	end

	-- Reset fluid exit grace when we land
	if
		(old == Enum.HumanoidStateType.Freefall or old == Enum.HumanoidStateType.Jumping)
		and (new == Enum.HumanoidStateType.Running or new == Enum.HumanoidStateType.Landed)
	then
		fluidExitGrace = false
	end
end)

--------------------------------------------------------------------
--  ACTION HELPERS
--------------------------------------------------------------------
local function StopDive(bounce)
	if not isDiving then return end
	isDiving = false
	Humanoid.AutoRotate, HRP.CanCollide = true, true
	Anim.Dive:Stop()
	if bounce then play "bounce" end
	HRP.AssemblyLinearVelocity = Vector3.new(0, HRP.AssemblyLinearVelocity.Y, 0)
	currentState = ParkourState.jump
end
local function StartDive()
	if InFluid() or stateDebounce or isDiving or hasDived then return end
	if (currentState == ParkourState.jump or currentState == ParkourState.double) and IsHighEnoughForDive() then
		isDiving, hasDived = true, true
		currentState = ParkourState.dive
		Humanoid.AutoRotate, HRP.CanCollide = false, false
		local f = HRP.CFrame.LookVector.Unit * DIVE_FORCE
		HRP.Velocity = Vector3.new(f.X, DIVE_UPWARD_NUDGE, f.Z)
		play "dive"
		Anim.Dive:Play()
	end
end
local function StopRoll(bounce)
	if not isRolling then return end
	isRolling, stateDebounce = false, false
	Humanoid.WalkSpeed = BASE_WALK_SPEED
	HRP.CanCollide, UpperTorso.CanCollide = true, true
	Anim.Roll:Stop()
	if bounce then play "bounce" end
	currentState = ParkourState.jump
end
local function StartRoll()
	if InFluid() or stateDebounce or isRolling or currentState ~= ParkourState.grounded then return end
	stateDebounce, isRolling = true, true
	currentState = ParkourState.roll
	Humanoid.WalkSpeed = 0
	HRP.CanCollide, UpperTorso.CanCollide = false, false
	rollDir, rollStartTime = HRP.CFrame.LookVector.Unit, tick()
	play "roll"
	Anim.Roll:Play()
	HRP.Velocity = Vector3.new(
		rollDir.X * BASE_WALK_SPEED * ROLL_SPEED_MULTIPLIER,
		HRP.AssemblyLinearVelocity.Y,
		rollDir.Z * BASE_WALK_SPEED * ROLL_SPEED_MULTIPLIER
	)
end

--------------------------------------------------------------------
--  JUMP
--------------------------------------------------------------------
local function Jump()
	if currentState == ParkourState.swim then return end
	if isRolling then
		StopRoll(false)
		local air = not IsGrounded()
		HRP.Velocity = Vector3.new(HRP.Velocity.X, air and DOUBLE_JUMP_POWER or JUMP_POWER, HRP.Velocity.Z)
		if air then
			hasDoubleJumped, currentState = true, ParkourState.double
			play "doublejump"
			Anim.Jump:Play()
		else
			currentState = ParkourState.jump
			play "jump"
			groundLockUntil = tick() + GROUND_LOCK_TIME
		end
		return
	end
	if fluidExitGrace then
		fluidExitGrace = false
		groundLockUntil = tick() + GROUND_LOCK_TIME
		HRP.Velocity = Vector3.new(HRP.Velocity.X, JUMP_POWER, HRP.Velocity.Z)
		-- Fix for triple-jump bug - properly set hasDoubleJumped to prevent additional jumping
		hasDoubleJumped = true
		currentState = ParkourState.double
		play "doublejump"
		Anim.Jump:Play()
		return
	end
	if InFluid() or stateDebounce then return end
	if currentState == ParkourState.grounded then
		groundLockUntil = 0
		HRP.Velocity = Vector3.new(HRP.Velocity.X, JUMP_POWER, HRP.Velocity.Z)
		currentState = ParkourState.jump
		ResetAirFlags()
		play "jump"
	elseif currentState == ParkourState.jump and not hasDoubleJumped then
		HRP.Velocity = Vector3.new(HRP.Velocity.X, DOUBLE_JUMP_POWER, HRP.Velocity.Z)
		currentState, hasDoubleJumped = ParkourState.double, true
		play "doublejump"
		Anim.Jump:Play()
	elseif currentState == ParkourState.dive and not hasDoubleJumped then
		StopDive(false)
		HRP.Velocity = Vector3.new(HRP.Velocity.X, DOUBLE_JUMP_POWER, HRP.Velocity.Z)
		currentState, hasDoubleJumped = ParkourState.double, true
		play "doublejump"
		Anim.Jump:Play()
	end
end

--------------------------------------------------------------------
--  INPUT / ROLL-DIVE BINDING
--------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(inp, gp)
	if isParkourEnabled() == false then return end
	if gp then return end
	if inp.KeyCode == Enum.KeyCode.Space or inp.KeyCode == Enum.KeyCode.ButtonA then
		if not jumpHeld then
			jumpHeld = true
			Jump()
		end
	end
end)
UserInputService.InputEnded:Connect(function(inp, gp)
	if gp then return end
	if inp.KeyCode == Enum.KeyCode.Space or inp.KeyCode == Enum.KeyCode.ButtonA then jumpHeld = false end
end)

-- Connect to mobile jump button if it exists
Platform.onJumpButtonPressed:Connect(function(state)
	if isParkourEnabled() == false then return end
	if state == Enum.UserInputState.Begin then
		if not jumpHeld then
			jumpHeld = true
			Jump()
		end
	else
		jumpHeld = false
	end
end)

CAS:BindAction("RollDive", function(_, st)
	if st ~= Enum.UserInputState.Begin then return end
	if InFluid() then return end
	if isParkourEnabled() == false then return end
	if IsGrounded() then
		StartRoll()
	else
		StartDive()
	end
end, false, Enum.KeyCode.LeftShift, Enum.KeyCode.RightShift, Enum.KeyCode.ButtonB)

--------------------------------------------------------------------
--  MOBILE & CONSOLE SUPPORT
--------------------------------------------------------------------
local function hookMobileButton()
	if not UserInputService.TouchEnabled then return end

	local gui = Player:WaitForChild("PlayerGui"):WaitForChild("MobileControls", 5)
	if not gui then return end

	local btn = gui:WaitForChild("MobileButtons", 2)
	if not btn then return end

	btn = btn:WaitForChild("ParkourButton", 2)
	if not btn then return end

	btn.MouseButton1Down:Connect(function()
		if isParkourEnabled() == false then return end

		if InFluid() then return end
		if IsGrounded() then
			StartRoll()
		else
			StartDive()
		end
	end)
end

--------------------------------------------------------------------
--  HEARTBEAT LOOP
--------------------------------------------------------------------
RunService.Heartbeat:Connect(function()
	local inWater = TerrainWaterCheck()
	if inWater and currentState ~= ParkourState.swim then
		StopRoll(false)
		StopDive(false)
		currentState = ParkourState.swim
	elseif not inWater and currentState == ParkourState.swim then
		currentState, fluidExitGrace = ParkourState.jump, true
		ResetAirFlags()
	end

	if isDiving and GroundIsClose() then StopDive(false) end

	if not InFluid() then
		if IsGrounded() and currentState ~= ParkourState.roll then
			if currentState ~= ParkourState.grounded then
				currentState = ParkourState.grounded
				ResetAirFlags()
				StopDive(false)
				-- Reset fluid exit grace when landing on ground
				fluidExitGrace = false
			end
		elseif not IsGrounded() and currentState == ParkourState.grounded then
			currentState = ParkourState.jump
		end
	end

	if isRolling then
		local hit = ForwardHit(HRP.Position - Vector3.new(0, 2, 0), ROLL_OBSTACLE_DIST)
		local timeout = tick() - rollStartTime >= ROLL_DURATION
		if (hit and hit.Normal.Y <= 0.4) or timeout then
			local bounce = hit and hit.Material ~= Enum.Material.Water
			StopRoll(bounce)
			if hit and hit.Material == Enum.Material.Water then currentState = ParkourState.swim end
		else
			local vy = HRP.AssemblyLinearVelocity.Y
			HRP.CFrame = CFrame.new(HRP.Position, HRP.Position + rollDir)
			HRP.Velocity = Vector3.new(
				rollDir.X * BASE_WALK_SPEED * ROLL_SPEED_MULTIPLIER,
				vy,
				rollDir.Z * BASE_WALK_SPEED * ROLL_SPEED_MULTIPLIER
			)
		end
	end

	if isDiving then
		local hit = ForwardHit(Head.Position, DIVE_OBSTACLE_DIST)
		if hit and hit.Normal.Y <= 0.4 then
			local bounce = hit.Material ~= Enum.Material.Water
			StopDive(bounce)
			if hit.Material == Enum.Material.Water then currentState = ParkourState.swim end
		else
			local dv = HRP.CFrame.LookVector.Unit * DIVE_FORCE
			HRP.Velocity = Vector3.new(dv.X, HRP.Velocity.Y, dv.Z)
		end
	end

	-- local gui = EnsureDebugGui()
	-- if gui then
	-- 	gui.StateText.Text = string.format(
	-- 		"State: %s\nHumState: %s\nGrounded: %s\nWater: %s\nGrace: %s\nDoubleJ: %s\nRolling: %s\nDiving: %s",
	-- 		currentState,
	-- 		tostring(Humanoid:GetState()),
	-- 		tostring(IsGrounded()),
	-- 		tostring(inWater),
	-- 		tostring(fluidExitGrace),
	-- 		tostring(hasDoubleJumped),
	-- 		tostring(isRolling),
	-- 		tostring(isDiving)
	-- 	)
	-- end

	-- Update the client state
	parkourState:set(currentState)
end)

-- Handle character removal - reset parkour state
Player.CharacterRemoving:Connect(function() parkourState:set(ParkourState.grounded) end)

-- Run the hook once the PlayerGui hierarchy exists
if Player:FindFirstChild "PlayerGui" then
	hookMobileButton()
else
	Player.CharacterAdded:Wait() -- safety for edge cases
	task.spawn(hookMobileButton)
end
