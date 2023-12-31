--!strict

local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local RunService = game:GetService "RunService"
local ServerStorage = game:GetService "ServerStorage"

local isServer = RunService:IsServer()

local ClientState = if not isServer then require(ReplicatedStorage.Shared.Data.ClientState) else nil
local ClientServerCommunication = require(ReplicatedStorage.Shared.Data.ClientServerCommunication)
local Fusion = if not isServer then require(ReplicatedFirst.Vendor.Fusion) else nil
local PlayerDataManager = if isServer then require(ServerStorage.Shared.Data.PlayerDataManager) else nil

local peek = if Fusion then Fusion.peek else nil

local Homes = {}

function Homes.setSelectedHome(homeId: string, player: Player?)
	if isServer and not player then
		warn "A player must be provided when calling from the server."
		return
	elseif not isServer and player then
		warn "No player needs to be given when calling from the client, so this parameter will be ignored."
	end

	if isServer then
		assert(PlayerDataManager and player)

		if not PlayerDataManager.persistentDataIsLoaded(player) then
			warn "This player's persistent data has not been loaded, so the selected home cannot be set."
			return
		end

		local data = PlayerDataManager.getPersistentData(player)
		assert(data)

		if data.home.selected == homeId then return end

		if not data.inventory.homes[homeId] then
			warn(`This player does not own a home with ID ${homeId}.`)
			return
		end

		data.home.selected = homeId
		ClientServerCommunication.replicateAsync("SetSelectedHome", homeId, player)
	else
		assert(ClientState and Fusion and peek)

		if not peek(ClientState.inventory.homes)[homeId] then
			warn(`This player does not own a home with ID ${homeId}.`)
			return
		end

		ClientState.home.selected:set(homeId)
		ClientServerCommunication.replicateAsync("SetSelectedHome", homeId)
	end
end

return Homes
