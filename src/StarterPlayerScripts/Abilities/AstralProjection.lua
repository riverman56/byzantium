local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Utilities = script.Parent.Parent.Utilities
local castFromMouse = require(Utilities.castFromMouse)

local replicatedStorageFolder = ReplicatedStorage:WaitForChild("Byzantium")

local SharedAssets = replicatedStorageFolder.SharedAssets

local Modules = SharedAssets.Modules
local Ragdoll = require(Modules.Ragdoll)

local Packages = replicatedStorageFolder.Packages
local Ropost = require(Packages.Ropost)

local localPlayer = Players.LocalPlayer

local channel = Ropost.channel("Byzantium")

local isFlying = false

local vectorForce = nil
local alignOrientation = nil

local connection = nil
local ballSocketConstraints = {}
local guid = HttpService:GenerateGUID()

local LIMBS = {
    "Left Arm",
    "Right Arm",
    "Left Leg",
    "Right Leg",
    "Torso",
    "Head",
}
local CONFIGURATION = {
    DRAG = 3,
    FORCE = 50,
    DRAG_EXPONENT = 1.4,
}

local function getMass(instance: Instance)
    local mass = if instance:IsA("BasePart") and not (instance:: BasePart).Massless then (instance:: BasePart):GetMass() else 0

    for _, basePart in instance:GetDescendants() do
        if basePart:IsA("BasePart") and basePart.Massless ~= true then
            mass += basePart:GetMass()
        end
    end

    return mass
end

channel:subscribe("astralProjectVictim", function(data, envelope)
    local character = localPlayer.Character
    if not character then
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

    isFlying = true
    vectorForce.Enabled = true
    alignOrientation.Enabled = true
    humanoid:ChangeState(Enum.HumanoidStateType.Physics)
    workspace.Gravity = 0

    for _, animation in animator:GetPlayingAnimationTracks() do
        animation:Stop()
    end

    Ragdoll:setRagdoll(character, true)

    -- slow down limb physics
    local previousLimbCFrames = {}
    for _, limb in character:GetDescendants() do
        if table.find(LIMBS, limb.Name) and limb:IsA("BasePart") then
            previousLimbCFrames[limb.Name] = limb.CFrame
        end
    end

    RunService:BindToRenderStep(guid, Enum.RenderPriority.Camera.Value, function()
        for _, limb in character:GetDescendants() do
            if table.find(LIMBS, limb.Name) and limb:IsA("BasePart") then
                local currentCFrame = limb.CFrame
                limb.CFrame = previousLimbCFrames[limb.Name]:Lerp(currentCFrame, 0.3)
                previousLimbCFrames[limb.Name] = limb.CFrame
            end
        end
    end)

    -- constraint & movement math
    connection = RunService.Heartbeat:Connect(function()
        local trueCharacterMass = getMass(character)

        -- align the torso with the camera direction
        local cameraCFrame = workspace.CurrentCamera.CFrame
        alignOrientation.CFrame = cameraCFrame

        -- anti-gravity force
        vectorForce.Force = Vector3.new(0, workspace.Gravity, 0) * trueCharacterMass

        local moveDirection = humanoid.MoveDirection
        if moveDirection.Magnitude > 0 then
            local localizedMoveDirection = rootPart.CFrame:VectorToObjectSpace(moveDirection)

            local influenceUpwards = 0
            local angleToUpwards = math.deg(math.acos(rootPart.CFrame.LookVector:Dot(Vector3.yAxis)))
            if angleToUpwards < 90 then
                -- the character is looking somewhat upwards [0, 1]
                influenceUpwards = 1 - (angleToUpwards / 90)
            else
                -- the character is lookoing somewhat downwards.[-1, 0]
                influenceUpwards = -(angleToUpwards - 90) / 90
            end

            -- apply movement forces
            vectorForce.Force += (moveDirection * CONFIGURATION.FORCE * trueCharacterMass) + Vector3.new(0, influenceUpwards * CONFIGURATION.FORCE * trueCharacterMass * (if localizedMoveDirection.Z > 0 then -1 else 1), 0)
        end

        -- apply a drag force to the moving assembly
        if rootPart.AssemblyLinearVelocity.Magnitude > 0 then
            local dragVector = -rootPart.AssemblyLinearVelocity.Unit
            vectorForce.Force += dragVector * CONFIGURATION.DRAG * trueCharacterMass * (rootPart.AssemblyLinearVelocity.Magnitude ^ CONFIGURATION.DRAG_EXPONENT)
        end
    end)
end)

local function onLocalCharacterAdded(character: Model)
    local rootPart = character:WaitForChild("HumanoidRootPart")

    alignOrientation = Instance.new("AlignOrientation")
    alignOrientation.Enabled = false
    alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
    alignOrientation.MaxTorque = math.huge
    alignOrientation.MaxAngularVelocity = math.huge
    alignOrientation.Responsiveness = 180
    alignOrientation.Attachment0 = rootPart.RootAttachment
    alignOrientation.Parent = rootPart

    vectorForce = Instance.new("VectorForce")
    vectorForce.Enabled = false
    vectorForce.Force = Vector3.new(0, 0, 0)
    vectorForce.RelativeTo = Enum.ActuatorRelativeTo.World
    vectorForce.Attachment0 = rootPart.RootAttachment
    vectorForce.Parent = rootPart

    -- create the ragdoll joints
    Ragdoll:setup(character)
end

local AstralProjection = {}
AstralProjection.KEYCODE = Enum.KeyCode.F

function AstralProjection:setup()
    local character = localPlayer.Character
    if character then
        onLocalCharacterAdded(character)
    end
    localPlayer.CharacterAdded:Connect(onLocalCharacterAdded)
end

function AstralProjection:run()
    local character = localPlayer.Character
    if not character then
        localPlayer.CharacterAdded:Wait()
        character = localPlayer.Character
    end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
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

    local result = castFromMouse(RaycastParams.new(), 2000, true)
    if not result then
        return
    end

    local targetCharacter = result.Instance:FindFirstAncestorWhichIsA("Model")
    if not targetCharacter then
        return
    end

    local targetPlayer = Players:GetPlayerFromCharacter(targetCharacter)
    if not targetPlayer then
        return
    end

    local targetRootPart = targetCharacter:FindFirstChild("HumanoidRootPart")
    if not targetRootPart then
        return
    end

    local targetHumanoid = targetCharacter:FindFirstChild("Humanoid")
    if not targetHumanoid then
        return
    end

    local targetDestination = targetRootPart.CFrame.Position + targetRootPart.CFrame.LookVector * 4.3
    humanoid:MoveTo(targetDestination)

    local moveToFinishedConnection = nil
    moveToFinishedConnection = humanoid.MoveToFinished:Connect(function(reached)
        if not reached then
            humanoid:MoveTo(targetDestination)
            return
        end

        moveToFinishedConnection:Disconnect()
        moveToFinishedConnection = nil

        rootPart.CFrame = CFrame.lookAt(rootPart.Position, targetRootPart.Position)
        
        channel:publish("astralProject", {
            victim = targetPlayer,
        })
    end)

    --[[if isFlying then
        isFlying = false
        vectorForce.Enabled = false
        alignOrientation.Enabled = false
        humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
        workspace.Gravity = 196.2
        
        connection:Disconnect()
        connection = nil

        RunService:UnbindFromRenderStep(guid)
    end]]
end

return AstralProjection