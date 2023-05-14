local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedStorageFolder = ReplicatedStorage:WaitForChild("Byzantium")

local SharedAssets = replicatedStorageFolder.SharedAssets
local Constants = require(SharedAssets.Constants)

local function getCubesFolder(): Folder
    local cubesFolder = workspace:FindFirstChild(Constants.CUBES_FOLDER_IDENTIFIER)
    if not cubesFolder then
        cubesFolder = Instance.new("Folder")
        cubesFolder.Name = Constants.CUBES_FOLDER_IDENTIFIER
        cubesFolder.Parent = workspace
    end

    return cubesFolder
end

return getCubesFolder