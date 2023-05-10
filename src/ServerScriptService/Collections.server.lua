local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local CHARACTERS_TAG_NAME = "BYZANTIUM_CHARACTER"

local function onCharacterAdded(character: Model)
    CollectionService:AddTag(character, CHARACTERS_TAG_NAME)
end

local function onCharacterRemoving(character: Model)
    CollectionService:RemoveTag(character, CHARACTERS_TAG_NAME)
end

local function onPlayerAdded(player: Player)
    local character = player.Character
    if character then
        onCharacterAdded(character)
    end

    player.CharacterAdded:Connect(onCharacterAdded)
    player.CharacterRemoving:Connect(onCharacterRemoving)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
    onPlayerAdded(player)
end