local ReplicatedStorage = game:GetService "ReplicatedStorage"

local SafeRetry = require(ReplicatedStorage.Utility.SafeRetry)

local DataStoreUtility = {}

--[[
	Calls `DataStore:GetAsync()` without erroring. If it errors, it will automatically retry.
]]
function DataStoreUtility.safeGetAsync(dataStore: GlobalDataStore, key)
	return SafeRetry(function() return dataStore:GetAsync(key) end)
end

--[[
	Calls `DataStore:IncrementAsync()` without erroring. If it errors, it will automatically retry.
]]
function DataStoreUtility.safeIncrementAsync(dataStore: GlobalDataStore, key, delta, userIds, options)
	return SafeRetry(function() return dataStore:IncrementAsync(key, delta, userIds, options) end)
end

--[[
	Calls `DataStore:ListKeysAsync()` without erroring. If it errors, it will automatically retry.
]]
function DataStoreUtility.safeListKeysAsync(dataStore: DataStore, prefix, pageSize, cursor, excludeDeleted)
	return SafeRetry(function() return dataStore:ListKeysAsync(prefix, pageSize, cursor, excludeDeleted) end)
end

--[[
	Calls `DataStore:RemoveAsync()` without erroring. If it errors, it will automatically retry.
]]
function DataStoreUtility.safeRemoveAsync(dataStore: GlobalDataStore, key)
	return SafeRetry(function() return dataStore:RemoveAsync(key) end)
end

--[[
	Calls `DataStore:SetAsync()` without erroring. If it errors, it will automatically retry.
]]
function DataStoreUtility.safeSetAsync(dataStore: GlobalDataStore, key, value, userIds, options)
	return SafeRetry(function() return dataStore:SetAsync(key, value, userIds, options) end)
end

--[[
	Calls `DataStore:UpdateAsync()` without erroring. If it errors, it will automatically retry.
]]
function DataStoreUtility.safeUpdateAsync(dataStore: GlobalDataStore, key, transformFunction)
	return SafeRetry(function() return dataStore:UpdateAsync(key, transformFunction) end)
end

return DataStoreUtility
