local PhysicsService = game:GetService("PhysicsService")

PhysicsService:RegisterCollisionGroup("Character")
PhysicsService:RegisterCollisionGroup("CharacterDetection")

PhysicsService:CollisionGroupSetCollidable("Character", "Character", false)
PhysicsService:CollisionGroupSetCollidable("Character", "CharacterDetection", false)