local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local Players = game:GetService "Players"

local dataFolder = ReplicatedStorage:WaitForChild "Data"

local ClientState = require(dataFolder:WaitForChild "ClientState")
local CRDU = require(dataFolder:WaitForChild("RoundData"):WaitForChild "ClientRoundDataUtility")
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

					local isShooting = playerData.actions.isShooting
					local isHacking = playerData.actions.isHacking
					local isAlive = playerData.status == Enums.PlayerStatus.alive

					local isHoldingBattery = use(CRDU.isHoldingBattery)

					return not isShooting and not isHacking and isAlive and not isHoldingBattery
				end),
			}
		elseif descendant.Name == "Terminal" then
			local rootTerminalModel = descendant:FindFirstAncestor "Terminal" :: Folder
			local terminalIdValue = rootTerminalModel:WaitForChild "Id" :: IntValue
			local terminalId = terminalIdValue.Value

			if terminalId == 0 then
				local timeElapsed = 0

				repeat
					timeElapsed += task.wait()
				until terminalIdValue.Value ~= 0 or timeElapsed >= 60 -- this only happens in an edge case where the map is deleted before stuff laods

				terminalId = terminalIdValue.Value

				if terminalId == 0 then
					warn "Terminal ID is still 0 after waiting"
					return
				end
			end

			scope:Hydrate(descendant) {
				Enabled = scope:Computed(function(use)
					local playerData = use(ClientState.external.roundData.playerData)[player.UserId]

					if not playerData then return false end

					if playerData.team == Enums.TeamType.hunters then return false end

					local currentPhase = use(ClientState.external.roundData.currentPhaseType)

					if not RoundConfiguration.terminalPhases[currentPhase] then return false end

					local parkourState = use(ClientState.actions.parkourState)
					local isShooting = playerData.actions.isShooting
					local isHacking = playerData.actions.isHacking
					local isAlive = playerData.status == Enums.PlayerStatus.alive
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

					local terminalData
					do
						local terminalDatas = use(ClientState.external.roundData.terminalData)

						for _, data in pairs(terminalDatas) do
							if data.id == terminalId then
								terminalData = data
								break
							else
							end
						end
					end
					if not terminalData then
						warn("Terminal data not found: " .. terminalId)
						return false
					end
					if terminalData.progress >= 100 then return false end

					return parkourState == Enums.ParkourState.grounded
						and not isShooting
						and not isHacking
						and isAlive
						and not isHoldingBattery
				end),
			}
		elseif descendant.Name == "HealRobot" then
			local proximityPlayer = Players:GetPlayerFromCharacter(descendant.Parent.Parent)

			if not proximityPlayer then return end

			if proximityPlayer == player then
				descendant.Enabled = false
				return
			end

			scope:Hydrate(descendant) {
				Enabled = scope:Computed(function(use)
					local playerData = use(ClientState.external.roundData.playerData)[player.UserId]
					local proximityPlayerData = use(ClientState.external.roundData.playerData)[proximityPlayer.UserId]

					if not proximityPlayerData then
						-- print(proximityPlayer, proximityPlayer.Name, proximityPlayer.UserId)
						return false
					end

					if not playerData then return false end

					local currentPhase = use(ClientState.external.roundData.currentPhaseType)

					if not RoundConfiguration.roundPhases[currentPhase] then return false end

					if playerData.team ~= proximityPlayerData.team then return false end
					if proximityPlayerData.status == Enums.PlayerStatus.dead then return false end
					if proximityPlayerData.health >= 100 then return false end

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

					local isShooting = playerData.actions.isShooting
					local isHacking = playerData.actions.isHacking
					local isAlive = playerData.status == Enums.PlayerStatus.alive

					return not isShooting and not isHacking and isAlive and isHoldingBattery
				end),
			}
		end
	end
end

workspace.DescendantAdded:Connect(onDescendantAdded)

for _, descendant in ipairs(workspace:GetDescendants()) do
	onDescendantAdded(descendant)
end
