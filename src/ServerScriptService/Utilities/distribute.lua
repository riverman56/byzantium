local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local root = script.Parent.Parent

local function distribute()
    local replicatedStorageFolder = Instance.new("Folder")
    replicatedStorageFolder.Name = "Byzantium"

    local serverStorageFolder = Instance.new("Folder")
    serverStorageFolder.Name = "Byzantium"
    
    root.Packages.Parent = replicatedStorageFolder
    root.Assets.SharedAssets.Parent = replicatedStorageFolder
    root.Assets.ServerAssets.Parent = serverStorageFolder

    replicatedStorageFolder.Parent = ReplicatedStorage
    serverStorageFolder.Parent = ServerStorage
end

return distribute