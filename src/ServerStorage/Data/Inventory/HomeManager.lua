local LOADED_ITEM_ATTRIBUTE = "ItemId" -- This is the attribute that is set on items that are loaded into the game

local Players = game:GetService "Players"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerStorage = game:GetService "ServerStorage"
-- local TeleportService = game:GetService "TeleportService"

local serverStorageShared = ServerStorage.Shared
-- local replicatedFirstVendor = ReplicatedFirst.Vendor
local replicatedFirstShared = ReplicatedFirst.Shared
local dataServerStorage = serverStorageShared.Data
local inventoryServerStorage = dataServerStorage.Inventory
local replicatedStorageShared = ReplicatedStorage.Shared
-- local dataReplicatedStorage = replicatedStorageShared.Data
-- local inventoryReplicatedStorage = dataReplicatedStorage.Inventory
local enums = replicatedFirstShared.Enums
local serverFolder = replicatedStorageShared.Server
local utilityFolder = replicatedFirstShared.Utility
local configurationFolder = replicatedFirstShared.Configuration

local InventoryManager = require(inventoryServerStorage.InventoryManager)
local PlayerDataManager = require(dataServerStorage.PlayerDataManager)
-- local Items = require(inventoryReplicatedStorage.Items)
local ItemCategory = require(enums.ItemCategory)
-- local HomeType = require(enums.ItemTypeHome)
local PlayerDataConfig = require(replicatedFirstShared.Configuration.PlayerDataConfig)
local ServerGroupEnum = require(enums.ServerGroup)
local ServerTypeGroups = require(configurationFolder.ServerTypeGroups)
local SpacialQuery = require(utilityFolder.SpacialQuery)
local Serialization = require(utilityFolder.Serialization)
-- local ServerData = require(serverStorageShared.ServerManagement.ServerData)
-- local Promise = require(replicatedFirstVendor.Promise)
local Types = require(utilityFolder.Types)
local LocalServerInfo = require(serverFolder.LocalServerInfo)

type HomeServerInfo = Types.HomeServerInfo
type UserEnum = Types.UserEnum
type InventoryItem = Types.InventoryItem
type PlacedItem = Types.PlacedItem
type Promise = Types.Promise
type ServerIdentifier = Types.ServerIdentifier

local isHomeServer = ServerTypeGroups.serverInGroup(ServerGroupEnum.isHome)

local placedItemsFolder
if isHomeServer then
	placedItemsFolder = workspace:FindFirstChild "PlacedItems" or Instance.new "Folder"
	placedItemsFolder.Name = "PlacedItems"
	placedItemsFolder.Parent = workspace
end

--[[
	Gets a loaded item from an item id. This returns an instance or nil if the item is not loaded.
]]
local function getLoadedItemFromId(itemId: string): Instance?
	for _, placedItem in pairs(placedItemsFolder:GetChildren()) do
		if placedItem:GetAttribute(LOADED_ITEM_ATTRIBUTE) == itemId then return placedItem end
	end

	return
end

--[[
	Gets all loaded items in the game. This returns a table of item ids to instances.
]]
-- local function getLoadedItems()
-- 	local loadedItems = {}

-- 	for _, placedItem in pairs(placedItemsFolder:GetChildren()) do
-- 		local itemId = placedItem:GetAttribute(LOADED_ITEM_ATTRIBUTE)

-- 		if itemId then loadedItems[itemId] = placedItem end
-- 	end

-- 	return loadedItems
-- end

--[[
	Gets the home owner user id of the home. This returns a number or nil if the server is not a home server.
]]
local function getHomeOwner()
	local serverIdentifier = LocalServerInfo.getServerIdentifier()

	return if serverIdentifier then serverIdentifier.homeOwner else nil
end

local HomeManager = {}

--[[
	Gets the index of the home that a player is selecting.
	* `userId` is the user id of the player. If this is nil, it will use the home owner of the server.

	The player does not need to be in this server.

	Returns a success boolean and the index of the home that the player is selecting if successful.
]]
function HomeManager.getSelectedHomeIndex(userId: number?): (boolean, number?)
	userId = userId or getHomeOwner()

	local success, itemId = HomeManager.getSelectedHomeId(userId)
	if not success then return false end

	local getItemPathSuccess, _, index = InventoryManager.getItemPathFromId(userId :: number, itemId)
	return getItemPathSuccess, index
end

--[[
	Gets the itemId of a home that a player has selected.

	* `userId` is the user id of the player. If this is nil, it will use the home owner of the server.
	* The player does not need to be in this server.

	Returns a success boolean and the itemId of the home that the player has selected.
]]
function HomeManager.getSelectedHomeId(userId: number?)--: (boolean, string?)
	-- userId = userId or getHomeOwner()

	-- return PlayerSettings.getSetting(userId :: number, "selectedHome")
end

--[[
	Sets the selected home id for the player. The player needs to be in this server.
	Does not return anything, but will throw an error if the player is not in this server.
]]
function HomeManager.setSelectedHomeId(userId: number?, itemId: string)
	-- userId = userId or getHomeOwner()

	-- PlayerSettings.setSetting(userId :: number, "selectedHome", itemId)
end

--[[
	Gets the lock status of a player's home. The player does not need to be in this server.

	Returns a success boolean and the lock status of the player's home if successful.
]]
function HomeManager.getLockStatus(userId: number?)--: (boolean, UserEnum?)
	-- userId = userId or getHomeOwner()

	-- return PlayerSettings.getSetting(userId :: number, "homeLockStatus")
end

--[[
	Sets the lock status (HomeLockType.lua) of a player's home. The player needs to be in this server.
	Does not return anything, but will throw an error if the player is not in this server.
]]
function HomeManager.setLockStatus(userId: number?, lockStatus: UserEnum)
	-- userId = userId or getHomeOwner()

	-- PlayerSettings.setSetting(userId :: number, "homeLockStatus", lockStatus)
end

--[[
	Gets the home of a player. `slot` can be an `itemId`, index to the homes inventory caregory, or `nil`.
	* If `slot` is an `itemId`, it will return the home with that id.
	* If `slot` is an index, it will return the home at that index in the homes inventory category.
	* If `slot` is `nil`, it will return the home that the player or home owner has selected.

	The player does not need to be in this server.

	Returns a success boolean and the home if successful.
	If success is true, the home will only be nil if the player does not have the specified home.
]]
function HomeManager.getHome(userId: number?, slot: string | number | nil): (boolean, InventoryItem?)
	userId = userId or getHomeOwner()
	assert(userId, "userId is nil, and it is not a home server.")

	local homes = InventoryManager.getHomes(userId)

	if not homes then return false end

	if type(slot) == "string" then
		for _, home in pairs(homes) do
			if home.id == slot then return true, home end
		end

		return true
	elseif type(slot) == "number" then
		return true, homes[slot]
	else -- type(slot) == "nil"
		local success, selectedHomeId = HomeManager.getSelectedHomeId(userId)

		if not success then return false end

		local item

		for _, home in pairs(homes) do
			if home.id == selectedHomeId then
				item = home
				break
			end
		end

		return true, item
	end
end

--[[
	Gets the home server info of a player. The player does not need to be in this server.
	If there was an error getting the player's data, this will return nil.

	```luam
	homeServerInfo = {
		privateServerId = string,
		serverCode = string,
	},
	```
]]
function HomeManager.getHomeServerInfo(userId: number?): HomeServerInfo
	userId = userId or getHomeOwner()

	local profile = PlayerDataManager.viewOfflinePersistentDataAsync(userId :: number)

	return profile and profile.playerInfo.homeServerInfo
end

--[[
	Gets whether the home serverIdentifier is stamped. The player does not need to be in this server.
	Returns a success boolean and the stamped status of the home serverIdentifier if successful.

	A home serverIdentifier is stamped if, in the ServerData datastore, the privateServerId key has the serverIdentifier.
]]
function HomeManager.isHomeIdentifierStamped(userId: number?): (boolean, boolean?)
	userId = userId or getHomeOwner()

	local profile = PlayerDataManager.viewOfflinePersistentDataAsync(userId :: number)

	if profile then return true, profile.playerInfo.homeInfoStamped end

	return false
end

--[[
	Gets the placed items of a player's active or specified home.
	If no player is specified, it will use the home owner of the server.

	`slot` can be an `itemId`, index to the homes inventory caregory, or `nil`.
	* If `slot` is an `itemId`, it will use the home with that id.
	* If `slot` is an index, it will use the home at that index in the homes inventory category.
	* If `slot` is `nil`, it will use the home that the player or home owner has selected.

	Returns a success boolean and the placed items if successful.
]]
function HomeManager.getPlacedItems(userId: number, slot: string | number | nil): (boolean, { PlacedItem }?)
	userId = userId or getHomeOwner()

	local success, home = HomeManager.getHome(userId, slot)

	if not success then return false end
	assert(home, "HomeManager.getPlacedItems: No home with the specified slot was found.")

	return true, home.placedItems
end

--[[
	Gets a placed item from the given item id.
	If no user is specified, it will use the home owner of the server.

	`slot` can be an `itemId`, index to the homes inventory caregory, or `nil`.
	* If `slot` is an `itemId`, it will use the home with that id.
	* If `slot` is an index, it will use the home at that index in the homes inventory category.
	* If `slot` is `nil`, it will use the home that the player or home owner has selected.

	A `PlacedItem` is a table with the following structure:
	```lua
	PlacedItem = {
		itemId: string,
		pivotCFrame: CFrame | table,
	}
	```

	Returns a success boolean and the placed item if successful.
]]
function HomeManager.getPlacedItemFromId(
	itemId: string,
	userId: number?,
	slot: string | number | nil
): (boolean, PlacedItem?)
	userId = userId or getHomeOwner()

	local success, placedItems = HomeManager.getPlacedItems(userId :: number, slot)

	if not success then return false end

	for _, placedItem in ipairs(placedItems) do
		if placedItem.itemId == itemId then return true, placedItem end
	end

	return false
end

--[[
	Returns a success boolean and a boolean indicating whether the given item is
	placed in the player's active or specified home.

	If no userId is specified, it will use the home owner of the server.

	`slot` can be an `itemId`, index to the homes inventory caregory, or `nil`.
	* If `slot` is an `itemId`, it will use the home with that id.
	* If `slot` is an index, it will use the home at that index in the homes inventory category.
	* If `slot` is `nil`, it will use the home that the player or home owner has selected.
]]
function HomeManager.isItemPlaced(itemId, userId: number?, slot: string | number | nil): (boolean, boolean?)
	userId = userId or getHomeOwner()

	local success, placedItem = HomeManager.getPlacedItemFromId(itemId, userId, slot)

	if not success then return false end

	return true, placedItem and true or false
end

--[[
	Returns a success boolean and a boolean indicating whether the specified home is at its max placed items.

	If no userId is specified, it will use the home owner of the server.

	`slot` can be an `itemId`, index to the homes inventory caregory, or `nil`.
	* If `slot` is an `itemId`, it will use the home with that id.
	* If `slot` is an index, it will use the home at that index in the homes inventory category.
	* If `slot` is `nil`, it will use the home that the player or home owner has selected.
]]
function HomeManager.isPlacedItemsFull(userId: number?, numItemsToAdd: number?, slot: string | number | nil)
	userId = userId or getHomeOwner()
	assert(userId)

	numItemsToAdd = numItemsToAdd or 0
	assert(numItemsToAdd)
	local maxFurniturePlaced = PlayerDataConfig.inventoryLimits.furniture

	local success, placedItems = HomeManager.getPlacedItems(userId, slot)

	if not success then return false end

	if #placedItems + numItemsToAdd > maxFurniturePlaced or #placedItems == maxFurniturePlaced then
		return true, true
	end

	return true, false
end

--[[
	Returns a success boolean and a boolean indicating whether an item can be placed
	based on the provided itemId and pivotCFrame.

	Conditions tested:
	* Placed items is full
	* Player owns item
	* Not placed in the air

	Can only be called on a home server.
]]
function HomeManager.canPlaceItem(itemId: string, pivotCFrame: CFrame)
	local homeOwner = getHomeOwner()

	assert(homeOwner, "HomeManager.placeItem: No home owner found.")

	local success, isPlacedItemsFull = HomeManager.isPlacedItemsFull(homeOwner, 1)

	if not success then
		warn "HomeManager.placeItem: No success when checking if placed items is full"
		return false
	end

	local playerOwnsSuccess, playerOwnsItem = InventoryManager.playerOwnsItem(homeOwner, itemId)

	if not playerOwnsSuccess then
		warn "HomeManager.placeItem: No success when checking if player owns item"
		return false
	end

	if isPlacedItemsFull and not playerOwnsItem then
		warn "HomeManager.placeItem: Placed items is full or player does not own item"
		warn("isPlacedItemsFull: " .. tostring(isPlacedItemsFull))
		warn("playerOwnsItem: " .. tostring(playerOwnsItem))
		return true, false
	end

	return true, SpacialQuery.getPartsTouchingPoint(pivotCFrame)[1] ~= nil
end

--[[
	Loads (or places), a placed item into the home on a home server using the given placed item.

	Can only be called on a home server.
]]
function HomeManager.loadPlacedItem(placedItem: PlacedItem)
	-- assert(isHomeServer, "HomeManager.loadPlacedItem: Can only be called on a home server.")

	-- local homeOwner = getHomeOwner()

	-- local itemId = placedItem.itemId
	-- local pivotCFrame: CFrame = Serialization.deserialize(placedItem.pivotCFrame)

	-- local success, item = InventoryManager.getItemFromId(homeOwner, placedItem.itemId)

	-- if not success then return false end
	-- assert(item, "HomeManager.loadPlacedItem: item does not exist in inventory")

	-- local info = Items.getFurnitureItem(item.itemEnum)
	-- local object = getLoadedItemFromId(itemId)

	-- object = object or info.model:Clone()

	-- object:SetAttribute(LOADED_ITEM_ATTRIBUTE, itemId)
	-- object:PivotTo(pivotCFrame)
	-- object.Parent = placedItemsFolder

	-- print("HomeManager.loadPlacedItem: loaded item", itemId)

	-- return true
end

--[[
	Unloads (or removes), a placed item from the home server using the given placed item.
]]
function HomeManager.unloadPlacedItem(placedItem: PlacedItem)
	assert(isHomeServer, "HomeManager.unloadPlacedItem: Can only be called on a home server.")

	local object = getLoadedItemFromId(placedItem.itemId)

	if object then object:Destroy() end
end

--[[
	Adds/creates a placed item in a player's placedItems. The item is loaded right after.
	The placedItems table is located in every home that a player owns.

	Returns a success boolean.

	Can only be called on a home server.
]]
function HomeManager.addPlacedItem(itemId: string, pivotCFrame: CFrame)
	local homeOwner = getHomeOwner()
	assert(homeOwner, "HomeManager.addPlacedItem: No home owner found.")

	local player = Players:GetPlayerByUserId(homeOwner)

	assert(
		player and PlayerDataManager.persistentDataIsLoaded(player),
		"HomeManager.addPlacedItem: No player data found."
	)

	local success, placedItem = HomeManager.getPlacedItemFromId(itemId, homeOwner)

	if not success then
		warn "HomeManager.addPlacedItem: No success when getting placed item from id"
		return false
	end

	local getPlacedItemsSuccess, placedItems = HomeManager.getPlacedItems(homeOwner)

	if not getPlacedItemsSuccess then
		warn "HomeManager.addPlacedItem: No success when getting placed items"
		return false
	end

	local getIndexSuccess, selectedHomeIndex = HomeManager.getSelectedHomeIndex(homeOwner)

	if not selectedHomeIndex or not getIndexSuccess then
		warn "HomeManager.addPlacedItem: No success when getting selected home index"
		return false
	end

	placedItem = placedItem or {} :: PlacedItem
	placedItem.pivotCFrame = Serialization.serialize(pivotCFrame)
	placedItem.itemId = itemId

	local path = { "inventory", "homes", selectedHomeIndex, "placedItems" }

	if placedItem then
		local placedItemIndex = table.find(placedItems, placedItem)

		if not placedItemIndex then
			warn "HomeManager.addPlacedItem: Placed item not found in placed items"
			return false
		end

		PlayerDataManager.arraySetPersistent(player, path, placedItemIndex, placedItem)
	else
		PlayerDataManager.arrayInsertPersistent(player, path, placedItem)
	end

	return HomeManager.loadPlacedItem(placedItem)
end

--[[
	Removes a placed item from a player's placedItems. The item is unloaded right after.
	Can be called from a non-home server.

	Returns a success boolean.
]]
function HomeManager.removePlacedItem(itemId: string, userId: number?)
	userId = userId or getHomeOwner()
	assert(userId, "HomeManager.removePlacedItem: No user id found.")

	local player = Players:GetPlayerByUserId(userId)

	assert(player and PlayerDataManager.persistentDataIsLoaded(player), "Player data not found")

	local success, placedItem = HomeManager.getPlacedItemFromId(itemId, userId)
	if not success then
		warn "Placed item not found"
		return false
	end
	assert(placedItem, "Placed item not found")

	local getPlacedSuccess, placedItems = HomeManager.getPlacedItems(userId)
	if not getPlacedSuccess then
		warn "Placed items not found"
		return false
	end

	local selectedSuccess, selectedHomeIndex = HomeManager.getSelectedHomeIndex(userId)
	if not selectedSuccess or not selectedHomeIndex then
		warn "Selected home index not found"
		return false
	end

	local placedItemIndex = table.find(placedItems, placedItem)
	if not placedItemIndex then
		warn "Placed item index not found"
		return false
	end

	local path = { "inventory", "homes", selectedHomeIndex, "placedItems" }

	PlayerDataManager.arrayRemovePersistent(player, path, placedItemIndex)

	if isHomeServer then HomeManager.unloadPlacedItem(placedItem) end

	return true
end

--[[
	Loads (places) all placed items found in a player's inventory into the workspace.
	Returns a success boolean.
]]
function HomeManager.loadItems()
	-- assert(isHomeServer, "HomeManager.loadItems: Can only be called on a home server.")

	-- local success, placedItems = HomeManager.getPlacedItems()

	-- if not success then
	-- 	warn "HomeManager.loadItems: No success when getting placed items"
	-- 	return false
	-- end

	-- local promises = {}

	-- for _, placedItem in pairs(placedItems) do
	-- 	table.insert(
	-- 		promises,
	-- 		Promise.new(function(resolve, reject)
	-- 			local success = HomeManager.loadPlacedItem(placedItem)

	-- 			if success then
	-- 				resolve()
	-- 			else
	-- 				reject()
	-- 			end
	-- 		end)
	-- 	)
	-- end

	-- return Promise.all(promises):await()
end

--[[
	Unloads all placed items found in a player's inventory from the workspace.
]]
function HomeManager.unloadItems()
	-- assert(isHomeServer, "HomeManager.unloadItems: Can only be called on a home server.")

	-- local success, placedItems = HomeManager.getPlacedItems()

	-- if not success then
	-- 	warn "HomeManager.unloadItems: No success when getting placed items"
	-- 	return false
	-- end

	-- for _, placedItem in pairs(placedItems) do
	-- 	HomeManager.unloadPlacedItem(placedItem)
	-- end

	-- return true
end

--[[
	Loads a home into the workspace by loading all placed items.

	Returns a success boolean.
]]
function HomeManager.loadHome()
	-- assert(isHomeServer, "HomeManager.loadHome can only be called in a home server")

	-- local success, home = HomeManager.getHome()

	-- if not success or not home then
	-- 	warn "HomeManager.loadHome: No success when getting home"
	-- 	return false
	-- end

	-- local homeInfo = Items.getHomeItem(home.itemEnum)
	-- local modelClone = homeInfo.model:Clone()
	-- modelClone.Name = "RenderedHome"
	-- modelClone.Parent = workspace

	-- return HomeManager.loadItems()
end

--[[
	Unloads a home from the workspace by deleting it.

	Does not return anything.
]]
function HomeManager.unloadHome()
	assert(isHomeServer, "HomeManager.unrenderHome can only be called in a home server")

	workspace:FindFirstChild("RenderedHome"):Destroy()
	placedItemsFolder:ClearAllChildren()
end

local function loadProfile(player: Player)
	-- LocalServerInfo.getServerIdentifier() -- Make sure server identifier is get

	-- local function onError() -- If initialization failed for a player
	-- 	warn "HomeManager: Initialization failed for player."
	-- end

	-- local userId = player.UserId
	-- local homes = InventoryManager.getHomes(userId)

	-- if #homes == 0 then
	-- 	InventoryManager.newItemInInventory(ItemCategory.home, HomeType.devHome, player, {
	-- 		permanent = true, -- We don't want users to be able to delete their default home
	-- 	})
	-- end

	-- homes = InventoryManager.getHomes(userId) -- Refresh homes variable

	-- local success, selectedHomeId = HomeManager.getSelectedHomeId(userId)

	-- if not success then
	-- 	warn "HomeManager: Failed to get selected home id"

	-- 	onError()
	-- 	return
	-- end

	-- if not selectedHomeId or not select(2, HomeManager.getHome(userId, selectedHomeId)) then
	-- 	HomeManager.setSelectedHomeId(userId, homes[1].id)
	-- end

	-- local homeServerInfo = HomeManager.getHomeServerInfo(userId)

	-- if not success then
	-- 	warn "HomeManager: Failed to get home server info"

	-- 	onError()
	-- 	return
	-- end

	-- if not (homeServerInfo and homeServerInfo.privateServerId and homeServerInfo.serverCode) then
	-- 	local function getReservedServer()
	-- 		return Promise.try(function()
	-- 			local code, privateServerId = TeleportService:ReserveServer(PlayerDataConfig.homePlaceId)

	-- 			if code and privateServerId then
	-- 				return code, privateServerId
	-- 			else
	-- 				return Promise.reject()
	-- 			end
	-- 		end)
	-- 	end

	-- 	local success = Promise.retry(getReservedServer, 5)
	-- 		:andThen(
	-- 			function(code, privateServerId)
	-- 				PlayerDataManager.setValuePersistent(player, { "playerInfo", "homeServerInfo" }, {
	-- 					serverCode = code,
	-- 					privateServerId = privateServerId,
	-- 				})
	-- 			end
	-- 		)
	-- 		:await()

	-- 	if not success then
	-- 		warn "HomeManager: Failed to get reserved server"

	-- 		onError()
	-- 		return
	-- 	end
	-- end

	-- local success, isStamped = HomeManager.isHomeIdentifierStamped(userId)

	-- if not success then
	-- 	warn "HomeManager: Failed to get home info stamped"

	-- 	onError()
	-- 	return
	-- end

	-- if not isStamped then
	-- 	print "Stamping home server..."

	-- 	local success, response = ServerData.stampHomeServer(player)

	-- 	if not success then
	-- 		warn("HomeManager: Failed to stamp home server: ", response)

	-- 		onError()
	-- 		return
	-- 	else
	-- 		print "Successfully stamped home server!"
	-- 	end
	-- end

	-- local success, placedItems = HomeManager.getPlacedItems(userId)

	-- if success then
	-- 	for _, placedItem in pairs(placedItems) do
	-- 		local success, doesOwn = InventoryManager.playerOwnsItem(userId, placedItem.itemId)

	-- 		if not success then
	-- 			warn "HomeManager: Failed to check if player owns item"

	-- 			onError()
	-- 			return
	-- 		end

	-- 		if not doesOwn then
	-- 			HomeManager.removePlacedItem(placedItem.itemId, userId) -- We don't really care if this fails
	-- 		end
	-- 	end
	-- else
	-- 	warn "HomeManager: Failed to get placed items"

	-- 	onError()
	-- 	return
	-- end

	-- if isHomeServer and getHomeOwner() == userId then
	-- 	for itemId in getLoadedItems() do
	-- 		local success, doesOwn = InventoryManager.playerOwnsItem(userId, itemId)

	-- 		if not success then
	-- 			warn "HomeManager: Failed to check if player owns item"

	-- 			onError()
	-- 			return
	-- 		end

	-- 		if not doesOwn then HomeManager.unloadPlacedItem(select(2, HomeManager.getPlacedItemFromId(itemId))) end
	-- 	end
	-- end
end

for _, player in PlayerDataManager.getPlayersWithLoadedPersistentData() do
	loadProfile(player)
end

PlayerDataManager.persistentDataLoaded:Connect(loadProfile)

InventoryManager.itemRemovedFromInventory:Connect(
	function(player: Player, itemCategory: UserEnum, _, item: InventoryItem)
		if itemCategory == ItemCategory.home then
			local success, selectedHomeId = HomeManager.getSelectedHomeId(player.UserId)

			if not success then
				warn "HomeManager itemRemovedFromInventory Fail: Failed to get selected home id"
				return
			end

			if selectedHomeId == item.id then
				local homes = InventoryManager.getHomes(player.UserId)

				if not homes then
					warn "HomeManager itemRemovedFromInventory Fail: Failed to get homes"
					return
				end

				HomeManager.setSelectedHomeId(player.UserId, homes[1].id)
			end
		elseif itemCategory == ItemCategory.furniture then
			local success, isPlaced = HomeManager.isItemPlaced(item.id, player.UserId)

			if not success then
				warn "HomeManager itemRemovedFromInventory Fail: Failed to check if item is placed"
				return
			end

			if isPlaced then HomeManager.removePlacedItem(item.id, player.UserId) end
		end
	end
)

return HomeManager
