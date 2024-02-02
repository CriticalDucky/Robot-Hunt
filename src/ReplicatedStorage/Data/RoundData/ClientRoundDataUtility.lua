local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

local dataFolder = ReplicatedStorage:WaitForChild("Data")

local ClientState = require(dataFolder:WaitForChild("ClientState"))
local Enums = require(ReplicatedFirst:WaitForChild("Enums"))
local PhaseType = Enums.PhaseType

local Fusion = require(ReplicatedFirst:WaitForChild("Vendor"):WaitForChild("Fusion"))
local Computed = Fusion.Computed

local lobbyPhases = {
    [PhaseType.Intermission] = true,
    [PhaseType.Loading] = true,
    [PhaseType.NotEnoughPlayers] = true,
    [PhaseType.Results] = true,
}

local ClientRoundDataUtility = {}

ClientRoundDataUtility.isRoundActive = Computed(function(use)
    local roundData = ClientState.external.roundData
    local currentPhase = use(roundData.currentPhase)
    local currentRoundType = use(roundData.currentRoundType)

    return not lobbyPhases[currentPhase] and currentRoundType ~= nil
end)

ClientRoundDataUtility.isGunEnabled = Computed(function(use)
    local resultTable: {[number]: boolean} = {}

    local isGameRunning = use(ClientRoundDataUtility.isRoundActive)
    
    if not isGameRunning then return resultTable end

    local roundData = ClientState.external.roundData
    local roundPlayerData = use(roundData.playerData)
    local currentRoundType = use(roundData.currentRoundType) -- gamemode

    for _, playerData in pairs(roundPlayerData) do
        local player = playerData.player
        
        local isAlive = not (playerData.status == Enums.PlayerStatus.dead)

        if not isAlive then continue end

        if currentRoundType == Enums.RoundType.defaultRound then
            local team = playerData.team
            local phase = use(roundData.currentPhaseType)

            if team == Enums.TeamType.hunters or phase == PhaseType.PhaseTwo then
                resultTable[player.UserId] = true
            end
        else
            if currentRoundType ~= nil then
                error("Gamemode has no gun enabled check implemented")
            end
        end
    end
    
    return resultTable
end)

return ClientRoundDataUtility