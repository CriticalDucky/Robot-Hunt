--!strict

--[[
    This group of enums represents the different states, or "phases" that the game can be in.
]]
return {
    -- Lobby
    Intermission = 1,
    Results = 5,
    NotEnoughPlayers = 0,

    -- Default Round
    PhaseOne = 3,
    PhaseTwo = 4,
    Hiding = 2,
}