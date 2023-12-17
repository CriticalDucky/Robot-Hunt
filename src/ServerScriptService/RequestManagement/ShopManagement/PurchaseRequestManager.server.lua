local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerStorage = game:GetService "ServerStorage"

local serverStorageShared = ServerStorage.Shared
local serverStorageVendor = ServerStorage.Vendor
local replicatedStorageShared = ReplicatedStorage.Shared
local replicatedFirstShared = ReplicatedFirst.Shared
local dataFolder = serverStorageShared.Data
local shoppingFolder = dataFolder.Shopping
local replicatedShoppingFolder = replicatedStorageShared.Data.ShopInfo
local enumsFolder = replicatedFirstShared.Enums
local serverStorageSharedUtility = serverStorageShared.Utility

local ReplicaService = require(serverStorageVendor.ReplicaService)
local ActiveShops = require(shoppingFolder.ActiveShops)
local Shops = require(replicatedShoppingFolder.Shops)
local ShopManager = require(shoppingFolder.ShopManager)
local PurchaseResponseType = require(enumsFolder.PurchaseResponseType)
local ReplicaResponse = require(serverStorageSharedUtility.ReplicaResponse)

local purchaseRequest = ReplicaService.NewReplica {
	ClassToken = ReplicaService.NewClassToken "PurchaseRequest",
	Replication = "All",
}

ReplicaResponse.listen(purchaseRequest, function(player, shopEnum: string, itemIndex: number)
	if not ActiveShops[shopEnum] then
		warn "PurchaseRequestManager: Shop is not active"

		return false, PurchaseResponseType.invalid
	end

	local shopInfo = Shops[shopEnum]
	local shopItem = shopInfo.items[itemIndex]

	if not shopItem then
		warn "PurchaseRequestManager: Shop item does not exist"

		return false, PurchaseResponseType.invalid
	end

	local canBuy, result = ShopManager.canPlayerBuyItem(player, shopEnum, itemIndex)

	if not canBuy then
		warn "PurchaseRequestManager: Player cannot buy item"

		return false, result
	end

	local success, purchaseResult = ShopManager.purchaseShopItem(player, shopEnum, itemIndex)

	if not success then
		warn "PurchaseRequestManager: Player cannot buy item"

		return false, purchaseResult
	end

	return true, purchaseResult
end)