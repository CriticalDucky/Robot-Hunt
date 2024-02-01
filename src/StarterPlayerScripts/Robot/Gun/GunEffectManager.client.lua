local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local RunService = game:GetService "RunService"

local RoundConfiguration = require(ReplicatedStorage:WaitForChild("Configuration"):WaitForChild "RoundConfiguration")
local ClientState = require(ReplicatedStorage:WaitForChild("Data"):WaitForChild "ClientState")
local Fusion = require(ReplicatedFirst:WaitForChild("Vendor"):WaitForChild "Fusion")
local Types = require(ReplicatedFirst:WaitForChild("Utility"):WaitForChild "Types")

local Observer = Fusion.Observer
local Hydrate = Fusion.Hydrate
local Out = Fusion.Out
local peek = Fusion.peek
local Value = Fusion.Value
local Computed = Fusion.Computed
local Spring = Fusion.Spring
local Tween = Fusion.Tween

type RoundPlayerData = Types.RoundPlayerData

local localPlayer = Players.LocalPlayer

local function calculateBeamWidth1(distance) return 0.2 + (distance / 100) end

local function calculateStrength(distance) return RoundConfiguration.gunStrengthMultiplier ^ distance end

local function onPlayerAdded(player)
	local tipPositionUpdateConnection: RBXScriptConnection? = nil

	local roundPlayerData = Computed(function(use): RoundPlayerData?
		local roundPlayerData = use(ClientState.external.roundData.playerData)

		if not roundPlayerData then return end

		for _, data in ipairs(roundPlayerData) do
			if data.playerId == player.UserId then return data end
		end

		return nil
	end)

	local gunHitPosition = Computed(function(use)
		local roundPlayerData = use(roundPlayerData)

		if not roundPlayerData then return end

		return roundPlayerData.gunHitPosition
	end)

	local isShooting = Computed(
		function(use): boolean return use(roundPlayerData) and use(roundPlayerData).actions.isShooting end
	)

	local function onCharacterAdded(character)
		if tipPositionUpdateConnection then tipPositionUpdateConnection:Disconnect() end

		local gun = character:WaitForChild "Gun"

		local referencesFolder = gun:WaitForChild "References" :: Configuration

		local beamObjectValue: ObjectValue = referencesFolder:WaitForChild "Beam"
		local hitPartObjectValue: ObjectValue = referencesFolder:WaitForChild "HitPart"
		local tipAttachmentObjectValue: ObjectValue = referencesFolder:WaitForChild "AttachmentTip"
		local tipPosition = Value(nil :: Vector3?)

		local function waitForValue(objectValue: ObjectValue): Instance?
			local value = objectValue.Value

			if value then return value end

			objectValue.Changed:Wait()

			return objectValue.Value
		end

		local beam = waitForValue(beamObjectValue) :: Beam
		local hitPart = waitForValue(hitPartObjectValue) :: Part
		local tipAttachment = waitForValue(tipAttachmentObjectValue) :: Attachment

		local distance = Computed(function(use): number
			if not use(isShooting) then return 0 end

			local gunHitPosition = use(gunHitPosition)
			local tipPosition = use(tipPosition)

			if not gunHitPosition or not tipPosition then return 0 end

			local distance = (use(gunHitPosition) - use(tipPosition)).Magnitude

			return distance
		end)

		Hydrate(hitPart) {
			Position = Computed(function(use)
				local gunHitPosition = use(gunHitPosition)

				if not gunHitPosition then return Vector3.new(0, 0, 0) end

				return use(gunHitPosition)
			end),
		}

		Hydrate(beam) {
			Enabled = true,
			Width0 = Computed(function(use) return if use(isShooting) and use(gunHitPosition) then 0.2 else 0 end),
			Width1 = Computed(
				function(use)
					return if use(isShooting) and use(gunHitPosition) then calculateBeamWidth1(use(distance)) else 0
				end
			),
			Color = Computed(function(use) return ColorSequence.new(RoundConfiguration.hunterBeamColor) end),
			Transparency = Computed(function(use)
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

		local gunHighlightTransparency = Value(1 :: number)

		local gunHighlightTransparencyTween =
			Tween(gunHighlightTransparency, TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut))

		local function forEachGunDescendant(descendant: Instance)
			if descendant:IsA "BasePart" then
				local transparency = descendant:GetAttribute "CustomTransparency" or 0

				Hydrate(descendant) {
					Transparency = Computed(function(use)
						local playerData = use(ClientState.external.roundData.playerData)
						local currentPlayerData = playerData and playerData[player.UserId]

						if not playerData then return 0 end

						local isShooting = currentPlayerData.actions.isShooting

						return if isShooting then transparency else 0
					end),
				}
			end
		end

		for _, descendant in ipairs(gun:GetDescendants()) do
			forEachGunDescendant(descendant)
		end

		gun.DescendantAdded:Connect(forEachGunDescendant)

		tipPositionUpdateConnection = RunService.RenderStepped:Connect(
			function() tipPosition:set(tipAttachment.WorldPosition) end
		)
	end

	player.CharacterAdded:Connect(onCharacterAdded)

	if player.Character then onCharacterAdded(player.Character) end
end

Players.PlayerAdded:Connect(onPlayerAdded)

for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end
