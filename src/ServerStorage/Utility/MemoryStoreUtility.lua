--!strict

local ReplicatedStorage = game:GetService "ReplicatedStorage"

local SafeRetry = require(ReplicatedStorage.Shared.Utility.SafeRetry)

local MemoryStoreUtility = {}

--[[
    Gets all items from a memory store sorted map.

    ---

    @param sortedMap The sorted map to get all items from.
    @param direction How the items are sorted.
    @return Whether or not the operation was successful.
    @return The items in the sorted map.
]]
function MemoryStoreUtility.safeSortedMapGetAllAsync(sortedMap: MemoryStoreSortedMap, direction)
	local results = {}

	local exclusiveLowerBound

	while true do
		local success, items: { { key: string, value: any } } =
			MemoryStoreUtility.safeSortedMapGetRangeAsync(sortedMap, direction, 200, exclusiveLowerBound)

		if not success then return false, (nil :: any) :: { { key: string, value: any } } end

		for _, v in pairs(items) do
			table.insert(results, v)
		end

		if #items < 200 then break end

		exclusiveLowerBound = items[#items].key
	end

	return true, results
end

function MemoryStoreUtility.safeSortedMapGetAsync(sortedMap: MemoryStoreSortedMap, key)
	return SafeRetry(function() return sortedMap:GetAsync(key) end)
end

function MemoryStoreUtility.safeSortedMapGetRangeAsync(
	sortedMap: MemoryStoreSortedMap,
	direction,
	count,
	exclusiveLowerBound,
	exclusiveUpperBound
)
	return SafeRetry(
		function() return sortedMap:GetRangeAsync(direction, count, exclusiveLowerBound, exclusiveUpperBound) end
	)
end

function MemoryStoreUtility.safeSortedMapRemoveAsync(sortedMap: MemoryStoreSortedMap, key)
	return SafeRetry(function() return sortedMap:RemoveAsync(key) end)
end

function MemoryStoreUtility.safeSortedMapSetAsync(sortedMap: MemoryStoreSortedMap, key, value, expiration)
	return SafeRetry(function() return sortedMap:SetAsync(key, value, expiration) end)
end

function MemoryStoreUtility.safeSortedMapUpdateAsync(
	sortedMap: MemoryStoreSortedMap,
	key,
	transformFunction,
	expiration
)
	return SafeRetry(function() return sortedMap:UpdateAsync(key, transformFunction, expiration) end)
end

return MemoryStoreUtility
