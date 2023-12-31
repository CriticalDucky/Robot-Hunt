--[[
	Provides an interface to the players inventory.

	An inventoryItem looks like this:
	```lua
	inventoryItem = {
		id: string, -- The id of the item. Typically looks like a 10 character string.
		itemCategory: UserEnum, -- The category of the item. (see below)
		itemEnum: string | number,
		placedItems: {}?,
		permanent: boolean?,
	},
	```

	The inventory table in the player's profile data is structured as follows.
	All three tables are arrays.
	```lua
	inventory = {
		accessories = {inventoryItem}, -- Accessories are items that one's character can wear.
		homeItems = {inventoryItem}, -- Home items (furniture, decorations, etc.) are items that can be placed or applied to a home. The enum name for this is "furniture"
		homes = {inventoryItem}, -- An array of homes that the player owns.
		-- more can be added here. To add a new category, visit PlayerDataConfig.lua and search for "inventory".
	},
	```

	This script offers functionality such as adding and removing items from the inventory.
	It also offers functionality to perform trades of items between players.
]]

local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerStorage = game:GetService "ServerStorage"

local replicatedFirstVendor = ReplicatedFirst.Vendor
local replicatedFirstShared = ReplicatedFirst.Shared
local replicatedStorageShared = ReplicatedStorage.Shared
local serverStorageShared = ServerStorage.Shared
local dataFolder = serverStorageShared.Data
local utilityFolder = replicatedFirstShared.Utility
local replicatedStorageData = replicatedStorageShared.Data
local replicatedStorageInventory = replicatedStorageData.Inventory
local enumsFolder = replicatedFirstShared.Enums

-- local Configuration = require(replicatedFirstShared.Configuration)
local PlayerDataManager = require(dataFolder.PlayerDataManager)
local Items = require(replicatedStorageInventory.Items)
local Table = require(utilityFolder.Table)
local Signal = require(replicatedFirstVendor.Signal.Signal)
-- local PlayerDataInfo = Configuration.PlayerDataInfo
local Id = require(utilityFolder.Id)
local Types = require(utilityFolder.Types)
local ItemCategory = require(enumsFolder.ItemCategory)

type InventoryItem = Types.InventoryItem
type ItemCategory = Types.ItemCategory
type UserEnum = Types.UserEnum

local function addPropsToItem(item: InventoryItem)
	-- local itemCategory = item.itemCategory

	-- local props = PlayerDataConfig.itemProps[itemCategory]

	-- if props then
	-- 	for propName, propValue in pairs(props) do
	-- 		if item[propName] == nil then item[propName] = Table.deepCopy(propValue) end
	-- 	end
	-- end

	return item
end

local InventoryManager = {}

--[[
	Removes an item from the player's inventory.
	- player is the player to remove the item from
	- itemCategory is the category of the item to remove
	- itemIndex is the index of the item to remove

	If no errors occur, assume the item was removed successfully.
]]
local function removeItem(player: Player, itemCategory: string, itemIndex: number)
	assert(player and itemCategory and itemIndex, "removeItem: Invalid arguments")

	assert(PlayerDataManager.persistentDataIsLoaded(player), "removeItem: Player data not found")

	local item = InventoryManager.getItemFromIndex(player.UserId, itemCategory, itemIndex)
	assert(item, "removeItem: Item not found")

	-- PlayerDataManager.arrayRemovePersistent(player, { "inventory", itemCategory }, itemIndex)
	InventoryManager.itemRemovedFromInventory:Fire(player, itemCategory, itemIndex, item)
end

--[[
	Internal function for adding an item to the player's inventory.
	- playerData is the player's data
	- itemCategory is the category of the item to add
	- item is the item to add

	You're expected to make all necessary checks before calling this function.
]]
local function addItem(player: Player, itemCategory: string, item: InventoryItem)
	assert(player and itemCategory and item, "addItem: Invalid arguments")

	assert(PlayerDataManager.persistentDataIsLoaded(player), "addItem: Player data not found")

	local isInventoryFull = select(2, InventoryManager.isInventoryFull(player.UserId, itemCategory, 1))
	assert(not isInventoryFull, "addItem: Inventory is full")

	InventoryManager.itemPlacingInInventory:Fire(player, itemCategory, item)

	-- PlayerDataManager.arrayInsertPersistent(player, { "inventory", itemCategory }, item)
end

--[[
	Internal function for changing the owner of items.
	If this function doesn't error, assume that the items were successfully changed.
	Make sure to perform the necessary sanity checks before calling this function.

	- If a current owner is provided but a new owner is not, the items will be removed from the current
	owner's inventory.
	- If a new owner is provided but a current owner is not, the items will be added to the new owner's
	inventory.
	- If both a current owner and a new owner are provided, the items will be removed from the current
	owner's inventory and added to the new owner's inventory. If the new owner's inventory is full, it will error.
]]
local function changeOwnerOfItems(items: { InventoryItem }, currentOwner: Player?, newOwner: Player?)
	assert(currentOwner or newOwner, "InventoryManager.changeOwnerOfItems: Both currentOwner and newOwner are nil")
	assert(#items > 0, "InventoryManager.changeOwnerOfItems: No items to change owner of")

	-- In this function, we don't need to check if retrieving the player data failed since the lack of player data is part of the sanity checks.

	local function checkIfInventoryWouldBeFull()
		for _, item in pairs(items) do
			local otherItemsOfSameCategory = {}

			for _, otherItem in pairs(items) do
				if otherItem.itemCategory == item.itemCategory then
					table.insert(otherItemsOfSameCategory, otherItem)
				end
			end

			assert(
				not select(
					2,
					InventoryManager.isInventoryFull(
						(newOwner :: Player).UserId,
						item.itemCategory,
						#otherItemsOfSameCategory
					)
				),
				"InventoryManager.changeOwnerOfItems: Inventory would be full for: " .. (item.itemCategory or "nil")
			)
		end
	end

	if currentOwner then
		assert(
			select(2, InventoryManager.playerOwnsItems(currentOwner.UserId, items)),
			"InventoryManager.changeOwnerOfItems: Player does not own items"
		)
	end

	if newOwner and currentOwner then
		assert(
			PlayerDataManager.persistentDataIsLoaded(currentOwner)
				and PlayerDataManager.persistentDataIsLoaded(newOwner),
			"InventoryManager.changeOwnerOfItems: Player data not found"
		)

		checkIfInventoryWouldBeFull()

		for _, item in pairs(items) do
			local itemCategory, index = InventoryManager.getItemPathFromId(currentOwner.UserId, item.id)

			assert(itemCategory and index, "InventoryManager.changeOwnerOfItems: Item path from id not found")

			removeItem(currentOwner, itemCategory, index)
			addItem(newOwner, itemCategory, item)
		end
	elseif currentOwner and not newOwner then
		assert(
			PlayerDataManager.persistentDataIsLoaded(currentOwner),
			"InventoryManager.changeOwnerOfItems: Player data not found"
		)

		for _, item in pairs(items) do
			local itemCategory, index = InventoryManager.getItemPathFromId(currentOwner.UserId, item.id)

			assert(itemCategory and index, "InventoryManager.changeOwnerOfItems: Item path from id not found")

			removeItem(currentOwner, itemCategory, index)
		end
	elseif not currentOwner and newOwner then
		assert(
			PlayerDataManager.persistentDataIsLoaded(newOwner),
			"InventoryManager.changeOwnerOfItems: Player data not found"
		)

		checkIfInventoryWouldBeFull()

		for _, item in pairs(items) do
			addItem(newOwner, item.itemCategory, item)
		end
	end
end

InventoryManager.itemPlacingInInventory = Signal.new()
InventoryManager.itemRemovedFromInventory = Signal.new()

--[[
	Returns the inventory table in the player's profile data.

	Can return nil in the rare case retrieving the player's profile data fails.
]]
function InventoryManager.getInventory(userId: number)
	local profileData = PlayerDataManager.viewOfflinePersistentDataAsync(userId)
	return profileData and profileData.inventory
end

--[[
	Returns the inventory category table in the player's profile data.

	Can return nil in the rare case retrieving the player's profile data fails.
]]
function InventoryManager.getInventoryCategory(userId: number, itemCategory: UserEnum): ItemCategory?
	local inventory = InventoryManager.getInventory(userId)

	return inventory and inventory[itemCategory]
end

--[[
	Returns the accessories inventory table in the player's profile data.

	Can return nil in the rare case retrieving the player's profile data fails.
]]
function InventoryManager.getAccessories(userId: number): ItemCategory?
	return InventoryManager.getInventoryCategory(userId, ItemCategory.accessory)
end

--[[
	Returns the furniture (home items) inventory table in the player's profile data.

	Can return nil in the rare case retrieving the player's profile data fails.
]]
function InventoryManager.getFurniture(userId: number): ItemCategory?
	return InventoryManager.getInventoryCategory(userId, ItemCategory.furniture)
end

--[[
	Returns the homes inventory table in the player's profile data.

	Can return nil in the rare case retrieving the player's profile data fails.
]]
function InventoryManager.getHomes(userId: number): ItemCategory?
	return InventoryManager.getInventoryCategory(userId, ItemCategory.home)
end

--[[
	Gets the item from the specified inventory category with the specified index and returns:
	1. A boolean indicating whether player data was successfully retrieved. If this is false, disregard the item returned.
	2. The item if it was found, or nil if it was not found
]]
function InventoryManager.getItemFromIndex(
	userId: number,
	itemCategory: UserEnum,
	itemIndex: number
): (boolean, InventoryItem?)
	local inventoryCategory = InventoryManager.getInventoryCategory(userId, itemCategory)

	if inventoryCategory then
		return true, inventoryCategory[itemIndex]
	else
		return false, nil
	end
end

--[[
	- `userId` is the id of the player to search for the item in.
	- `itemId` is the id of the item to search for.

	Returns:
	- Success boolean
	- The item from the player's inventory with the specified id
	- The item category
	- The item index in that category

	The first return statement is a boolean indicating the success of getting the player data.
	This is necessary because a player data request may fail, and the item returned may be nil.
	These two cases are indistinguishable without this return statement.
]]
function InventoryManager.getItemFromId(userId: number, itemId: string): (boolean, InventoryItem?, UserEnum?, number?)
	local inventory = InventoryManager.getInventory(userId)

	if not inventory then
		return false -- player data request failed
	end

	for itemCategory: UserEnum, items: { InventoryItem } in pairs(inventory) do
		for index, item: InventoryItem in items do
			if item.id == itemId then return true, item, itemCategory, index end
		end
	end

	return true -- item not found, but player data request succeeded
end

--[[
	Returns the item category and index of the item with the specified id.
	Wrapper for InventoryManager.getItemFromId.

	Returns:
	- Success boolean
	- The item category
	- The item index in that category

	The first return statement is a boolean indicating the success of getting the player data.
	This is necessary because a player data request may fail, and the item returned may be nil.
	These two cases are indistinguishable without this return statement.
]]
function InventoryManager.getItemPathFromId(userId: number, itemId: string)
	local success, _, itemCategory, index = InventoryManager.getItemFromId(userId, itemId)

	return success, itemCategory, index
end

--[[
	Returns success boolean and a boolean indicating whether or not the player owns the specified item.
	If the success boolean is false, disregard the second return statement. An error occurred retrieving the player's profile data.
	Natural language wrapper for InventoryManager.getItemFromId.

	If there was an error retrieving the player's profile data, this function will return nil.
]]
function InventoryManager.playerOwnsItem(userId: number, itemId)
	local success, item = InventoryManager.getItemFromId(userId, itemId)

	if success then
		return true, item ~= nil
	else
		return false
	end
end

--[[
	Returns:
	1. Success boolean (if there was an error retrieving the player's profile data, this will be false)
	2. A boolean indicating whether or not the player owns all of the specified items

	The first return statement is a boolean indicating the success of getting the player data.
	This is necessary because a player data request may fail, and the item returned may be nil.
	These two cases are indistinguishable without this return statement.

	Example usage:
	```lua
	local success, ownsAllItems = InventoryManager.playerOwnsItems(userId, { "itemId", InventoryItem })

	if success then
		if ownsAllItems then
			-- player owns all items
		else
			-- player does not own all items
		end
	else
		-- error retrieving player data
	end
	```
]]
function InventoryManager.playerOwnsItems(userId: number, itemIds: { string | InventoryItem }): (boolean, boolean?)
	for _, itemId in pairs(itemIds) do
		local success, playerOwnsItem =
			InventoryManager.playerOwnsItem(userId, if type(itemId) == "string" then itemId else itemId.id)

		if not success then
			return false
		elseif not playerOwnsItem then
			return true, false
		end
	end

	return true, true
end

--[[
	Returns a a player data retrieval success bolean along with
	a boolean indicating if the player's inventory is full.
	- userId is the id of the player to check
	- itemCategory is the category of the item to add
	- numItemsToAdd is the number of items to add (optional, defaults to 0)

	The first return statement is a boolean indicating the success of getting the player data.
	This is necessary because a player data request may fail, and the item returned may be nil.
	These two cases are indistinguishable without this return statement.

	Example useage:

	```lua
	local userId = 123456789
	local itemCategory = ItemCategory.accessory
	local numItemsToAdd = 1

	local success, isFull = InventoryManager.isInventoryFull(userId, itemCategory, numItemsToAdd)

	if not success then
		error("Failed to retrieve player data")
	end

	if isFull then
		-- The player's inventory is full
	end
	```
]]

function InventoryManager.isInventoryFull(
	userId: number,
	itemCategory: UserEnum,
	numItemsToAdd: number?
)
	-- assert(userId and itemCategory, "InventoryManager.isInventoryFull: Invalid arguments")

	-- numItemsToAdd = numItemsToAdd or 0

	-- local inventoryCategory = InventoryManager.getInventoryCategory(userId, itemCategory)

	-- if not inventoryCategory then return false, nil end

	-- local numItems = #inventoryCategory
	-- local limit = PlayerDataInfo.inventoryLimits[itemCategory]

	-- if numItems == limit then return true, true end

	-- if numItems + numItemsToAdd > limit then return true, true end

	-- return true, false
end

--[[
	Returns a new item.
	- itemCategory is the category of the item to add
	- itemEnum is the enum of the item to add
	- props is a table of properties to add to the item (optional)

	You're expected to add the item to the player's inventory yourself.
]]
function InventoryManager.newItem(itemCategory: UserEnum, itemEnum: UserEnum, props: {}?): InventoryItem
	assert(itemCategory and itemEnum, "InventoryManager.newItem: Invalid arguments")
	assert(Items.getItem(itemCategory, itemEnum), "InventoryManager.newItem: Item does not exist")

	local item = addPropsToItem {
		id = Id.generate(), -- Chance of collision is: 64^10: 1 in 1152921504606846976. Not bad.
		itemCategory = itemCategory,
		itemEnum = itemEnum,
	}

	return if props then Table.merge(if table.isfrozen(props) then Table.deepCopy(props) else props, item) else item
end

--[[
	Adds an array of items to an *online* player's inventory. Will error if sanity checks fail.

	Does not return anything.
]]
function InventoryManager.addItemsToInventory(items: { InventoryItem }, player: Player)
	return changeOwnerOfItems(items, nil, player)
end

--[[
	Removes an array of items from an *online* player's inventory. Will error if sanity checks fail.

	Does not return anything.
]]
function InventoryManager.removeItemsFromInventory(items: { InventoryItem }, player: Player)
	return changeOwnerOfItems(items, player, nil)
end

--[[
	Creates a new item and puts in in the player's inventory using the specified itemCategory and itemEnum.
	Players must be online and in the same server. Will error if sanity checks fail.

	Does not return anything.
]]
function InventoryManager.newItemInInventory(
	itemCategory: UserEnum,
	itemEnum: UserEnum,
	player: Player,
	props: { [string]: any }?
)
	assert(itemCategory and itemEnum and player, "InventoryManager.newItemInInventory: Missing argument(s)")

	local item = InventoryManager.newItem(itemCategory, itemEnum, props)

	InventoryManager.addItemsToInventory({ item }, player)
end

--[[
	Crude way to reconcile item props with the player's inventory. Will replace this function with a better one later.
]]
local function reconcileItems(player) -- just like the function above, but no promises
	-- local success, inventory = InventoryManager.getInventory(player.userId)

	-- assert(PlayerDataManager.persistentDataIsLoaded(player), "reconcileItems: Player profile not loaded")

	-- if not success or not inventory then return end

	-- for itemCategory, items in pairs(inventory) do
	-- 	local propTemplate = PlayerDataConfig.itemProps[itemCategory]

	-- 	if not propTemplate then continue end

	-- 	for itemIndex, item in ipairs(items) do
	-- 		Table.recursiveIterate(propTemplate, function(path, value)
	-- 			local function index(t, indexPath)
	-- 				local element = t

	-- 				for _, i in ipairs(indexPath) do
	-- 					element = element[i]
	-- 				end

	-- 				return element
	-- 			end

	-- 			if index(item, Table.copy(path)) == nil then
	-- 				PlayerDataManager.setValuePersistent(
	-- 					player,
	-- 					{ "inventory", itemCategory, itemIndex, table.unpack(path) },
	-- 					Table.deepCopy(value)
	-- 				)
	-- 			end
	-- 		end)
	-- 	end
	-- end

	-- return true
end

-- For all player data that's loaded in this server, reconcile items

for _, player in PlayerDataManager.getPlayersWithLoadedPersistentData() do
	reconcileItems(player)
end

PlayerDataManager.persistentDataLoaded:Connect(reconcileItems)

return InventoryManager
