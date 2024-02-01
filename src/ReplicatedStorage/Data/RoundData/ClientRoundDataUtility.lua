local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

local dataFolder = ReplicatedStorage:WaitForChild("Data")

local ClientState = require(dataFolder:WaitForChild("ClientState"))

local Fusion = require(ReplicatedFirst:WaitForChild("Vendor"):WaitForChild("Fusion"))
local Computed = Fusion.Computed

local ClientRoundDataUtility = {}

ClientRoundDataUtility.isGunEnabled = Computed(function(use)
    local resultTable: {[number]: boolean} = {}

    local roundData = ClientState.external.roundData
    local roundPlayerData = use(roundData.playerData)
    local currentRoundType = use(roundData.currentRoundType)
end)

return ClientRoundDataUtility