local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ServerStorage = game:GetService "ServerStorage"

local serverStorageShared = ServerStorage.Shared
local serverStorageVendor = ServerStorage.Vendor
local replicatedFirstShared = ReplicatedFirst.Shared
local serverStorageSharedUtility = serverStorageShared.Utility
local enumsFolder = replicatedFirstShared.Enums
local utilityFolder = replicatedFirstShared.Utility
local dataFolder = serverStorageShared.Data

local ReplicaService = require(serverStorageVendor.ReplicaService)
local ReplicaResponse = require(serverStorageSharedUtility.ReplicaResponse)
local Param = require(utilityFolder.Param)
-- local PlayerSettings = require(dataFolder.Settings.PlayerSettings)
local Table = require(utilityFolder.Table)
local HomeLockType = require(enumsFolder.HomeLockType)
local InventoryManager = require(dataFolder.Inventory.InventoryManager)
local SetSettingResponseType = require(enumsFolder.SetSettingResponseType)

local setSettingRequest = ReplicaService.NewReplica {
	ClassToken = ReplicaService.NewClassToken "SetSettingRequest",
	Replication = "All",
}

--[[
    A table with the setting name as the key and a verification method as the value.
    The verification method should return true if the value is valid, and false if it is not.
]]
local verificationMethods: { [string]: (Player, any) -> boolean } = {
	findOpenWorld = function(_, value)
		return Param.expect { value, "boolean" }
	end,

	homeLock = function(_, value)
		if not Param.expect { value, "string" } then return false end

		return Table.hasValue(HomeLockType, value)
	end,

	selectedHome = function(player, value)
		if not Param.expect { value, "string" } then return false end

		local success, ownsItem = InventoryManager.playerOwnsItem(player.UserId, value)

		return success and ownsItem
	end,

    musicVolume = function(_, value)
        return Param.expect { value, "number" } and value >= 0 and value <= 1
    end,

    sfxVolume = function(_, value)
        return Param.expect { value, "number" } and value >= 0 and value <= 1
    end,
}

ReplicaResponse.listen(setSettingRequest, function(player, setting, value)
    if not Param.expect { setting, "string" } then
        warn("Invalid setting type: " .. typeof(setting))

        return false, SetSettingResponseType.invalid
    end

    local verificationMethod = verificationMethods[setting]

    if not verificationMethod then
        warn("Invalid setting: " .. setting)

        return false, SetSettingResponseType.invalid
    end

    if not verificationMethod(player, value) then
        warn("Invalid value for setting: " .. setting)

        return false, SetSettingResponseType.invalid
    end

    -- PlayerSettings.setSetting(player, setting, value)

    return true
end)
