local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedStorageFolder = ReplicatedStorage:WaitForChild("Byzantium")
local Constants = require(replicatedStorageFolder.SharedAssets.Constants)

PhysicsService:RegisterCollisionGroup(Constants.BYZANTIUM_CHARACTERS_COLLISION_GROUP_IDENTIFIER)
PhysicsService:RegisterCollisionGroup(Constants.CHARACTERS_COLLISION_GROUP_IDENTIFIER)
PhysicsService:CollisionGroupSetCollidable(Constants.CHARACTERS_COLLISION_GROUP_IDENTIFIER, Constants.BYZANTIUM_CHARACTERS_COLLISION_GROUP_IDENTIFIER, false)
PhysicsService:CollisionGroupSetCollidable(Constants.BYZANTIUM_CHARACTERS_COLLISION_GROUP_IDENTIFIER, Constants.BYZANTIUM_CHARACTERS_COLLISION_GROUP_IDENTIFIER, false)

local function onDescendantAdded(descendant)
	if descendant:IsA("BasePart") then
		descendant.CollisionGroup = "Characters"
	end
end

local function onCharacterAdded(character)
	for _, descendant in pairs(character:GetDescendants()) do
		onDescendantAdded(descendant)
	end
	character.DescendantAdded:Connect(onDescendantAdded)
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(onCharacterAdded)
end)