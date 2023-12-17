local ServerStorage = game:GetService "ServerStorage"

local serverStorageShared = ServerStorage.Shared
local dataFolder = serverStorageShared.Data

local PlayerDataManager = require(dataFolder.PlayerDataManager)

local Currency = {}

--[[
    Gets the amount of currency of the specified currency type that the player has.
    Returns a success boolean and the amount of currency if successful.
    If no currency type is specified, returns a table of all currency types and their amounts.

    CurrencyType is a CurrencyType.lua enum.
]]
function Currency.get(player, currencyType)
	local profile = PlayerDataManager.viewPersistentData(player.UserId)

	if not profile then return false end

	local currencyTable = profile.Data.currency

	return true, if currencyType then currencyTable[currencyType] else currencyTable
end

--[[
    Returns a success boolean and whether or not the player has the specified amount of currency.

    CurrencyType is a CurrencyType.lua enum.
]]
function Currency.hasAmount(player: Player, currencyType, amount: number)
	assert(player and currencyType and amount, "Currency.has: Missing argument(s)")

	local currency = Currency.get(player, currencyType)

	return currency and currency >= amount
end

--[[
    Sets the player's currency to the specified amount.
    Returns a success boolean.

    CurrencyType is a CurrencyType.lua enum.

    Consider using Currency.increment for general transaction operations.
]]
function Currency.set(player: Player, currencyType, amount: number)
    assert(player and currencyType and amount, "Currency.set: Missing argument(s)")

    if not PlayerDataManager.persistentDataIsLoaded(player) then return false end

    PlayerDataManager.setValuePersistent(player, { "currency", currencyType }, amount)

    return true
end

--[[
    Increments the player's currency by the specified amount.
    Returns a success boolean.

    CurrencyType is a CurrencyType.lua enum.
]]
function Currency.increment(player: Player, currencyType, amount: number)
	assert(player and currencyType and amount, "Currency.increment: Missing argument(s)")

	if not PlayerDataManager.persistentDataIsLoaded(player) then return false end

	local success, currencyAmount = Currency.get(player, currencyType)

	if success and currencyAmount and currencyAmount + amount >= 0 then
		return Currency.set(player, currencyType, currencyAmount + amount)
	end

    if not (currencyAmount + amount >= 0) then
        error("Currency.increment: Resulting currency amount is less than 0")
    end

    return false
end



return Currency
