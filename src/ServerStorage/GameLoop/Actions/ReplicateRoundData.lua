--!strict

--#region Imports

local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerStorage = game:GetService "ServerStorage"
local Players = game:GetService "Players"

local ClientServerCommunication = require(ReplicatedStorage.Data.ClientServerCommunication)
local RoundData = require(ServerStorage.GameLoop.RoundData)

--#endregion

local function replicate()
    for _, player in ipairs(Players:GetPlayers()) do
        ClientServerCommunication.replicateAsync("UpdateRoundData", RoundData.getFilteredData(), player)
    end
end

return function()
    task.spawn(replicate)
end