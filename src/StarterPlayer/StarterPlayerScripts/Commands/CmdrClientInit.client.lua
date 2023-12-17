local Players = game:GetService "Players"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local replicatedFirstShared = ReplicatedFirst:WaitForChild "Shared"
local utilityFolder = replicatedFirstShared:WaitForChild "Utility"
local enumsFolder = replicatedFirstShared:WaitForChild "Enums"

local Cmdr = require(ReplicatedStorage:WaitForChild "CmdrClient" :: ModuleScript)
local PlayerPermission = require(utilityFolder:WaitForChild "PlayerPermission")
local PlayerPermissionLevel = require(enumsFolder:WaitForChild "PlayerPermissionLevel")

if PlayerPermission.hasPermission(Players.LocalPlayer, PlayerPermissionLevel.moderator) then
	Cmdr:SetActivationKeys { Enum.KeyCode.F2 }
end
