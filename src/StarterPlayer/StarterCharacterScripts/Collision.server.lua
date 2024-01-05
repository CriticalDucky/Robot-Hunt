local PhysicsService = game:GetService("PhysicsService")

local character = script.Parent

for _, v in ipairs(character:GetDescendants()) do
	if v:IsA("BasePart") then
		v.CollisionGroup = "Character"
	end
end

PhysicsService:CollisionGroupSetCollidable("Character", "Character", false)
