local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedStorageFolder = ReplicatedStorage.Byzantium

local SharedAssets = replicatedStorageFolder.SharedAssets

local Modules = SharedAssets.Modules
local Ragdoll = require(Modules.Ragdoll)

local Content = SharedAssets.Content
local Animations = require(Content.Animations)

local Packages = replicatedStorageFolder.Packages
local Ropost = require(Packages.Ropost)

local channel = Ropost.channel("Byzantium")

local AstralProjection = {}

channel:subscribe("astralProject", function(data, envelope)
    local player = envelope.player

    local character = player.Character
    if not character then
        return
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return
    end
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        return
    end

    local victim = data.victim

    local victimCharacter = victim.Character
    if not victimCharacter then
        return
    end
    local victimRootPart = victimCharacter:FindFirstChild("HumanoidRootPart")
    if not victimRootPart then
        return
    end
    local victimHumanoid = victimCharacter:FindFirstChildOfClass("Humanoid")
    if not victimHumanoid then
        return
    end
    local victimAnimator = victimHumanoid:FindFirstChildOfClass("Animator")
    if not victimAnimator then
        return
    end

    victimRootPart.Anchored = true
    for _, animationTrack in victimAnimator:GetPlayingAnimationTracks() do
        animationTrack:Stop()
    end
    
    victimHumanoid:UnequipTools()
    victim.Backpack:ClearAllChildren()

    local victimClone = Players:CreateHumanoidModelFromDescription(victimHumanoid:GetAppliedDescription(), Enum.HumanoidRigType.R6)
    
    local victimCloneRootPart = victimClone:FindFirstChild("HumanoidRootPart")
    local victimCloneHumanoid = victimClone:FindFirstChildOfClass("Humanoid")
    local victimCloneAnimator = victimHumanoid:FindFirstChildOfClass("Animator")

    victimCloneRootPart.CFrame = victimRootPart.CFrame

    local animationInstance = Instance.new("Animation")
    animationInstance.AnimationId = Animations.AstralProjectUser
    local astralProjectUser = animator:LoadAnimation(animationInstance)
    astralProjectUser:Play()

    local animationInstance2 = Instance.new("Animation")
    animationInstance2.AnimationId = Animations.AstralProjectVictim
    local astralProjectVictim = victimCloneAnimator:LoadAnimation(animationInstance2)
    astralProjectVictim:Play()

    astralProjectVictim:GetMarkerReachedSignal("project"):Connect(function()
        -- transition the genuine victim character into the projected state
        for _, descendant in victimCharacter:GetDescendants() do
            if descendant:IsA("Decal") or (descendant:IsA("Accessory") and (descendant.AccessoryType ~= Enum.AccessoryType.Hat or descendant.AccessoryType ~= Enum.AccessoryType.Hair)) then
                descendant:Destroy()
            elseif descendant:IsA("BasePart") then
                descendant.CastShadow = false
                descendant.Color = Color3.fromRGB(111, 100, 255)
                descendant.Material = Enum.Material.ForceField
            end
        end

        channel:publish("astralProjectVictim", {
            fakeCharacter = victimClone,
            victimAnimation = astralProjectVictim,
        }, Players:GetPlayers())
    end)

    astralProjectVictim:GetMarkerReachedSignal("end"):Connect(function()
        Ragdoll:setup(victimClone)
        Ragdoll:setRagdoll(victimClone, true)

        victimCloneHumanoid.WalkSpeed = 0
        victimCloneHumanoid.JumpHeight = 0

        victimCloneHumanoid.MaxHealth = math.huge
        victimCloneHumanoid.Health = math.huge

        -- TODO: make other characters non collidable w collision group
    end)
end)

function AstralProjection:setup()
end

return AstralProjection