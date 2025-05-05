local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local loader = ServerScriptService.Nevermore:FindFirstChild("LoaderUtils", true).Parent
local require = require(loader).bootstrapGame(ServerScriptService.Nevermore)

local serviceBag = require("ServiceBag").new()
local ikService = serviceBag:GetService(require("IKService"))
serviceBag:Init()
serviceBag:Start()

-- RunService.Stepped:Connect(function()
--     -- Update IK targets for all players
--     for _, player in Players:GetPlayers() do
--         local character = player.Character or player.CharacterAdded:Wait()
--         local humanoid = character:FindFirstChildOfClass("Humanoid")

--         if humanoid then
--             ikService:UpdateServerRigTarget(humanoid, Vector3.zero)
--         end
--     end
-- end)

-- Build test NPC rigs
-- local RigBuilderUtils = require("RigBuilderUtils")
-- RigBuilderUtils.promiseR15MeshRig():Then(function(character)
-- 	local humanoid = character.Humanoid

-- 	-- reparent to middle
-- 	humanoid.RootPart.CFrame = CFrame.new(0, 25, 0)
-- 	character.Parent = workspace
-- 	humanoid.RootPart.CFrame = CFrame.new(0, 25, 0)

-- 	-- look at origin
-- 	RunService.Stepped:Connect(function()
-- 		ikService:UpdateServerRigTarget(humanoid, Vector3.zero)
-- 	end)
-- end)