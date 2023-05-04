local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LaserBlast = {}
LaserBlast.KEYCODE = Enum.KeyCode.G

local replicatedStorageFolder = ReplicatedStorage:WaitForChild("Byzantium")

local SharedAssets = replicatedStorageFolder.SharedAssets

local Modules = SharedAssets.Modules
local Laser = require(Modules.Laser)

local Content = SharedAssets.Content
local Animations = require(Content.Animations)

local Packages = replicatedStorageFolder.Packages
local Ropost = require(Packages.Ropost)
local Flipper = require(Packages.Flipper)

local channel = Ropost.channel("Byzantium")

local localPlayer = Players.LocalPlayer

local rng = Random.new()

local TWEEN_INFO = {
    ORIGIN_TRANSPARENCY = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
    ORIGIN_TRANSPARENCY_OUT = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
    ORIGIN_CUBE = TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut),
    ORIGIN_ROTATION = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
}

local SPRING_CONFIGS = {
    POSITION = {
        frequency = 1,
        dampingRatio = 0.4,
    },
    BOUNCE = {
        frequency = 5,
        dampingRatio = 0.6,
    },
    BOUNCE2 = {
        frequency = 2.5,
        dampingRatio = 0.5,
    }
}

local function weld(part0: BasePart, part1: BasePart)
    local weldConstraint = Instance.new("WeldConstraint")
    weldConstraint.Name = part1.Name
    weldConstraint.Part0 = part0
    weldConstraint.Part1 = part1
    weldConstraint.Parent = part0
    return weldConstraint
end

channel:subscribe("laserBlast", function(data)
    local targetCharacter = data.target
    local rootPart = targetCharacter:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        return
    end

    local targetPlayer = Players:GetPlayerFromCharacter(targetCharacter)
    if not targetPlayer then
        return
    end

    local rightArm = targetCharacter:FindFirstChild("Right Arm")
    if not rightArm then
        return
    end

    local humanoid = targetCharacter:FindFirstChild("Humanoid")
    if not humanoid then
        return
    end

    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        return
    end

    local animationInstance = Instance.new("Animation")
    animationInstance.AnimationId = Animations.LaserBlast
    local animation = animator:LoadAnimation(animationInstance)
    animation:Play()

    local controlPart = Instance.new("Part")
    controlPart.Transparency = 1
    controlPart.CanCollide = false
    controlPart.Anchored = true
    controlPart.Massless = true
    controlPart.CFrame = rightArm.CFrame
    controlPart.Parent = workspace

    local origin = Laser:origin((rightArm.CFrame + rightArm.CFrame.UpVector) * CFrame.fromEulerAnglesXYZ(0, 0, math.rad(-90)))
    for _, component in origin:GetChildren() do
        if component:IsA("BasePart") then
            weld(controlPart, component)
            component.Transparency = 1
            TweenService:Create(component, TWEEN_INFO.ORIGIN_TRANSPARENCY, {
                Transparency = 0,
            }):Play()
        end
    end

    local positionMotor = Flipper.SingleMotor.new(0)
    positionMotor:onStep(function(alpha)
        origin.Circle.Position = origin.Cube.Position:Lerp((rightArm.CFrame + rightArm.CFrame.UpVector * 0.75).Position, alpha)
        origin.Shards.Position = origin.Cube.Position:Lerp(rightArm.Position, alpha)
        origin.Octagon.Position = origin.Cube.Position:Lerp((rightArm.CFrame - rightArm.CFrame.UpVector * 0.5).Position, alpha)
    end)

    local originCubeTween = TweenService:Create(origin.Cube, TWEEN_INFO.ORIGIN_CUBE, {
        Orientation = origin.Cube.Orientation + Vector3.new(rng:NextNumber(-1000, 1000), rng:NextNumber(-1000, 1000), rng:NextNumber(-1000, 1000)),
    })

    origin.Parent = workspace

    originCubeTween:Play()

    local elapsed = 0
    local degreesPerSecond = 360
    local connection = RunService.Heartbeat:Connect(function(deltaTime)
        elapsed += deltaTime
        controlPart.CFrame = rightArm.CFrame * CFrame.fromEulerAnglesXYZ(0, math.rad(degreesPerSecond * elapsed), 0)
    end)

    positionMotor:setGoal(Flipper.Spring.new(1, SPRING_CONFIGS.POSITION))
    
    origin.Cube.Attachment.Flare:Emit(10)

    animation:GetMarkerReachedSignal("fire"):Connect(function()
        animation:AdjustWeight(0.9, 0.3)
        Laser:laser(rootPart.CFrame + rootPart.CFrame.LookVector * 2.5, Color3.fromRGB(111, 100, 255), 0)
        positionMotor:setGoal(Flipper.Spring.new(3, SPRING_CONFIGS.BOUNCE))
        task.delay(0.15, function()
            positionMotor:setGoal(Flipper.Spring.new(1, SPRING_CONFIGS.BOUNCE2))
        end)
    end)

    animation:GetMarkerReachedSignal("fade"):Connect(function()
        animation:Stop(1)
    end)

    animation.Stopped:Connect(function()
        for _, component in origin:GetChildren() do
            if component:IsA("BasePart") then
                TweenService:Create(component, TWEEN_INFO.ORIGIN_TRANSPARENCY_OUT, { Transparency = 1 }):Play()
            end
        end
    end)

    task.delay(5, function()
        connection:Disconnect()
        connection = nil
        origin:Destroy()
    end)

end)

function LaserBlast:setup() 
end

function LaserBlast:run()
    local character = localPlayer.character
    if not character then
        return
    end

    channel:publish("laserBlast", {})
end

return LaserBlast