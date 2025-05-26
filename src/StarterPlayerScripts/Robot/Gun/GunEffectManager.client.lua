---------------------------------------------------------------------
-- GunEffectManager (dual-gun version)
---------------------------------------------------------------------
local RETRACT_ANIM_ID = "rbxassetid://137512829777517" -- TODO: replace

local Players = game:GetService "Players"
local RS = game:GetService "ReplicatedStorage"
local RF = game:GetService "ReplicatedFirst"
local RunService = game:GetService "RunService"

-- modules
local RoundCfg = require(RS.Configuration.RoundConfiguration)
local ClientState = require(RS.Data.ClientState)
local CRDU = require(RS.Data.RoundData.ClientRoundDataUtility)
local Fusion = require(RF.Vendor.Fusion)
local MouseUtil = require(RF.Utility.Mouse)
local Platform = require(RF.Utility.Platform)
local IK = require(RS.Utility.IK)
local Types = require(RF.Utility.Types)
local Enums = require(RF.Enums)

local GunEffectsFolder = Instance.new "Folder"
GunEffectsFolder.Name = "GunEffects"
GunEffectsFolder.Parent = workspace

---------------------------------------------------------------------
-- Fusion helpers
---------------------------------------------------------------------
local peek = Fusion.peek
local Out = Fusion.Out
local scope = Fusion.scoped(Fusion)

---------------------------------------------------------------------
-- Local helpers
---------------------------------------------------------------------
type RoundPlayerData = Types.RoundPlayerData

local function beamWidth1(dist: number): number
	local startWidth = 0.2 -- The width of the beam at the start
	local maxWidth = 2 -- The maximum width of the beam
	local maxDist = 100 -- The maximum distance for scaling

	-- Linear scaling with clamping
	local width = startWidth + (maxWidth - startWidth) * math.min(dist / maxDist, 1)
	return width
end
local function strength(dist: number): number return RoundCfg.gunStrengthMultiplier ^ dist end

local function getTargetPosition(player: Player)
	local maxDepth = 256
	local platform = peek(Platform.platform)

	if platform == Enums.PlatformType.Mobile then
		local camera = workspace.CurrentCamera
		if not camera then return end

		local viewportSize = camera.ViewportSize

		local ray = camera:ViewportPointToRay(viewportSize.X / 2, viewportSize.Y / 2, maxDepth)

		local rayCastParams = RaycastParams.new()

		rayCastParams.FilterType = Enum.RaycastFilterType.Exclude
		rayCastParams.FilterDescendantsInstances = { player.Character }

		local result = workspace:Raycast(camera.CFrame.Position, ray.Direction * maxDepth, rayCastParams)

		if result then
			return result.Position
		else
			return ray.Origin + ray.Direction * maxDepth
		end
	else
		return MouseUtil.getWorldPosition(nil, { player.Character }, maxDepth)
	end
end

local playerScopes = {}

---------------------------------------------------------------------
-- Per-player glue
---------------------------------------------------------------------
local function onPlayer(player: Player)
	-----------------------------------------------------------------
	-- Fusion reactive values derived from round data
	-----------------------------------------------------------------
	local playerScope = scope:deriveScope()
	playerScopes[player] = playerScope

	local rd = playerScope:Computed(
		function(use): RoundPlayerData? return use(ClientState.external.roundData.playerData)[player.UserId] end
	)

	local shoot = playerScope:Computed(function(u) return u(rd) and u(rd).actions.isShooting or false end)
	local gunOn = playerScope:Computed(function(u) return u(CRDU.isGunEnabled)[player.UserId] or false end)

	local beingAtk = playerScope:Computed(function(u)
		for _, data in pairs(u(ClientState.external.roundData.playerData)) do
			if data.victims[player.UserId] then return true end
		end
		return false
	end)

	-----------------------------------------------------------------
	-- Character-specific setup
	-----------------------------------------------------------------
	local characterScope: Fusion.Scope = nil

	local function characterAdded(char: Model)
		characterScope = playerScope:innerScope()

		-- retract animation
		local anim = Instance.new "Animation"
		anim.AnimationId = RETRACT_ANIM_ID

		local hum = char:WaitForChild "Humanoid"
		local animator = hum:WaitForChild "Animator" :: Animator

		local retractTrack = animator:LoadAnimation(anim)

		if not retractTrack then
			warn "Failed to load gun retract animation"
			return
		end

		retractTrack.Priority = Enum.AnimationPriority.Action4

		-- gun FX folder refs
		local gfx = char:WaitForChild "GunEffects"
		local beamL = gfx:WaitForChild "BeamL" :: Beam
		local beamR = gfx:WaitForChild "BeamR" :: Beam
		local hitL = gfx:WaitForChild "HitL" :: Part
		local hitR = gfx:WaitForChild "HitR" :: Part
		local neonL = char:WaitForChild "LeftGunNeon" :: Part
		local neonR = char:WaitForChild "RightGunNeon" :: Part
		local colorL = char:WaitForChild "LeftGunColor" :: Part
		local colorR = char:WaitForChild "RightGunColor" :: Part
		local hitFlareL = hitL:WaitForChild("HitFlare"):WaitForChild "HitFlareImage" :: ImageLabel
		local hitFlareR = hitR:WaitForChild("HitFlare"):WaitForChild "HitFlareImage" :: ImageLabel
		local gunFlareL = neonL:WaitForChild("GunFlare"):WaitForChild "GunFlareImage" :: ImageLabel
		local gunFlareR = neonR:WaitForChild("GunFlare"):WaitForChild "GunFlareImage" :: ImageLabel

		if player == Players.LocalPlayer then
			beamL.Parent = GunEffectsFolder
			beamR.Parent = GunEffectsFolder

			table.insert(characterScope, beamL)
			table.insert(characterScope, beamR)
		end

		local colors = characterScope:Value({})
		do
			local colorsConfig = char:WaitForChild "Colors" :: Configuration

			local function forChildren(config: Configuration)
				local name = config.Name
				local hunters = (config:WaitForChild "Hunters" :: Color3Value).Value
				local rebels = (config:WaitForChild "Rebels" :: Color3Value).Value
				colors[name] = {
					[Enums.TeamType.hunters] = hunters,
					[Enums.TeamType.rebels] = rebels,
					[Enums.TeamType.lobby] = Color3.new(1, 1, 1),
				}
			end

			for _, config in ipairs(colorsConfig:GetChildren()) do
				forChildren(config)
			end

			colorsConfig.ChildAdded:Connect(function(child)
				if child:IsA "Configuration" then
					forChildren(child)
				end
			end)
		end

		local tipPosL, tipPosR = characterScope:Value(nil), characterScope:Value(nil)

		----------------------------------------------------------------
		-- distance computeds
		----------------------------------------------------------------
		local distL = characterScope:Computed(function(u)
			local isShooting = u(shoot)

			if not isShooting then return 0 end

			local playerData = u(rd)

			if not playerData then return 0 end

			if not playerData.gunHitPositionL then return 0 end

			local tipPosL = u(tipPosL)

			if tipPosL then
				return (tipPosL - playerData.gunHitPositionL).Magnitude
			else
				return 0
			end
		end)
		local distR = characterScope:Computed(function(u)
			local isShooting = u(shoot)

			if not isShooting then return 0 end

			local playerData = u(rd)

			if not playerData then return 0 end

			if not playerData.gunHitPositionR then return 0 end

			local tipPosR = u(tipPosR)

			if tipPosR then
				return (tipPosR - playerData.gunHitPositionR).Magnitude
			else
				return 0
			end
		end)

		table.insert(
			characterScope,
			RunService.RenderStepped:Connect(function()
				tipPosL:set(neonL.Position)
				tipPosR:set(neonR.Position)
			end)
		)

		----------------------------------------------------------------
		-- Hydrate beams & hit parts
		----------------------------------------------------------------
		local function setupBeam(beam: Beam, dist, hitPosKey: "gunHitPositionL" | "gunHitPositionR")
			characterScope:Hydrate(beam) {
				Enabled = true,
				Width0 = characterScope:Computed(
					function(u) return if u(shoot) and u(rd) and u(rd)[hitPosKey] then 0.2 else 0 end
				),
				Width1 = characterScope:Computed(
					function(u) return if u(shoot) and u(rd) and u(rd)[hitPosKey] then beamWidth1(u(dist)) else 0 end
				),
				Color = characterScope:Computed(function(u)
					local data = u(rd)
					if not data then return ColorSequence.new(Color3.new(1, 1, 1)) end
					local c = colors["Beam"][data.team] or Color3.new(1, 1, 1)
					return ColorSequence.new(c)
				end),
				Transparency = characterScope:Computed(function(u)
					local d = u(dist)
					local keys = {}
					local numKeypoints = 14 -- Number of keypoints before the final one

					for i = 0, numKeypoints do
						-- Use a non-linear scaling function to concentrate keypoints near the start
						local frac = (i / numKeypoints) ^ 2 -- Squaring frac to concentrate near 0
						local tr = (1 - strength(frac * d)) ^ 1.3
						table.insert(keys, NumberSequenceKeypoint.new(frac, tr))
					end

					-- Add the final keypoint at the end
					table.insert(keys, NumberSequenceKeypoint.new(1, strength(d)))
					return NumberSequence.new(keys)
				end),
			}
		end

		setupBeam(beamL, distL, "gunHitPositionL")
		setupBeam(beamR, distR, "gunHitPositionR")

		local function hydrateHit(hitPart: Part, key: "gunHitPositionL" | "gunHitPositionR")
			characterScope:Hydrate(hitPart) {
				Position = characterScope:Computed(function(u) return u(rd) and u(rd)[key] or Vector3.zero end),
			}
		end
		hydrateHit(hitL, "gunHitPositionL")
		hydrateHit(hitR, "gunHitPositionR")

		local function hydrateFlare(
			hitFlare: ImageLabel,
			flareType: "HitFlare" | "GunFlare",
			key: "gunHitPositionL" | "gunHitPositionR"
		)
			characterScope:Hydrate(hitFlare) {
				Visible = characterScope:Computed(function(u) return u(shoot) and u(rd) and u(rd)[key] end),
				ImageColor3 = characterScope:Computed(function(u)
					local data = u(rd)
					if not data then return Color3.new(1, 1, 1) end
					return colors[flareType][data.team] or Color3.new(1, 1, 1)
				end),
			}
		end
		hydrateFlare(hitFlareL, "HitFlare", "gunHitPositionL")
		hydrateFlare(gunFlareL, "GunFlare", "gunHitPositionL")
		hydrateFlare(hitFlareR, "HitFlare", "gunHitPositionR")
		hydrateFlare(gunFlareR, "GunFlare", "gunHitPositionR")

		local function hydrateGunParts(gunPart: Part, colorType: "GunColor" | "GunNeon")
			characterScope:Hydrate(gunPart) {
				Color = characterScope:Computed(function(u)
					local data = u(rd)
					if not data then return Color3.new(1, 1, 1) end
					return colors[colorType][data.team] or Color3.new(1, 1, 1)
				end),
			}
		end
		hydrateGunParts(neonL, "GunNeon")
		hydrateGunParts(neonR, "GunNeon")
		hydrateGunParts(colorL, "GunColor")
		hydrateGunParts(colorR, "GunColor")

		----------------------------------------------------------------
		-- torso effects
		----------------------------------------------------------------
		local upperTorso = char:WaitForChild "UpperTorso"

		local oppositeTeam = characterScope:Computed(function(use): number?
			local rd = use(rd)

			if not rd then return end

			return if rd.team == Enums.TeamType.hunters then Enums.TeamType.rebels else Enums.TeamType.hunters
		end)

		local function forEachUpperTorsoDescendant(descendant: Instance)
			if descendant.Name == "AttackLight" then
				characterScope:Hydrate(descendant) {
					Enabled = characterScope:Computed(function(use) return use(beingAtk) end),
					Color = characterScope:Computed(function(use)
						local rd = use(rd)
						local oppositeTeam = use(oppositeTeam)

						if not rd or not oppositeTeam then return Color3.new(1, 1, 1) end

						return colors["AttackLight"][oppositeTeam] or Color3.new(1, 1, 1)
					end),
				}
			elseif descendant.Name == "AttackGlow" then
				characterScope:Hydrate(descendant) {
					Enabled = characterScope:Computed(function(use) return use(beingAtk) end),
				}

				characterScope:Hydrate(descendant:WaitForChild "ImageLabel") {
					ImageColor3 = characterScope:Computed(function(use)
						local rd = use(rd)
						local oppositeTeam = use(oppositeTeam)

						if not rd or not oppositeTeam then return Color3.new(1, 1, 1) end

						return colors["AttackGlow"][oppositeTeam] or Color3.new(1, 1, 1)
					end),
				}
			elseif descendant.Name == "AttackElectricity" then
				characterScope:Hydrate(descendant) {
					Enabled = characterScope:Computed(function(use) return use(beingAtk) end),
					Color = characterScope:Computed(function(use)
						local roundPlayerData = use(rd)
						local oppositeTeam = use(oppositeTeam)

						if not roundPlayerData or not oppositeTeam then
							return ColorSequence.new(Color3.new(1, 1, 1))
						end

						return ColorSequence.new(colors["AttackElectricity"][oppositeTeam] or Color3.new(1, 1, 1))
					end),
				}
			end
		end

		for _, descendant in ipairs(upperTorso:GetDescendants()) do
			forEachUpperTorsoDescendant(descendant)
		end
		upperTorso.DescendantAdded:Connect(forEachUpperTorsoDescendant)

		----------------------------------------------------------------
		-- play / stop retract animation based on gunEnabled
		----------------------------------------------------------------
		local function updateRetract()
			if peek(gunOn) then
				if retractTrack.IsPlaying then retractTrack:Stop(0.5) end
			else
				if not retractTrack.IsPlaying then retractTrack:Play(0.2) end
			end
		end
		updateRetract()
		characterScope:Observer(gunOn):onChange(updateRetract)

		----------------------------------------------------------------
		-- IK aiming
		----------------------------------------------------------------

		local IKUpdateThread = nil
		local leftIK = nil
		local rightIK = nil

		local function resetShoulderJoint(motor: Motor6D)
			if motor then
				motor.Transform = CFrame.identity
				motor.C1 = CFrame.new(motor.C1.Position)
				motor.CurrentAngle = 0
				RunService.RenderStepped:Wait() -- :(
				motor.CurrentAngle = 0
			end
		end

		local function stopThread()
			if IKUpdateThread then
				task.cancel(IKUpdateThread)
				IKUpdateThread = nil
			end

			if leftIK then
				leftIK:Destroy()
				leftIK = nil
			end
			if rightIK then
				rightIK:Destroy()
				rightIK = nil
			end

			-- Reset joints properly
			local leftShoulder = char:FindFirstChild("LeftShoulder", true)
			local rightShoulder = char:FindFirstChild("RightShoulder", true)

			resetShoulderJoint(leftShoulder)
			resetShoulderJoint(rightShoulder)
		end

		local function onShootStatusChanged()
			if not peek(shoot) then
				stopThread()
				return
			else
				if not IKUpdateThread then
					local localThread = nil

					IKUpdateThread = task.spawn(function()
						local playerData = peek(ClientState.external.roundData.playerData)[player.UserId]

						if not playerData then return end
						local hitPosL = playerData.gunHitPositionL
						local hitPosR = playerData.gunHitPositionR

						repeat
							hitPosL = playerData.gunHitPositionL
							hitPosR = playerData.gunHitPositionR
							task.wait()
						until hitPosL or hitPosR

						leftIK = hitPosL and IK.AL.new(char, "Left", "Arm")
						rightIK = hitPosR and IK.AL.new(char, "Right", "Arm")
						if hitPosL then leftIK.ExtendWhenUnreachable = true end
						if hitPosR then rightIK.ExtendWhenUnreachable = true end

						local rootPart = char:WaitForChild "HumanoidRootPart" :: BasePart

						do -- We need to set C1 of LeftShoulder in LeftUpper Arm to (0, -90, 0) and right
							-- shoulder to (0, 90, 0) to make the arms point in the right direction, but we need to keep the position element of the cframes
							local leftShoulder = char:FindFirstChild("LeftShoulder", true)
							local rightShoulder = char:FindFirstChild("RightShoulder", true)

							if leftShoulder and hitPosL then
								leftShoulder.C1 = CFrame.new(leftShoulder.C1.Position)
									* CFrame.Angles(0, math.rad(90), 0)
							end
							if rightShoulder and hitPosR then
								rightShoulder.C1 = CFrame.new(rightShoulder.C1.Position)
									* CFrame.Angles(0, math.rad(-90), 0)
							end
						end

						while RunService.PreRender:Wait() do
							if localThread ~= IKUpdateThread then
								-- if the thread was stopped, we don't want to continue
								return
							end

							if player == Players.LocalPlayer then --and peek(Platform.platform) ~= Enums.PlatformType.Mobile then
								local mouseWorldPosition = getTargetPosition(player)
								if not mouseWorldPosition then continue end

								IK.SetTemporaryAimPosition(mouseWorldPosition)
								-- if on mobile, just make hrp follow the camera
								if peek(Platform.platform) == Enums.PlatformType.Mobile then
									local camera = workspace.CurrentCamera

									if camera then
										local camLook =
											Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z).Unit
										rootPart.CFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + camLook)
									end
								else
									local flatLook =
										Vector3.new(mouseWorldPosition.X, rootPart.Position.Y, mouseWorldPosition.Z)
									rootPart.CFrame = CFrame.lookAt(rootPart.Position, flatLook)
								end
							end

							if hitPosL then leftIK:Solve(hitL.Position) end
							if hitPosR then rightIK:Solve(hitR.Position) end
						end
					end)

					localThread = IKUpdateThread
				end
			end
		end
		characterScope:Observer(shoot):onChange(onShootStatusChanged)
		table.insert(characterScope, stopThread)
		-- if player == Players.LocalPlayer then
		-- 	local rootPart = char:WaitForChild "HumanoidRootPart" :: BasePart

		-- 	table.insert(
		-- 		characterScope,
		-- 		RunService.RenderStepped:Connect(function()
		-- 			if peek(Platform.platform) ~= Enums.PlatformType.Mobile then return end

		-- 			if peek(CRDU.isGunEnabled)[player.UserId] then
		-- 				local mouseWorldPosition = getTargetPosition(player)
		-- 				if not mouseWorldPosition then return end

		-- 				local camCF = workspace.CurrentCamera and workspace.CurrentCamera.CFrame
		-- 				if not camCF then return end
		-- 				local camLook = Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z).Unit

		-- 				IK.SetTemporaryAimPosition(mouseWorldPosition)
		-- 				rootPart.CFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + camLook)
		-- 			end
		-- 		end)
		-- 	)
		-- end
	end

	table.insert(playerScope, player.CharacterAdded:Connect(characterAdded))
	table.insert(
		playerScope,
		player.CharacterRemoving:Connect(function()
			if characterScope then characterScope:doCleanup() end
		end)
	)
	if player.Character then characterAdded(player.Character) end
end

---------------------------------------------------------------------
-- connect all players
---------------------------------------------------------------------
Players.PlayerAdded:Connect(onPlayer)
for _, plr in ipairs(Players:GetPlayers()) do
	onPlayer(plr)
end

Players.PlayerRemoving:Connect(function(plr)
	if playerScopes[plr] then
		playerScopes[plr]:doCleanup()
		playerScopes[plr] = nil
	end

	-- just go through the list and make sure each player is still playing

	for player, playerScope in pairs(playerScopes) do
		if not player:IsDescendantOf(Players) then
			playerScope:doCleanup()
			playerScopes[player] = nil
		end
	end
end)
