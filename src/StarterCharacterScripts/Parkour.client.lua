-- Roblox Parkour Movement System
-- v3.8 – obstacle-ray tweaks (head-level dive, shorter roll ray) + local SFX

local Players, RunService = game:GetService "Players", game:GetService "RunService"
local UserInputService = game:GetService "UserInputService"
local CAS = game:GetService "ContextActionService"
local Workspace = game:GetService "Workspace"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local ClientState = require(ReplicatedStorage:WaitForChild("Data"):WaitForChild "ClientState")
local Enums = require(ReplicatedFirst.Enums)
local ParkourState = Enums.ParkourState

local parkourState = ClientState.actions.parkourState

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild "Humanoid"
local HRP = Character:WaitForChild "HumanoidRootPart"
local UpperTorso = Character:WaitForChild "UpperTorso"
local Head = Character:WaitForChild "Head"

-- animations
local AnimIds = {
	Roll = "rbxassetid://132857544330790",
	Dive = "rbxassetid://80794143376440",
	Jump = "rbxassetid://121811864551864",
}
local Anim = {}
for k, id in pairs(AnimIds) do
	local a = Instance.new "Animation"
	a.Name, a.AnimationId = k, id
	Anim[k] = Humanoid:LoadAnimation(a)
end

-- local sounds (pre-placed under HRP)
local Sounds = {}
for _, n in ipairs { "bounce", "dive", "doublejump", "jump", "roll" } do
	local s = HRP:FindFirstChild(n)
	if s and s:IsA "Sound" then Sounds[n] = s end
end

-- tuning
local BASE_WALK_SPEED = 16
local JUMP_POWER = 50
local DOUBLE_JUMP_POWER = 45
local DIVE_FORCE = 35
local DIVE_UPWARD_NUDGE = 40
local DIVE_MIN_HEIGHT = 3
local ROLL_SPEED_MULTIPLIER = 2.1
local ROLL_SPEED = BASE_WALK_SPEED * ROLL_SPEED_MULTIPLIER
local ROLL_DURATION = 0.45
local DIVE_OBSTACLE_DIST = 2 -- forward ray length while diving
local ROLL_OBSTACLE_DIST = 1.0 -- shorter ray while rolling
local DIVE_END_BUFFER = 0.3

local currentState = ParkourState.grounded
local hasDoubleJumped, hasDived = false, false
local isDiving, isRolling, stateDebounce, jumpDebounce = false, false, false, false
local rollDir, rollStartTime = Vector3.zero, 0

local function IsGrounded()
	local st = Humanoid:GetState()
	return st == Enum.HumanoidStateType.Running or st == Enum.HumanoidStateType.Landed
end

local function FeetRay(d)
	local feetOffset = Humanoid.HipHeight + HRP.Size.Y * 0.5
	local origin = HRP.Position - Vector3.new(0, feetOffset, 0)
	local p = RaycastParams.new()
	p.FilterDescendantsInstances = { Character }
	p.FilterType = Enum.RaycastFilterType.Exclude
	return Workspace:Raycast(origin, Vector3.new(0, -d, 0), p)
end
local function IsHighEnoughForDive() return FeetRay(DIVE_MIN_HEIGHT) == nil end
local function GroundIsClose() return FeetRay(DIVE_END_BUFFER) ~= nil end

local function ForwardHit(origin, dist)
	local p = RaycastParams.new()
	p.FilterDescendantsInstances = { Character }
	p.FilterType = Enum.RaycastFilterType.Exclude
	return Workspace:Raycast(origin, HRP.CFrame.LookVector * dist, p)
end

local function StopDive(bounced)
	if not isDiving then return end
	isDiving = false
	Humanoid.AutoRotate, HRP.CanCollide = true, true
	Anim.Dive:Stop()
	if bounced and Sounds.bounce then Sounds.bounce:Play() end
	HRP.AssemblyLinearVelocity = Vector3.new(0, HRP.AssemblyLinearVelocity.Y, 0)
	currentState = IsGrounded() and ParkourState.grounded or ParkourState.jump
end

local function StartDive()
	if stateDebounce or isDiving or hasDived then return end
	if (currentState == ParkourState.jump or currentState == ParkourState.double) and IsHighEnoughForDive() then
		isDiving, hasDived = true, true
		currentState = ParkourState.dive
		Humanoid.AutoRotate, HRP.CanCollide = false, false
		local fwd = HRP.CFrame.LookVector.Unit * DIVE_FORCE
		HRP.Velocity = Vector3.new(fwd.X, DIVE_UPWARD_NUDGE, fwd.Z)
		if Sounds.dive then Sounds.dive:Play() end
		Anim.Dive:Play()
	end
end

local function StopRoll(bounced)
	if not isRolling then return end
	isRolling, stateDebounce = false, false
	Humanoid.WalkSpeed = BASE_WALK_SPEED
	HRP.CanCollide, UpperTorso.CanCollide = true, true
	Anim.Roll:Stop()
	if bounced and Sounds.bounce then Sounds.bounce:Play() end
	currentState = IsGrounded() and ParkourState.grounded or ParkourState.jump
end

local function StartRoll()
	if stateDebounce or isRolling or currentState ~= ParkourState.grounded then return end
	stateDebounce, isRolling = true, true
	currentState = ParkourState.roll
	Humanoid.WalkSpeed = 0
	HRP.CanCollide, UpperTorso.CanCollide = false, false
	rollDir, rollStartTime = HRP.CFrame.LookVector.Unit, tick()
	Anim.Roll:Play()
	if Sounds.roll then Sounds.roll:Play() end
	HRP.Velocity = Vector3.new(rollDir.X * ROLL_SPEED, HRP.AssemblyLinearVelocity.Y, rollDir.Z * ROLL_SPEED)
end

local function Jump()
	if isRolling then
		local air = not IsGrounded()
		StopRoll(false)
		HRP.Velocity = Vector3.new(HRP.Velocity.X, air and DOUBLE_JUMP_POWER or JUMP_POWER, HRP.Velocity.Z)
		if air then
			hasDoubleJumped = true
			currentState = ParkourState.double
			if Sounds.doublejump then Sounds.doublejump:Play() end
			Anim.Jump:Play()
		else
			currentState = ParkourState.jump
			if Sounds.jump then Sounds.jump:Play() end
		end
		return
	end
	if stateDebounce or jumpDebounce then return end
	if currentState == ParkourState.grounded then
		jumpDebounce = true
		task.delay(0.15, function() jumpDebounce = false end)
		HRP.Velocity = Vector3.new(HRP.Velocity.X, JUMP_POWER, HRP.Velocity.Z)
		currentState = ParkourState.jump
		hasDoubleJumped, hasDived = false, false
		if Sounds.jump then Sounds.jump:Play() end
	elseif currentState == ParkourState.jump and not hasDoubleJumped then
		HRP.Velocity = Vector3.new(HRP.Velocity.X, DOUBLE_JUMP_POWER, HRP.Velocity.Z)
		currentState, hasDoubleJumped = ParkourState.double, true
		if Sounds.doublejump then Sounds.doublejump:Play() end
		Anim.Jump:Play()
	elseif currentState == ParkourState.dive and not hasDoubleJumped then
		StopDive(false)
		HRP.Velocity = Vector3.new(HRP.Velocity.X, DOUBLE_JUMP_POWER, HRP.Velocity.Z)
		currentState, hasDoubleJumped = ParkourState.double, true
		if Sounds.doublejump then Sounds.doublejump:Play() end
		Anim.Jump:Play()
	end
end

UserInputService.JumpRequest:Connect(Jump)
CAS:BindAction("RollDive", function(_, state)
	if state ~= Enum.UserInputState.Begin then return end
	if IsGrounded() then
		StartRoll()
	else
		StartDive()
	end
end, false, Enum.KeyCode.LeftShift, Enum.KeyCode.RightShift, Enum.KeyCode.ButtonB)

local function EnsureDebugGui()
	if not Player:FindFirstChild "PlayerGui" then return end
	local gui = Player.PlayerGui:FindFirstChild "ParkourDebug"
	if gui then return gui end
	gui = Instance.new("ScreenGui", Player.PlayerGui)
	gui.Name = "ParkourDebug"
	local t = Instance.new("TextLabel", gui)
	t.Name = "StateText"
	t.Size = UDim2.fromOffset(320, 110)
	t.BackgroundTransparency = 0.4
	t.BackgroundColor3 = Color3.new()
	t.TextColor3 = Color3.new(1, 1, 1)
	t.Font = Enum.Font.Code
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.TextYAlignment = Enum.TextYAlignment.Top
	return gui
end

RunService.Heartbeat:Connect(function()
	if isDiving and GroundIsClose() then StopDive(false) end
	if IsGrounded() and currentState ~= ParkourState.roll then
		if currentState ~= ParkourState.grounded then
			currentState = ParkourState.grounded
			hasDoubleJumped, hasDived = false, false
			StopDive(false)
		end
	elseif not IsGrounded() and currentState == ParkourState.grounded then
		currentState = ParkourState.jump
	end

	if isRolling then
		local hit = ForwardHit(HRP.Position - Vector3.new(0, 2, 0), ROLL_OBSTACLE_DIST)
		if (hit and hit.Normal.Y <= 0.4) or tick() - rollStartTime >= ROLL_DURATION then
			StopRoll(hit ~= nil)
		else
			local vY = HRP.AssemblyLinearVelocity.Y
			HRP.CFrame = CFrame.new(HRP.Position, HRP.Position + rollDir)
			HRP.Velocity = Vector3.new(rollDir.X * ROLL_SPEED, vY, rollDir.Z * ROLL_SPEED)
		end
	end

	if isDiving then
		local hit = ForwardHit(Head.Position, DIVE_OBSTACLE_DIST)
		if hit and hit.Normal.Y <= 0.4 then
			StopDive(true)
		else
			local dv = HRP.CFrame.LookVector.Unit * DIVE_FORCE
			HRP.Velocity = Vector3.new(dv.X, HRP.Velocity.Y, dv.Z)
		end
	end

	local gui = EnsureDebugGui()
	if gui then
		gui.StateText.Text = string.format(
			"State: %s\nGrounded: %s\nDoubleJumped: %s\nDiving: %s\nRolling: %s",
			currentState,
			tostring(IsGrounded()),
			tostring(hasDoubleJumped),
			tostring(isDiving),
			tostring(isRolling)
		)
	end

    parkourState:set(currentState)
end)

Player.CharacterRemoving:Connect(function()
    parkourState:set(ParkourState.grounded)
end)