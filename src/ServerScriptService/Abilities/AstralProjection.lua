local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedStorageFolder = ReplicatedStorage.Byzantium

local SharedAssets = replicatedStorageFolder.SharedAssets

local Modules = SharedAssets.Modules
local Ragdoll = require(Modules.Ragdoll)

local Packages = replicatedStorageFolder.Packages
local Ropost = require(Packages.Ropost)

local channel = Ropost.channel("Byzantium")

local AstralProjection = {}

channel:subscribe("astralProjectUser", function(data, envelope)
    local player = envelope.player
    local fakeCharacter = data.fakeCharacter
    local victimCharacter = data.victimCharacter

    local character = player.Character
    if not character then
        return
    end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        return
    end

    local fakeCharacterRootPart = fakeCharacter:FindFirstChild("HumanoidRootPart")
    if not fakeCharacterRootPart then
        return
    end

    local fakeCharacterHumanoid = fakeCharacter:FindFirstChildOfClass("Humanoid")
    if not fakeCharacterHumanoid then
        return
    end

    -- players cannot interact with the fake character
    for _, descendant in fakeCharacter:GetDescendants() do
        if descendant:IsA("BasePart") then
            descendant.CollisionGroup = "ByzantiumCharacters"
        end
    end

    fakeCharacterRootPart:SetNetworkOwner(nil)

    Ragdoll:setRagdoll(victimCharacter, true)

    rootPart.Anchored = false
    rootPart.CFrame = fakeCharacterRootPart.CFrame

    -- transition the genuine victim character into the projected state
    for _, descendant in character:GetDescendants() do
        if descendant:IsA("Decal") or (descendant:IsA("Accessory") and (descendant.AccessoryType ~= Enum.AccessoryType.Hat or descendant.AccessoryType ~= Enum.AccessoryType.Hair)) or descendant:IsA("BodyColors") or descendant:IsA("Shirt") or descendant:IsA("Pants") then
            descendant:Destroy()
        elseif descendant:IsA("BasePart") then
            descendant.CanCollide = false

            if descendant.Name ~= "HumanoidRootPart" then
                descendant.Transparency = 0
                descendant.CastShadow = false
                descendant.Color = Color3.fromRGB(111, 100, 255)
                descendant.Material = Enum.Material.ForceField
            end
        elseif descendant:IsA("Motor6D") then
            local matchingMotorParent = fakeCharacter:FindFirstChild(descendant.Parent.Name)
            if not matchingMotorParent then
                return
            end

            local matchingMotor = matchingMotorParent:FindFirstChild(descendant.Name)
            if not matchingMotor or not matchingMotor:IsA("Motor6D") then
                return
            end

            descendant.Transform = matchingMotor.Transform
        end
    end

    Ragdoll:setup(fakeCharacter)
    Ragdoll:setRagdoll(fakeCharacter, true)

    --fakeCharacterHumanoid.MaxHealth = math.huge
    --fakeCharacterHumanoid.Health = math.huge
end)

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

    for _, animationTrack in victimAnimator:GetPlayingAnimationTracks() do
        animationTrack:Stop()
    end
    
    victimRootPart.Anchored = true
    victimHumanoid:UnequipTools()
    victim.Backpack:ClearAllChildren()

    local victimClone = Players:CreateHumanoidModelFromDescription(victimHumanoid:GetAppliedDescription(), Enum.HumanoidRigType.R6)
    victimClone.Name = victim.Name

    local victimCloneRootPart = victimClone:FindFirstChild("HumanoidRootPart")

    --replace the victim's character with the fake one
    victimCloneRootPart.CFrame = victimRootPart.CFrame
    victimClone.Parent = workspace

    for _, descendant in victimCharacter:GetDescendants() do
        if descendant:IsA("BasePart") or descendant:IsA("Decal") then
            descendant.Transparency = 1
        elseif descendant:IsA("ParticleEmitter") or descendant:IsA("Light") then
            descendant.Enabled = false
        end
    end

    channel:publish("astralProjectAnimation", {
        user = player,
        victim = victim,
        fakeCharacter = victimClone,
    }, Players:GetPlayers())
end)

function AstralProjection:setup()
end

return AstralProjection