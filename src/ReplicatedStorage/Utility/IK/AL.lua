--  IKB/R15/AL.lua  –  Adaptive Limb IK (custom “Joint” rigs supported)
--  • Works with R-15 OR custom rigs where each limb part owns a single
--    Motor6D called “Joint”.
--  • Keeps the original shoulder/elbow *position* and only replaces the
--    rotation, so limbs never pop to (0,0,0).

---------------------------------------------------------------------
-- Services & helper
---------------------------------------------------------------------
local RunService = game:GetService("RunService")
local Helper     = require(script.Parent:WaitForChild("Helper"))

---------------------------------------------------------------------
--                         TYPE HINT (optional)
---------------------------------------------------------------------
type ALIKType = {
	ExtendWhenUnreachable: boolean,

	-- runtime refs
	_UpperTorso: BasePart,
	_UpperJoint: Motor6D,
	_LowerJoint: Motor6D,

	-- cached constants
	_UpperJointC0Cache: CFrame,
	_LowerJointC0Cache: CFrame,
	_UpperLength: number,
	_LowerLength: number,

	_TransformResetLoop: RBXScriptConnection
}

---------------------------------------------------------------------
-- Module table
---------------------------------------------------------------------
local ALIK = {}
ALIK.__index = ALIK

---------------------------------------------------------------------
-- Utility: return Motor6D inside `part`:
--    • prefer `part[preferredName]` when it exists
--    • otherwise return first Motor6D child (eg. “Joint”)
---------------------------------------------------------------------
local function fetchJoint(part: BasePart, preferredName: string?): Motor6D
	if preferredName and part:FindFirstChild(preferredName) then
		return part[preferredName] :: Motor6D
	end
	return part:FindFirstChildWhichIsA("Motor6D") :: Motor6D
end

---------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------
function ALIK.new(character: Model, side: "Left" | "Right", bodyType: "Arm" | "Leg")
	local self = setmetatable({} :: ALIKType, ALIK)

	-- parts
	local upperTorso = character:WaitForChild("UpperTorso") :: BasePart
	local upper      = character:WaitForChild(side .. "Upper" .. bodyType) :: BasePart
	local lower      = character:WaitForChild(side .. "Lower" .. bodyType) :: BasePart
	local tip        = character:WaitForChild(side .. (bodyType == "Arm" and "Hand" or "Foot")) :: BasePart

	-- joints (support R15 names OR single “Joint”)
	local upperJoint = fetchJoint(
		upper,
		side .. (bodyType == "Arm" and "Shoulder" or "Hip")
	)
	local lowerJoint = fetchJoint(
		lower,
		side .. (bodyType == "Arm" and "Elbow"    or "Knee")
	)
	local tipJoint   = fetchJoint(
		tip,
		side .. (bodyType == "Arm" and "Wrist"    or "Ankle")
	)

	assert(upperJoint and lowerJoint and tipJoint, "ALIK: joints not found for "..side.." "..bodyType)

	-----------------------------------------------------------------
	-- cache original C0 (used for translation offset preservation)
	-----------------------------------------------------------------
	local upperC0Cache = upperJoint.C0
	local lowerC0Cache = lowerJoint.C0

	-----------------------------------------------------------------
	-- approximate limb lengths using default C1 / C0 values
	-----------------------------------------------------------------
	local upperLength = math.abs(upperJoint.C1.Y) + math.abs(lowerJoint.C0.Y)
	local lowerLength = math.abs(lowerJoint.C1.Y) + math.abs(tipJoint.C0.Y) + math.abs(tipJoint.C1.Y)

	-----------------------------------------------------------------
	-- zero Transform each physics step so other scripts don’t fight
	-----------------------------------------------------------------
	local resetLoop = RunService.Stepped:Connect(function()
		upperJoint.Transform = CFrame.identity
		lowerJoint.Transform = CFrame.identity
		tipJoint.Transform   = CFrame.identity
	end)

	-----------------------------------------------------------------
	-- populate self
	-----------------------------------------------------------------
	self.ExtendWhenUnreachable = false

	self._UpperTorso = upperTorso
	self._UpperJoint = upperJoint
	self._LowerJoint = lowerJoint

	self._UpperJointC0Cache = upperC0Cache
	self._LowerJointC0Cache = lowerC0Cache

	self._UpperLength = upperLength
	self._LowerLength = lowerLength

	self._TransformResetLoop = resetLoop

	return self
end

---------------------------------------------------------------------
-- Solve IK toward targetPosition (world space)
---------------------------------------------------------------------
function ALIK:Solve(targetPosition: Vector3)
	-- world-space CFrame of the upper-joint origin
	local upperWorldCFrame = self._UpperTorso.CFrame * self._UpperJointC0Cache

	-- planeCF = plane in which the limb bends, angles are around local X
	local planeCF, upperAng, lowerAng =
		Helper:Solve(
			upperWorldCFrame,
			targetPosition,
			self._UpperLength,
			self._LowerLength,
			self.ExtendWhenUnreachable
		)

	-----------------------------------------------------------------
	-- Preserve translation, replace rotation only
	-----------------------------------------------------------------
	local upperPos = self._UpperJointC0Cache.Position
	local lowerPos = self._LowerJointC0Cache.Position

	self._UpperJoint.C0 =
		CFrame.new(upperPos) *
		(self._UpperTorso.CFrame:ToObjectSpace(planeCF)).Rotation *
		CFrame.Angles(upperAng, 0, 0)

	self._LowerJoint.C0 =
		CFrame.new(lowerPos) *
		CFrame.Angles(lowerAng, 0, 0)
end

---------------------------------------------------------------------
-- Clean up and restore original C0
---------------------------------------------------------------------
function ALIK:Destroy()
	self._UpperJoint.C0 = self._UpperJointC0Cache
	self._LowerJoint.C0 = self._LowerJointC0Cache
	self._TransformResetLoop:Disconnect()
end

return ALIK
