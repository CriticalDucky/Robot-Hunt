local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerStorage = game:GetService "ServerStorage"

local serverStorageShared = ServerStorage.Shared
local dataFolder = serverStorageShared.Data
local shoppingFolder = dataFolder.Shopping
local inventoryFolder = dataFolder.Inventory
local replicatedStorageShared = ReplicatedStorage.Shared
local replicatedFirstShared = ReplicatedFirst.Shared
local replicatedStorageSharedData = replicatedStorageShared.Data
local enumsFolder = replicatedFirstShared.Enums
local replicatedShoppingFolder = replicatedStorageSharedData.ShopInfo

local ActiveShops = require(shoppingFolder.ActiveShops)
local Shops = require(replicatedShoppingFolder.Shops)
local PlayerDataManager = require(dataFolder.PlayerDataManager)
local InventoryManager = require(inventoryFolder.InventoryManager)
local Items = require(replicatedStorageSharedData.Inventory.Items)
-- local Currency = require(dataFolder.Currency.Currency)
local purchaseResponseType = require(enumsFolder.PurchaseResponseType)

local ShopManager = {}

--[[
    Returns whether or not the player can buy the item from a shop, along with the reason why.
    The second return argument is a `PurchaseResponseType` enum.
    WARNING: This will return false if player data is not found.
]]
function ShopManager.canPlayerBuyItem(player, shopEnum, itemIndex)
	assert(player and shopEnum and itemIndex, "Invalid arguments")
	assert(ActiveShops[shopEnum], "Shop is not active")

	local shopInfoTable = Shops[shopEnum]
	local shopItem = shopInfoTable.items[itemIndex]
	-- local itemInfo = Items[shopItem.itemCategory][shopItem.item]

	local playerData = PlayerDataManager.getPersistentData(player.UserId)

	if not playerData then
		warn "Player data not found"
		return false, purchaseResponseType.invalid
	end

	if not shopItem.sellingTime or not shopItem.sellingTime:isInRange() then
		warn "Shop item is not available"
		return false, purchaseResponseType.invalid
	end

	-- if not select(2, Currency.hasAmount(player, itemInfo.priceCurrencyType, itemInfo.price)) then
	-- 	warn "Player does not have enough currency"
	-- 	return false, purchaseResponseType.invalid
	-- end

	if not select(2, InventoryManager.isInventoryFull(player, shopItem.itemCategory, 1)) then
		warn "Player inventory is full"
		return false, purchaseResponseType.full
	end

	return true
end

--[[
    Purchases the item from the shop.
    - `shopEnum` is the enum of the shop.
    - `itemIndex` is the index of the item in the shop.

    Returns the success of the purchase, along with a `PurchaseResponseType` enum if not successful.
]]
function ShopManager.purchaseShopItem(player, shopEnum, itemIndex)
	local shopInfoTable = Shops[shopEnum]
	local shopItem = shopInfoTable.items[itemIndex]

	local itemCategory = Items[shopItem.itemCategory]

	if not itemCategory then
		warn "Invalid item category"
		return false, purchaseResponseType.invalid
	end

	local itemInfo = itemCategory[shopItem.item]

	if not itemInfo then
		warn "Invalid item"
		return false, purchaseResponseType.invalid
	end

	local canBuy, response = ShopManager.canPlayerBuyItem(player, shopEnum, itemIndex)

	if not canBuy then
		warn "Player cannot buy item"

		return false, response
	end

	-- if not Currency.increment(player, itemInfo.priceCurrencyType, -itemInfo.price) then
	-- 	warn "Failed to increment currency"

	-- 	return false, purchaseResponseType.error
	-- end

	InventoryManager.newItemInInventory(shopItem.itemCategory, shopItem.item, player)

	return true
end

return ShopManager
