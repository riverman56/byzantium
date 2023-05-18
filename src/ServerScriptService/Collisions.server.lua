local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

-- TODO: move collision group names to constants file
PhysicsService:RegisterCollisionGroup("ByzantiumCharacters")
PhysicsService:RegisterCollisionGroup("Characters")
PhysicsService:CollisionGroupSetCollidable("Characters", "ByzantiumCharacters", false)
PhysicsService:CollisionGroupSetCollidable("ByzantiumCharacters", "ByzantiumCharacters", false)

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