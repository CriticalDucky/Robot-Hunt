--[[
    Implements server directives.

    TODO: Create proper implementations.
]]

local ServerStorage = game:GetService "ServerStorage"

local ServerDirectives = require(ServerStorage.Utility.ServerDirectives)

ServerDirectives.kickingPlayer:Connect(function(player, reason) warn(`Kicking player {player.Name}. - {reason}`) end)

ServerDirectives.shuttingDownServer:Connect(function(reason) warn(`Shutting down server. - {reason}`) end)
