-- Helper functions for simple datastore requests for actions that don't require major wrappers like ProfileService

local DEBUG = false

local DATASTORE_MAX_RETRIES = 10

local ReplicatedFirst = game:GetService "ReplicatedFirst"

local Promise = require(ReplicatedFirst.Vendor.Promise)

local DataStore = {}

--[[
Attempts to update the value in the specified key, automatically retrying if it fails.

Yields and returns the success and the error (if there is one) of `UpdateAsync()`.

```lua
local success, result = DataStore.safeUpdate(dataStore, key, function(value)
	-- value is the current value in the datastore
	-- return the new value to set
	return value + 1
end
```
---]]
function DataStore.safeUpdate(dataStore: GlobalDataStore, key: string, transformFunction: (any) -> any)
	assert(typeof(dataStore) == "Instance" and dataStore:IsA "GlobalDataStore", "dataStore must be a GlobalDataStore")
	assert(typeof(key) == "string", "key must be a string")
	assert(typeof(transformFunction) == "function", "transformFunction must be a function")

	if DEBUG then print("DATASTORE: safeUpdate", key) end

	local function try()
		return Promise.try(function()
			return dataStore:UpdateAsync(key, transformFunction)
		end)
	end

	return Promise.retry(try, DATASTORE_MAX_RETRIES):await()
end

--[[
	Attempts to set the value in the specified key, automatically retrying if it fails.

	Yields and returns the success and the error (if there is one) of `SetAsync()`.

	```lua
	local success, result = DataStore.safeSet(dataStore, key, value)
	```
]]
function DataStore.safeSet(
	dataStore: GlobalDataStore,
	key: string,
	value,
	userIds: { number }?,
	options: DataStoreSetOptions?
)
	assert(typeof(dataStore) == "Instance" and dataStore:IsA "GlobalDataStore", "dataStore must be a GlobalDataStore")
	assert(typeof(key) == "string", "key must be a string")
	assert(userIds == nil or typeof(userIds) == "table", "userIds must be a table")
	assert(
		options == nil or (typeof(options) == "Instance" and options:IsA "DataStoreSetOptions"),
		"options must be a DataStoreSetOptions"
	)

	if DEBUG then print("DATASTORE: safeSet", key) end

	local function try()
		return Promise.try(function()
			return dataStore:SetAsync(key, value, userIds, options)
		end)
	end

	return Promise.retry(try, DATASTORE_MAX_RETRIES):await()
end

--[[
	Attempts to get the value in the specified key, automatically retrying if it fails.

	Yields and returns the success and value (or error response if success is false) of `GetAsync()`.

	```lua
	local success, data = DataStore.safeGet(dataStore, key) -- data is the error response if success is false
	```
]]
function DataStore.safeGet(dataStore: GlobalDataStore, key: string)
	assert(typeof(dataStore) == "Instance" and dataStore:IsA "GlobalDataStore", "dataStore must be a GlobalDataStore")
	assert(typeof(key) == "string", "key must be a string")

	if DEBUG then print("DATASTORE: safeGet", key) end

	local function try()
		return Promise.try(function()
			return dataStore:GetAsync(key)
		end)
	end

	return Promise.retry(try, DATASTORE_MAX_RETRIES):await()
end

--[[
	Attempts to remove the value in the specified key, automatically retrying if it fails.

	Yields and returns the success and the error (if there is one) of `RemoveAsync()`.

	```lua
	local success, result = DataStore.safeRemove(dataStore, key)
	```
]]
function DataStore.safeRemove(dataStore: GlobalDataStore, key: string)
	assert(typeof(dataStore) == "Instance" and dataStore:IsA "GlobalDataStore", "dataStore must be a GlobalDataStore")
	assert(typeof(key) == "string", "key must be a string")

	if DEBUG then print("DATASTORE: safeRemove", key) end

	local function try()
		return Promise.try(function()
			return dataStore:RemoveAsync(key)
		end)
	end

	return Promise.retry(try, DATASTORE_MAX_RETRIES):await()
end

return DataStore
