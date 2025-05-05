local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AL = require(script:WaitForChild("AL"))

local loader = ReplicatedStorage:WaitForChild("Nevermore"):WaitForChild("loader") :: ModuleScript
local require = require(loader).bootstrapGame(loader.Parent)

local serviceBag = require("ServiceBag").new()
local ikServiceClient = serviceBag:GetService(require("IKServiceClient"))
local IKAimPositionPriorites = require("IKAimPositionPriorites")

serviceBag:Init()
serviceBag:Start()

local IKManager = {}
IKManager.AL = AL

--[[
    @param lookAround: boolean — Whether to enable or disable look around.
]]
function IKManager.SetLookAround(lookAround: boolean)
    ikServiceClient:SetLookAround(lookAround)
end

--[[
    @param aimPosition: Vector3 — The position to aim at.
    @param priority: number? — The priority of the aim position. Defaults to IKAimPositionPriorites.HIGH.
]]
function IKManager.SetTemporaryAimPosition(aimPosition: Vector3, priority: number?)
    ikServiceClient:SetAimPosition(aimPosition, priority or IKAimPositionPriorites.HIGH)
end

IKManager.SetLookAround(true)

return IKManager
