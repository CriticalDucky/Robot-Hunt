--!strict

--#region Imports

local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerStorage = game:GetService "ServerStorage"

local ClientServerCommunication = require(ReplicatedStorage.Data.ClientServerCommunication)
local RoundDataManager = require(ServerStorage.GameLoop.RoundDataManager)

--#endregion

ClientServerCommunication.registerActionAsync("InitializeRoundData", function(player: Player)
    RoundDataManager.initializeRoundDataAsync(player)
end)

ClientServerCommunication.registerActionAsync("SetPhase")
ClientServerCommunication.registerActionAsync("UpdateVictims")
ClientServerCommunication.registerActionAsync("KillPlayer")
ClientServerCommunication.registerActionAsync("RevivePlayer")
ClientServerCommunication.registerActionAsync("UpdateHealth")
ClientServerCommunication.registerActionAsync("UpdateLifeSupport")
ClientServerCommunication.registerActionAsync("UpdateAmmo")
ClientServerCommunication.registerActionAsync("UpdateBatteryStatus")
ClientServerCommunication.registerActionAsync("SetUpRound")