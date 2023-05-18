local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedStorageFolder = ReplicatedStorage.Byzantium

local SharedAssets = replicatedStorageFolder.SharedAssets
local Constants = require(SharedAssets.Constants)

local function createFolders()
    local fakeCharactersFolder = workspace:FindFirstChild(Constants.FAKE_CHARACTERS_FOLDER_IDENTIFIER)
    if not fakeCharactersFolder then
        fakeCharactersFolder = Instance.new("Folder")
        fakeCharactersFolder.Name = Constants.FAKE_CHARACTERS_FOLDER_IDENTIFIER
        fakeCharactersFolder.Parent = workspace
    end

    local cubesFolder = workspace:FindFirstChild(Constants.CUBES_FOLDER_IDENTIFIER)
    if not cubesFolder then
        cubesFolder = Instance.new("Folder")
        cubesFolder.Name = Constants.CUBES_FOLDER_IDENTIFIER
        cubesFolder.Parent = workspace
    end
end

return createFolders