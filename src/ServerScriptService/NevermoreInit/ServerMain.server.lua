local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local loader = ServerScriptService.Nevermore:FindFirstChild("LoaderUtils", true).Parent
local require = require(loader).bootstrapGame(ServerScriptService.Nevermore)

local serviceBag = require("ServiceBag").new()
-- local Ragdoll = require("Ragdoll")

serviceBag:GetService(require("IKService"))
-- serviceBag:GetService(require("RagdollService"))

serviceBag:Init()
serviceBag:Start()

-- task.wait(5)

-- function setRagdollEnabled(humanoid: Humanoid, enabled: boolean)
--     assert(humanoid, "Humanoid is nil")

--     humanoid.RequiresNeck = false          -- keeps them alive when the neck Motor6D is swapped
--     humanoid.BreakJointsOnDeath = false    -- stops automatic death on joint swap


--     if enabled then
--         Ragdoll:Tag(humanoid)
--     else
--         Ragdoll:Untag(humanoid)
--     end
-- end

-- local humanoid = Players:GetChildren()[1].Character:WaitForChild("Humanoid") :: Humanoid

-- setRagdollEnabled(humanoid, true)

-- task.wait(5)

-- setRagdollEnabled(humanoid, false)

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