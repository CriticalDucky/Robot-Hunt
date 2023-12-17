local ReplicatedFirst = game:GetService "ReplicatedFirst"

local Types = require(ReplicatedFirst:WaitForChild("Shared"):WaitForChild("Utility"):WaitForChild "Types")

type Promise = Types.Promise

local ReplicaResponse = {}

--[[
	This function is used for replica responses on a server. Pass in a Replica,
	and a callback that takes a player and any number of arguments, and returns any value(s).

	When the replica is fired, the callback will be called with the player and the arguments.
	Values returned from the callback will be passed to the client.
]]
function ReplicaResponse.listen(requestReplica, callback: (Player, ...any) -> any)
	requestReplica:ConnectOnServerEvent(function(player, requestCode, ...)
		requestReplica:FireClient(player, requestCode, callback(player, ...))
	end)
end

return ReplicaResponse
