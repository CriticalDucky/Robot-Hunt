local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local Players = game:GetService "Players"

local ClientState = require(ReplicatedStorage:WaitForChild("Data"):WaitForChild "ClientState")

local Fusion = require(ReplicatedFirst:WaitForChild("Vendor"):WaitForChild "Fusion")

local Hydrate = Fusion.Hydrate
local Computed = Fusion.Computed

local player = Players.LocalPlayer

local function onDescendantAdded(descendant)
	if descendant:IsA "ProximityPrompt" then
		if descendant.Name == "Battery" then
			Hydrate(descendant) {
				Enabled = Computed(function(use)
					local playerData = use(ClientState.external.roundData.playerData)[player.UserId]

					if not playerData then return false end

					local isCrawling = use(ClientState.actions.isCrawling)
					local isShooting = playerData.actions.isShooting
					local isHacking = playerData.actions.isHacking

					return not isCrawling and not isShooting and not isHacking
				end),
			}
		elseif descendant.Name == "Terminal" then
			Hydrate(descendant) {
				Enabled = Computed(function(use)
					local playerData = use(ClientState.external.roundData.playerData)[player.UserId]

					if not playerData then return false end

					local isCrawling = use(ClientState.actions.isCrawling)
					local isShooting = playerData.actions.isShooting
					local isHacking = playerData.actions.isHacking

					return not isCrawling and not isShooting and not isHacking
				end),
			}
		end
	end
end

workspace.DescendantAdded:Connect(onDescendantAdded)

for _, descendant in ipairs(workspace:GetDescendants()) do
	onDescendantAdded(descendant)
end
