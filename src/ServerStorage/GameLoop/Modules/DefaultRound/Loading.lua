local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ServerStorage = game:GetService "ServerStorage"

local GameLoop = ServerStorage.GameLoop
local Maps = ServerStorage.Maps

local Actions = require(GameLoop.Actions)
local RoundDataManager = require(GameLoop.RoundDataManager)
local Promise = require(ReplicatedFirst.Vendor.Promise)
local RoundConfiguration = require(ReplicatedStorage.Configuration.RoundConfiguration)
local ClientServerCommunication = require(ReplicatedStorage.Data.ClientServerCommunication)
local Enums = require(ReplicatedFirst.Enums)

local Loading = {}

function Loading.begin()
	print "Loading started"

	local loadingLength = RoundConfiguration.timeLengths.lobby[Enums.PhaseType.Loading]
	local endTime = os.time() + loadingLength

	local timer = Actions.newPhaseTimer(endTime)

	return Promise.new(function(resolve, reject, onCancel)
		onCancel(function()
			print "Loading cancelled"
			timer:cancel()
		end)

		local map = Maps:GetChildren()[math.random(1, #Maps:GetChildren())]:Clone()
		map.Parent = workspace
		map.Name = "Map"

		assert(map:FindFirstChild "Batteries", "Map must have a Batteries folder")

		timer:andThen(function()
			print "Loading ended"

			ClientServerCommunication.replicateAsync("MapLoadingFinished")

			resolve()
		end)

		RoundDataManager.setPhase(Enums.PhaseType.Loading, endTime)
	end)
end

return Loading
