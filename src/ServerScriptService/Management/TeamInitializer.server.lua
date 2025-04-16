local Teams = game:GetService("Teams")

local function createTeam(name, color, autoAssignable)
    local team = Instance.new("Team")
    team.Name = name
    team.AutoAssignable = autoAssignable
    team.TeamColor = color
    team.Parent = Teams

    return team
end

createTeam("Hunters", BrickColor.new("Bright red"), false)
createTeam("Rebels", BrickColor.new("Bright blue"), false)
local lobby = createTeam("Lobby", BrickColor.new("Bright violet"), true)

local players = game:GetService("Players"):GetPlayers()

for _, player in ipairs(players) do
    player.Team = lobby
end