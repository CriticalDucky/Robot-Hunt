local HttpService = game:GetService "HttpService"

local ReplicaRequest = {}

-- Creates a new ReplicaRequest using the given replica. It will FireServer the given arguments, and then wait for the response.
-- The response is a table of elements returned by the server. This is all wrapped in a Promise.
function ReplicaRequest.new(replica, ...)
	assert(replica, "ReplicaRequest.new() called with nil replica")

	local varargs = { ... }

	local requestCode = HttpService:GenerateGUID(false)
	local response

	local connection
	do
		connection = replica:ConnectOnClientEvent(function(returnedCode, ...)
			if returnedCode == requestCode then
				response = { ... }
				connection:Disconnect()
			end
		end)
	end

	replica:FireServer(requestCode, unpack(varargs))

	local startTime = time()

	while not response and time() - startTime < 5 do
		task.wait()
	end

	connection:Disconnect()

	return response
end

return ReplicaRequest
