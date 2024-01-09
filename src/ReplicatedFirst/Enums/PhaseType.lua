--!strict

--[[
    This group of enums represents the different states, or "phases" that the game can be in.
]]
return {
    -- Lobby
    Intermission = 1,
    NotEnoughPlayers = 0,

    -- Default Round
    Infiltration = 2,
    PhaseOne = 3,
    Purge = 4,
    PhaseTwo = 5,   

    -- After Round

    Results = 6,
}