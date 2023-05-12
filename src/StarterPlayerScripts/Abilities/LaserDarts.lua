local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedStorageFolder = ReplicatedStorage:WaitForChild("Byzantium")

local Utilities = script.Parent.Parent.Utilities
local castFromMouse = require(Utilities.castFromMouse)

local SharedAssets = replicatedStorageFolder.SharedAssets

local Modules = SharedAssets.Modules
local Portals = require(Modules.Portals)

local Content = SharedAssets.Content
local Animations = require(Content.Animations)

local Packages = replicatedStorageFolder.Packages
local Ropost = require(Packages.Ropost)

local localPlayer = Players.LocalPlayer

local channel = Ropost.channel("Byzantium")

local LaserDarts = {}
LaserDarts.NAME = "LaserDarts"
LaserDarts.KEYCODE = Enum.KeyCode.Y

function LaserDarts:setup()
end

function LaserDarts:run()
    local character = localPlayer.character
    if not character then
        return
    end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        return
    end

    local result = castFromMouse(RaycastParams.new(), 2000, true)
    if not result then
        return
    end

    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then
        return
    end

    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        return
    end
end

return LaserDarts