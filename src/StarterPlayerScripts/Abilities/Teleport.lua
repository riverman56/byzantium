local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedStorageFolder = ReplicatedStorage:WaitForChild("Byzantium")

local Utilities = script.Parent.Parent.Utilities
local castFromMouse = require(Utilities.castFromMouse)

local SharedAssets = replicatedStorageFolder.SharedAssets

local Modules = SharedAssets.Modules
local Portal = require(Modules.Portal)

local Content = SharedAssets.Content
local Animations = require(Content.Animations)

local Packages = replicatedStorageFolder.Packages
local Ropost = require(Packages.Ropost)
local Flipper = require(Packages.Flipper)

local localPlayer = Players.LocalPlayer

local channel = Ropost.channel("Byzantium")

local Teleport = {}
Teleport.KEYCODE = Enum.KeyCode.T

channel:subscribe("teleport", function(data)
    local origin = data.origin
    local destination = data.destination

    Portal.new(origin)
end)

function Teleport:setup()
end

function Teleport:run()
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

    local animationInstance = Instance.new("Animation")
    animationInstance.AnimationId = Animations.Action
    local animation = animator:LoadAnimation(animationInstance)
    animation:Play()

    -- destination portal orientation preservation
    local x, y, z = rootPart.CFrame:ToEulerAnglesXYZ()

    channel:publish("teleport", {
        origin = rootPart.CFrame + rootPart.CFrame.LookVector * 3 + Vector3.new(0, 1.5, 0),
        destination = CFrame.new(result.Position + Vector3.new(0, 4.5, 0)) * CFrame.fromEulerAnglesXYZ(x, y, z),
    })
end

return Teleport