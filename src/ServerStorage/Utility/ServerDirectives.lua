local kickingPlayerEvent = Instance.new "BindableEvent"
local shuttingDownServerEvent = Instance.new "BindableEvent"

local ServerDirectives = {}

--[[
    Sends a request to kick a player.

    ---

    @param player The player to kick.
    @param reason The reason for kicking the player.
]]
function ServerDirectives.kickPlayer(player: Player, reason: string) kickingPlayerEvent:Fire(player, reason) end

--[[
    Sends a request to shut down the server and halts the thread it was called on.

    ---

    @param reason The message shown to players after they are kicked.
]]
function ServerDirectives.shutDownServer(reason: string)
	shuttingDownServerEvent:Fire(reason)
	task.wait(math.huge)
end

ServerDirectives.kickingPlayer = kickingPlayerEvent.Event

ServerDirectives.shuttingDownServer = shuttingDownServerEvent.Event

return ServerDirectives
