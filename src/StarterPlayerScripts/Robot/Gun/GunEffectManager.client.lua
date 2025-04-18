local GUN_VISIBILITY_TWEEN_TIME = 1

local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local RunService = game:GetService "RunService"

local RoundConfiguration = require(ReplicatedStorage:WaitForChild("Configuration"):WaitForChild "RoundConfiguration")
local ClientState = require(ReplicatedStorage:WaitForChild("Data"):WaitForChild "ClientState")
local ClientStateUtility =
	require(ReplicatedStorage:WaitForChild("Data"):WaitForChild("RoundData"):WaitForChild "ClientRoundDataUtility")
local Fusion = require(ReplicatedFirst:WaitForChild("Vendor"):WaitForChild "Fusion")
local Types = require(ReplicatedFirst:WaitForChild("Utility"):WaitForChild "Types")
local Enums = require(ReplicatedFirst:WaitForChild "Enums")

local scope = Fusion.scoped(Fusion)

local peek = Fusion.peek

type RoundPlayerData = Types.RoundPlayerData

local function calculateBeamWidth1(distance) return 0.2 + (distance / 100) end

local function calculateStrength(distance) return RoundConfiguration.gunStrengthMultiplier ^ distance end

local function onPlayerAdded(player)
	local tipPositionUpdateConnection: RBXScriptConnection? = nil
	local gunVisibilityUpdateConnection = nil

	local roundPlayerData = scope:Computed(function(use): RoundPlayerData?
		local roundPlayerData = use(ClientState.external.roundData.playerData)

		if not roundPlayerData then return end

		for id, data in pairs(roundPlayerData) do
			if id == player.UserId then return data end
		end

		return nil
	end)

	local gunHitPosition = scope:Computed(function(use)
		local roundPlayerData = use(roundPlayerData)

		if not roundPlayerData then return end

		return roundPlayerData.gunHitPosition
	end)

	local isBeingAttacked = scope:Computed(function(use): boolean
		for _, data in pairs(use(ClientState.external.roundData.playerData)) do
			if data.victims[player.UserId] then
				return true
			end
		end

		return false
	end)

	local isShooting = scope:Computed(function(use): boolean
		return use(roundPlayerData) and use(roundPlayerData).actions.isShooting
	end)

	local function onCharacterAdded(character)
		local gun = character:WaitForChild "Gun"
		local upperTorso = character:WaitForChild "UpperTorso"

		local referencesFolder = gun:WaitForChild "References" :: Configuration

		local beamObjectValue: ObjectValue = referencesFolder:WaitForChild "Beam"
		local hitPartObjectValue: ObjectValue = referencesFolder:WaitForChild "HitPart"
		local tipAttachmentObjectValue: ObjectValue = referencesFolder:WaitForChild "AttachmentTip"
		local tipPosition = scope:Value(nil :: Vector3?)

		local function waitForValue(objectValue: ObjectValue): Instance?
			local value = objectValue.Value

			if value then return value end

			objectValue.Changed:Wait()

			return objectValue.Value
		end

		local beam = waitForValue(beamObjectValue) :: Beam
		local hitPart = waitForValue(hitPartObjectValue) :: Part
		local tipAttachment = waitForValue(tipAttachmentObjectValue) :: Attachment

		local distance = scope:Computed(function(use): number
			if not use(isShooting) then return 0 end

			local gunHitPosition = use(gunHitPosition)
			local tipPosition = use(tipPosition)

			if not gunHitPosition or not tipPosition then return 0 end

			local distance = (use(gunHitPosition) - use(tipPosition)).Magnitude

			return distance
		end)

		scope:Hydrate(hitPart) {
			Position = scope:Computed(function(use)
				local gunHitPosition = use(gunHitPosition)

				if not gunHitPosition then return Vector3.new(0, 0, 0) end

				return use(gunHitPosition)
			end),
		}

		scope:Hydrate(beam) {
			Enabled = true,
			Width0 = scope:Computed(function(use) return if use(isShooting) and use(gunHitPosition) then 0.2 else 0 end),
			Width1 = scope:Computed(
				function(use)
					return if use(isShooting) and use(gunHitPosition) then calculateBeamWidth1(use(distance)) else 0
				end
			),
			Color = scope:Computed(function(use)
				local color

				local roundPlayerData = use(roundPlayerData)

				if not roundPlayerData then
					color = Color3.new(1, 1, 1)
				else
					color = RoundConfiguration.gunEffectColors[roundPlayerData.team].beamColor
				end

				return ColorSequence.new(color)
			end),
			Transparency = scope:Computed(function(use)
				local distance = use(distance)

				local keypoints = {}

				for i = 0, 14 do
					local currentDistance = i / 14 * distance

					local transparency = 1 - calculateStrength(currentDistance)

					table.insert(keypoints, NumberSequenceKeypoint.new(i / 14, transparency))
				end

				table.insert(keypoints, NumberSequenceKeypoint.new(1, calculateStrength(distance)))

				return NumberSequence.new(keypoints)
			end),
		}

		local gunHighlightTransparency = scope:Value(1 :: number)
		local isGunVisible = scope:Value(peek(ClientStateUtility.isGunEnabled)[player.UserId] or false :: boolean)
		local gunHighlightTransparencyTween = scope:Tween(
			gunHighlightTransparency,
			TweenInfo.new(GUN_VISIBILITY_TWEEN_TIME, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
		)

		local function forEachGunDescendant(descendant: Instance)
			if descendant:IsA "BasePart" and descendant.Name ~= "Hit" then
				local transparency = descendant:GetAttribute "CustomTransparency" or 0

				scope:Hydrate(descendant) {
					Transparency = scope:Computed(function(use) return if use(isGunVisible) then transparency else 1 end),
				}
			elseif descendant:IsA "Highlight" then
				scope:Hydrate(descendant) {
					FillTransparency = scope:Computed(
						function(use)
							return if use(ClientStateUtility.isGunEnabled)
								then peek(gunHighlightTransparencyTween)
								else 1
						end
					),
				}
			end
		end

		local oppositeTeam = scope:Computed(function(use): number?
			local roundPlayerData = use(roundPlayerData)

			if not roundPlayerData then return end

			return if roundPlayerData.team == Enums.TeamType.hunters
				then Enums.TeamType.rebels
				else Enums.TeamType.hunters
		end)

		local function forEachUpperTorsoDescendant(descendant: Instance)
			if descendant.Name == "AttackLight" then
				scope:Hydrate(descendant) {
					Enabled = scope:Computed(function(use) return use(isBeingAttacked) end),
					Color = scope:Computed(function(use)
						local roundPlayerData = use(roundPlayerData)
						local oppositeTeam = use(oppositeTeam)

						if not roundPlayerData or not oppositeTeam then return Color3.new(1, 1, 1) end

						return RoundConfiguration.gunEffectColors[oppositeTeam].attackLightColor
					end),
				}
			elseif descendant.Name == "AttackGlow" then
				scope:Hydrate(descendant) {
					Enabled = scope:Computed(function(use) return use(isBeingAttacked) end),
				}

				scope:Hydrate(descendant:WaitForChild "ImageLabel") {
					ImageColor3 = scope:Computed(function(use)
						local roundPlayerData = use(roundPlayerData)
						local oppositeTeam = use(oppositeTeam)

						if not roundPlayerData or not oppositeTeam then return Color3.new(1, 1, 1) end

						return RoundConfiguration.gunEffectColors[oppositeTeam].attackGlowColor
					end),
				}
			elseif descendant.Name == "AttackElectricity" then
				scope:Hydrate(descendant) {
					Enabled = scope:Computed(function(use) return use(isBeingAttacked) end),
					Color = scope:Computed(function(use)
						local roundPlayerData = use(roundPlayerData)
						local oppositeTeam = use(oppositeTeam)

						if not roundPlayerData or not oppositeTeam then
							return ColorSequence.new(Color3.new(1, 1, 1))
						end

						return ColorSequence.new(
							RoundConfiguration.gunEffectColors[oppositeTeam].attackElectricityColor
						)
					end),
				}
			end
		end

		for _, descendant in ipairs(gun:GetDescendants()) do
			forEachGunDescendant(descendant)
		end

		for _, descendant in ipairs(upperTorso:GetDescendants()) do
			forEachUpperTorsoDescendant(descendant)
		end

		gun.DescendantAdded:Connect(forEachGunDescendant)
		upperTorso.DescendantAdded:Connect(forEachUpperTorsoDescendant)

		tipPositionUpdateConnection = RunService.RenderStepped:Connect(
			function() tipPosition:set(tipAttachment.WorldPosition) end
		)

		local function onGunEnabledChanged()
			local isGunEnabled = peek(ClientStateUtility.isGunEnabled)[player.UserId]

			if isGunEnabled then
				gunHighlightTransparency:set(0)
				task.wait(GUN_VISIBILITY_TWEEN_TIME)
				isGunVisible:set(true)
				gunHighlightTransparency:set(1)
			else -- Do the opposite
				gunHighlightTransparency:set(0)
				task.wait(GUN_VISIBILITY_TWEEN_TIME)
				isGunVisible:set(false)
				gunHighlightTransparency:set(1)
			end
		end

		gunVisibilityUpdateConnection = scope:Observer(
			scope:Computed(function(use) return use(ClientStateUtility.isGunEnabled)[player.UserId] end)
		):onChange(onGunEnabledChanged)

		onGunEnabledChanged()
	end

	local function onCharacterRemoving()
		if tipPositionUpdateConnection then tipPositionUpdateConnection:Disconnect() end
		if gunVisibilityUpdateConnection then gunVisibilityUpdateConnection() end
	end

	player.CharacterAdded:Connect(onCharacterAdded)
	player.CharacterRemoving:Connect(onCharacterRemoving)

	if player.Character then onCharacterAdded(player.Character) end
end

Players.PlayerAdded:Connect(onPlayerAdded)

for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end
