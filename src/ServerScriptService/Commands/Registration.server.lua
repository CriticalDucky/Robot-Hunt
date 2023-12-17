local ServerStorage = game:GetService("ServerStorage")

local commandsFolder = ServerStorage.Shared.Commands
local hooksFolder = commandsFolder.Hooks
local customCommandsFolder = commandsFolder.Commands

local Cmdr = require(ServerStorage.Vendor.Cmdr)

Cmdr:RegisterHooksIn(hooksFolder)
Cmdr:RegisterCommandsIn(customCommandsFolder)