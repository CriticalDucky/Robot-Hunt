local ReplicatedStorage = game:GetService "ReplicatedStorage"
local TeleportService = game:GetService "TeleportService"

local SafeRetry = require(ReplicatedStorage.Shared.Utility.SafeRetry)

local TeleportUtility = {}

--[[
    Calls `TeleportService:GetPlayerPlaceInstanceAsync()` without erroring. If it errors, it will automatically retry.
]]
function TeleportUtility.safeGetPlayerPlaceInstanceAsync(userId)
	return SafeRetry(function() return TeleportService:GetPlayerPlaceInstanceAsync(userId) end)
end

--[[
    Calls `TeleportService:ReserveServer()` without erroring. If it errors, it will automatically retry.
]]
function TeleportUtility.safeReserveServerAsync(placeId)
	return SafeRetry(function() return TeleportService:ReserveServer(placeId) end)
end

--[[
    Calls `TeleportService:TeleportAsync()` without erroring. If it errors, it will automatically retry.
]]
function TeleportUtility.safeTeleportAsync(placeId, players, teleportOptions)
	return SafeRetry(function() return TeleportService:TeleportAsync(placeId, players, teleportOptions) end)
end

return TeleportUtility
