local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedStorageFolder = ReplicatedStorage:WaitForChild("Byzantium")
local SharedAssets = replicatedStorageFolder.SharedAssets
local Constants = require(SharedAssets.Constants)

local fakeCharactersFolder = workspace:WaitForChild(Constants.FAKE_CHARACTERS_FOLDER_IDENTIFIER)

local function getFakeProjectionCharacter(player: Player | nil)
    if not player then
        assert(RunService:IsClient(), "A player argument must be specified when calling getFakeProjectionCharacter from the server")
        player = Players.LocalPlayer
    end

    return fakeCharactersFolder:FindFirstChild(player.Name)
end

return getFakeProjectionCharacter