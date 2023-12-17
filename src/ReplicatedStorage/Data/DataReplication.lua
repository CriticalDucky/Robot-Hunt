--#region Imports

local RunService = game:GetService "RunService"
local ServerStorage = game:GetService "ServerStorage"

local isServer = RunService:IsServer()

local PlayerDataManager = if isServer
	then require(ServerStorage:WaitForChild("Data"):WaitForChild "PlayerDataManager")
	else nil

--#endregion

--#region State Replication Management

local stateReplicationEvents: { [string]: RemoteEvent } = {}

--#endregion

--[[
	Manages state replication. This is used to replicate state changes from the server to the client and vice versa.
]]
local StateReplication = {}

--[[
	Replicates the given action(s) to the server or specified client (depending on where this function was called).

	---

	`action` is the name of the action to replicate.

	`data` is the data to replicate with the action. This can be any replicatable value.

	`player` is the client to replicate to, when called from the server. It is **required** on the server and
	**ignored** on the client.

	The given action must be registered for it to replicate. If it is not, this function will yield until it is. See
	`StateReplication.registerActionAsync` for more information.
]]
function StateReplication.replicateAsync(action: string, data: any, player: Player?)
	if isServer and not player then
		warn "Player parameter is missing, so no actions will be replicated."
		return
	elseif not isServer and player then
		warn "Player parameter is unnecessary on the client, so it will be ignored."
	end

	local actionEvent = stateReplicationEvents[action]

	if not actionEvent then
		local warned = false
		local totalTime = 0

		repeat
			if totalTime >= 5 and not warned then
				warned = true
				warn(`Infinite yield possible for action '{action}' to register.`)
			end

			totalTime += task.wait()

			actionEvent = stateReplicationEvents[action]
		until actionEvent
	end

	if isServer then
		actionEvent:FireClient(player, data)
	else
		actionEvent:FireServer(data)
	end
end

--[[
	Registers a state replication action. This adds it to the list of actions that can be replicated and sets up the
	handler function that will be called when the action is replicated to this context.

	---

	`name` is the name of the action to register. This is the name that will be used when replicating the action.

	`handler` is the function that will be called when the action is replicated. On the server, the first parameter is
	the player that replicated the action, while the second parameter is the action data. On the client, the first and
	only parameter is the action data. This parameter may be ommitted if the action will only be used to replicate to
	the opposite context.

	This function is available on both the client and server. The context of where this function is called determines
	whether the action is registered in that context only. For replication to work, the action must be registered in
	both contexts. (Requests will queue if necessary.)

	An action can only be registered once per context. Attempting to register an action again will fail.

	On the client, this function will yield until the action is registered on the server.

	When registering an action on the server with a handler, the provided handler should ensure that the given data is
	valid. If it is not, it should not accept the request and instead send a replication request back to the client
	with the current data to resync.

	On the server, you can assume that the player's persistent data is loaded when the handler is called. (This is
	because the inverse should never happen; and if it somehow does, the handler will automatically be ignored.)
]]
function StateReplication.registerActionAsync(name: string, handler: ((Player, any) -> () | (any) -> ())?)
	if stateReplicationEvents[name] then
		warn(`Action '{name}' is already registered. You cannot reregister an action.`)
		return
	end

	if isServer then
		local replicationEvent = Instance.new "RemoteEvent"
		replicationEvent.Name = name
		replicationEvent.Parent = script

		stateReplicationEvents[name] = replicationEvent

		if handler then
			replicationEvent.OnServerEvent:Connect(function(player, ...)
				if not PlayerDataManager.persistentDataIsLoaded(player) then return end

				(handler :: (Player, any) -> ())(player, ...)
			end)
		end
	else
		local replicationEvent = script:WaitForChild(name) :: RemoteEvent

		stateReplicationEvents[name] = replicationEvent

		if handler then replicationEvent.OnClientEvent:Connect(handler) end
	end
end

return StateReplication
