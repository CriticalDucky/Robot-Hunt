local RoundDataManager = require(game.ServerStorage.GameLoop.RoundDataManager)

local Teleport = {}

function Teleport.toLobby(player: Player)
    player.Team = game.Teams:WaitForChild("Lobby")

    local character = player.Character

    if character then
        character:PivotTo(CFrame.new(100,3,100))
    end

    RoundDataManager.registerLobbyTeleport(player, false)
end

function Teleport.toGame(player: Player)
    local map = workspace:FindFirstChild("Map")
    if not map then
        warn("Map not found")
        return
    end
    local spawns = map:FindFirstChild("Spawns")
    local teamSpawns = spawns:FindFirstChild(player.Team.Name)
    if not teamSpawns then
        warn("Team spawns not found")
        return
    end
    local spawnPoints = teamSpawns:GetChildren()

    local spawnPoint = spawnPoints[math.random(1, #spawnPoints)]

    local character = player.Character

    if character then
        character:PivotTo(spawnPoint.CFrame + Vector3.new(0, 3, 0))
    end

    RoundDataManager.registerLobbyTeleport(player, true)
end

return Teleport