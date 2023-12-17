local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ServerStorage = game:GetService("ServerStorage")

local dataFolder = ServerStorage.Shared.Data
local enumsFolder = ReplicatedFirst.Shared.Enums
local configurationFolder = ReplicatedFirst.Shared.Configuration

local HomeManager = require(dataFolder.Inventory.HomeManager)
local ServerTypeGroups = require(configurationFolder.ServerTypeGroups)
local ServerGroupEnum = require(enumsFolder.ServerGroup)
local Teleport = require(ServerStorage.Shared.Teleportation.Teleport)

if ServerTypeGroups.serverInGroup(ServerGroupEnum.isHome) then
    if not HomeManager.loadHome() then
        Teleport.bootServer("The home failed to start up. (err code LH1)")
    end
end

