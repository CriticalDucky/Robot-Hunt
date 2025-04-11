local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local Players = game:GetService "Players"

local ClientState = require(ReplicatedStorage:WaitForChild("Data"):WaitForChild "ClientState")
local RoundConfiguration = require(ReplicatedStorage:WaitForChild("Configuration"):WaitForChild "RoundConfiguration")

local Fusion = require(ReplicatedFirst:WaitForChild("Vendor"):WaitForChild "Fusion")
local Enums = require(ReplicatedFirst:WaitForChild "Enums")

local scope = Fusion.scoped(Fusion)

local player = Players.LocalPlayer

local function onDescendantAdded(descendant)
	if descendant:IsA "ProximityPrompt" then
		if descendant.Name == "Battery" then
			scope:Hydrate(descendant) {
				Enabled = scope:Computed(function(use)
					local playerData = use(ClientState.external.roundData.playerData)[player.UserId]

					if not playerData then return false end

					local currentPhase = use(ClientState.external.roundData.currentPhaseType)

					if not RoundConfiguration.roundPhases[currentPhase] then return false end

					local isCrawling = use(ClientState.actions.isCrawling)
					local isShooting = playerData.actions.isShooting
					local isHacking = playerData.actions.isHacking
					local isAlive = playerData.status == Enums.PlayerStatus.alive

					return not isCrawling and not isShooting and not isHacking and isAlive
				end),
			}
		elseif descendant.Name == "Terminal" then
			scope:Hydrate(descendant) {
				Enabled = scope:Computed(function(use)
					local playerData = use(ClientState.external.roundData.playerData)[player.UserId]

					if not playerData then return false end

					if playerData.team == Enums.TeamType.hunters then return false end

					local currentPhase = use(ClientState.external.roundData.currentPhaseType)

					if not RoundConfiguration.roundPhases[currentPhase] then return false end
					if currentPhase == Enums.PhaseType.PhaseTwo then return false end

					local isCrawling = use(ClientState.actions.isCrawling)
					local isShooting = playerData.actions.isShooting
					local isHacking = playerData.actions.isHacking
					local isAlive = playerData.status == Enums.PlayerStatus.alive

					return not isCrawling and not isShooting and not isHacking and isAlive
				end),
			}
		elseif descendant.Name == "HealRobot" then
			local proximityPlayer = Players:GetPlayerFromCharacter(descendant.Parent.Parent)

			if not proximityPlayer then
				print "No player found"
				return
			end

			if proximityPlayer == player then
				descendant.Enabled = false
				return
			end

			scope:Hydrate(descendant) {
				Enabled = scope:Computed(function(use)
					local playerData = use(ClientState.external.roundData.playerData)[player.UserId]
					local proximityPlayerData = use(ClientState.external.roundData.playerData)[proximityPlayer.UserId]

					if not playerData then return false end

					local currentPhase = use(ClientState.external.roundData.currentPhaseType)

					if not RoundConfiguration.roundPhases[currentPhase] then return false end

					if playerData.team ~= proximityPlayerData.team then return false end
					if proximityPlayerData.status == Enums.PlayerStatus.dead then return false end

					local isHoldingBattery
					do
						local batteryDatas = use(ClientState.external.roundData.batteryData)

						for _, batteryData in pairs(batteryDatas) do
							if batteryData.holder == player.UserId then
								isHoldingBattery = true
								break
							end
						end
					end

					local isCrawling = use(ClientState.actions.isCrawling)
					local isShooting = playerData.actions.isShooting
					local isHacking = playerData.actions.isHacking
					local isAlive = playerData.status == Enums.PlayerStatus.alive

					return not isCrawling and not isShooting and not isHacking and isAlive and isHoldingBattery
				end),
			}
		end
	end
end

workspace.DescendantAdded:Connect(onDescendantAdded)

for _, descendant in ipairs(workspace:GetDescendants()) do
	onDescendantAdded(descendant)
end
