local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedStorageFolder = ReplicatedStorage:WaitForChild("Byzantium")

local Utilities = script.Parent.Parent.Utilities
local castFromMouse = require(Utilities.castFromMouse)

local SharedAssets = replicatedStorageFolder.SharedAssets

local Constants = require(SharedAssets.Constants)

local Modules = SharedAssets.Modules
local Portals = require(Modules.Portals)

local Content = SharedAssets.Content
local Animations = require(Content.Animations)

local Packages = replicatedStorageFolder.Packages
local Ropost = require(Packages.Ropost)

local localPlayer = Players.LocalPlayer

local channel = Ropost.channel("Byzantium")

local portalsFolder = workspace:FindFirstChild("BYZANTIUM_PORTALS")
if not portalsFolder then
    portalsFolder = Instance.new("Folder")
    portalsFolder.Name = "BYZANTIUM_PORTALS"
    portalsFolder.Parent = workspace
end

local Teleport = {}
Teleport.NAME = "Teleport"
Teleport.KEYCODE = Enum.KeyCode.T

function Teleport:nonPrivilegedSetup()
    channel:subscribe("teleport", function(data)
        local origin = data.origin
        local destination = data.destination

        Portals.createTeleportationPortal(origin, portalsFolder.Gateways)
        Portals.createTeleportationPortal(destination * CFrame.fromEulerAnglesXYZ(0, math.rad(180), 0), portalsFolder.Entrance)
    end)
end

function Teleport:run()
    local character = localPlayer.character
    if not character then
        return
    end

    if character:GetAttribute(Constants.ACTION_ATTRIBUTE_IDENTIFIER) then
		return
	end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
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

    local result = castFromMouse(RaycastParams.new(), 2000, true)
    if not result then
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