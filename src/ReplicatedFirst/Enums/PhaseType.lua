--!strict

--[[
    This group of enums represents the different states, or "phases" that the game can be in.
]]
return {
    -- Lobby
    Intermission = 1,
    Loading = 2,
    NotEnoughPlayers = 0,

    -- Default Round
    Infiltration = 3,
    PhaseOne = 4,
    Purge = 5,
    PhaseTwo = 6,   

    -- After Round
    GameOver = 7,
    Results = 8,
}