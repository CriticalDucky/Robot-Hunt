-- Disable first‑person by bumping the minimum zoom distance
local Players = game:GetService("Players")
local player  = Players.LocalPlayer

player.CameraMinZoomDistance = 3
