local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ServerStorage = game:GetService "ServerStorage"

local GameLoop = ServerStorage.GameLoop

local Actions = require(GameLoop.Actions)
local RoundDataManager = require(GameLoop.RoundDataManager)
local Promise = require(ReplicatedFirst.Vendor.Promise)
local RoundConfiguration = require(ReplicatedStorage.Configuration.RoundConfiguration)
local Enums = require(ReplicatedFirst.Enums)

local Hiding = {}

function Hiding.begin()
	print "Hiding started"
	RoundDataManager.data.currentPhaseType = Enums.PhaseType.Hiding
	RoundDataManager.data.phaseStartTime = os.time()
	RoundDataManager.replicateDataAsync()

	local timer = Promise.delay(RoundConfiguration.timeLengths[Enums.RoundType.defaultRound][Enums.PhaseType.Hiding])

	return Promise.new(function(resolve, reject, onCancel)
		onCancel(function()
			print "Hiding cancelled"
			timer:cancel()
		end)

		timer:andThen(function()
			print "Hiding ended"
			resolve()
		end)
	end)
end

return Hiding
