local PhysicsService = game:GetService("PhysicsService")

PhysicsService:RegisterCollisionGroup("Character")
PhysicsService:RegisterCollisionGroup("CharacterDetection")
PhysicsService:RegisterCollisionGroup("Battery")

PhysicsService:CollisionGroupSetCollidable("Character", "Character", false)
PhysicsService:CollisionGroupSetCollidable("Character", "CharacterDetection", false)
PhysicsService:CollisionGroupSetCollidable("Character", "Battery", false)