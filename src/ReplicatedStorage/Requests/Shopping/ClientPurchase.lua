local ReplicatedStorage = game:GetService "ReplicatedStorage"

local replicatedStorageShared = ReplicatedStorage:WaitForChild "Shared"
local replicationFolder = replicatedStorageShared:WaitForChild "Replication"
local dataFolder = replicatedStorageShared:WaitForChild "Data"
local shopInfoFolder = dataFolder:WaitForChild "ShopInfo"
local requestsFolder = replicatedStorageShared:WaitForChild "Requests"

local ReplicaCollection = require(replicationFolder:WaitForChild "ReplicaCollection")
local ReplicaRequest = require(requestsFolder:WaitForChild "ReplicaRequest")
local Shops = require(shopInfoFolder:WaitForChild "Shops")

local ClientPurchase = {}

function ClientPurchase.request(shopEnum, itemIndex)
	assert(shopEnum and Shops[shopEnum], "shop must be a valid shop type")
	assert(itemIndex and Shops[shopEnum].items[itemIndex], "item must be a valid item")

	local purchaseRequestReplica = ReplicaCollection.waitForReplica("PurchaseRequest")

	return ReplicaRequest.new(purchaseRequestReplica, shopEnum, itemIndex)
end

return ClientPurchase
