local PhysicsService = game:GetService("PhysicsService")

local character = script.Parent

PhysicsService:RegisterCollisionGroup("Character")
PhysicsService:CollisionGroupSetCollidable("Character", "Character", false)

for _, v in ipairs(character:GetDescendants()) do
	if v:IsA("BasePart") then
		v.CollisionGroup = "Character"
	end
end


