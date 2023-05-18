local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local replicatedStorageFolder = ReplicatedStorage:WaitForChild("Byzantium")

local SharedAssets = replicatedStorageFolder.SharedAssets

local Modules = SharedAssets.Modules
local HitDetection = require(Modules.HitDetection)
local Laser = require(Modules.Laser)

local Constants = require(SharedAssets.Constants)

local Content = SharedAssets.Content
local Animations = require(Content.Animations)

local Packages = replicatedStorageFolder.Packages
local Ropost = require(Packages.Ropost)
local Flipper = require(Packages.Flipper)

local channel = Ropost.channel("Byzantium")

local localPlayer = Players.LocalPlayer

local rng = Random.new()

local CONFIGURATION = {
    DAMAGE = 100,
}

local TWEEN_INFO = {
    ORIGIN_TRANSPARENCY = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
    ORIGIN_TRANSPARENCY_OUT = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
    ORIGIN_CUBE = TweenInfo.new(2, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut),
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
        dampingRatio = 0.2,
    }
}

local function weld(part0: BasePart, part1: BasePart)
    local weldInstance = Instance.new("Weld")
    weldInstance.Name = part1.Name
    weldInstance.Part0 = part0
    weldInstance.Part1 = part1
    weldInstance.C0 = part1.CFrame:ToObjectSpace(part0.CFrame)
    weldInstance.Parent = part1
    return weldInstance
end

local LaserBlast = {}
LaserBlast.NAME = "LaserBlast"
LaserBlast.KEYCODE = Enum.KeyCode.G

function LaserBlast:nonPrivilegedSetup() 
    channel:subscribe("laserBlast", function(data)
        local player = data.player

        local character = player.Character
        if not character then
            return
        end

        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then
            return
        end

        local rightArm = character:FindFirstChild("Right Arm")
        if not rightArm then
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

        local origin = Laser:origin((rightArm.CFrame + rightArm.CFrame.UpVector))
        weld(rightArm, origin.Core)
        origin.Core.Shards.C1 = CFrame.new(0, 0, -1)
        for _, component in origin:GetChildren() do
            if component:IsA("BasePart") and component.Name ~= "Core" then
                component.Transparency = 1
                
                local highlight = component:FindFirstChild("Highlight")
                if highlight then
                    highlight.OutlineTransparency = 1
                    highlight.FillTransparency = 1

                    TweenService:Create(highlight, TWEEN_INFO.ORIGIN_TRANSPARENCY, {
                        FillTransparency = if highlight.Parent.Name == "Shards" then 0.7 else 1,
                        OutlineTransparency = if highlight.Parent.Name == "Shards" then 0.4 else 0,
                    }):Play()
                end

                TweenService:Create(component, TWEEN_INFO.ORIGIN_TRANSPARENCY, {
                    Transparency = 0,
                }):Play()
            end
        end

        local positionMotor = Flipper.SingleMotor.new(0)
        positionMotor:onStep(function(alpha)
            origin.Core.Shards.C1 = CFrame.new(0, 0, 0):Lerp(CFrame.new(0, 0, -1), alpha) * origin.Core.Shards.C1.Rotation
            origin.Core.Circle.C1 = CFrame.new(0, 0, 0):Lerp(CFrame.new(0, 0, -1.75), alpha) * origin.Core.Circle.C1.Rotation
            origin.Core.Octagon.C1 = CFrame.new(0, 0, 0):Lerp(CFrame.new(0, 0, -0.5), alpha) * origin.Core.Octagon.C1.Rotation
        end)

        local originCubeTween = TweenService:Create(origin.Cube, TWEEN_INFO.ORIGIN_CUBE, {
            Orientation = origin.Cube.Orientation + Vector3.new(rng:NextNumber(-1000, 1000), rng:NextNumber(-1000, 1000), rng:NextNumber(-1000, 1000)),
        })

        origin.Parent = rightArm

        originCubeTween:Play()

        local degreesPerSecond = 360
        local connection = RunService.Heartbeat:Connect(function(deltaTime)
            origin.Core.Shards.C1 *= CFrame.fromEulerAnglesXYZ(0, 0, -math.rad(degreesPerSecond * deltaTime))
            origin.Core.Circle.C1 *= CFrame.fromEulerAnglesXYZ(0, 0, math.rad(degreesPerSecond * deltaTime))
            origin.Core.Octagon.C1 *= CFrame.fromEulerAnglesXYZ(0, 0, math.rad(degreesPerSecond * deltaTime))
        end)

        positionMotor:setGoal(Flipper.Spring.new(1, SPRING_CONFIGS.POSITION))
    
        origin.Cube.Attachment.Flare:Emit(10)

        local laserBlastAnimationInstance = Instance.new("Animation")
        laserBlastAnimationInstance.AnimationId = Animations.LaserBlast
        local laserBlastAnimation = animator:LoadAnimation(laserBlastAnimationInstance)
        laserBlastAnimation:Play()

        laserBlastAnimation:GetMarkerReachedSignal("fire"):Connect(function()
            origin.Cube.Attachment.Pulse:Emit(origin.Cube.Attachment.Pulse:GetAttribute("EmitCount"))
            laserBlastAnimation:AdjustWeight(0.9, 0.3)
            Laser:laser(rootPart.CFrame + rootPart.CFrame.LookVector * 2.5, Color3.fromRGB(111, 100, 255), 0)

            local humanoidsToDamage = HitDetection:boxInFrontOf(rootPart.CFrame, 100, 5, 6)
            local ourHumanoid = table.find(humanoidsToDamage, humanoid)
            if ourHumanoid then
                table.remove(humanoidsToDamage, ourHumanoid)
            end
            
            if #humanoidsToDamage > 0 then
                channel:publish("damage", {
                    humanoidsToDamage = humanoidsToDamage,
                    damage = CONFIGURATION.DAMAGE,
                })
            end

            positionMotor:setGoal(Flipper.Spring.new(3, SPRING_CONFIGS.BOUNCE))
            task.delay(0.15, function()
                positionMotor:setGoal(Flipper.Spring.new(1, SPRING_CONFIGS.BOUNCE2))
            end)
        end)

        laserBlastAnimation:GetMarkerReachedSignal("fade"):Connect(function()
            laserBlastAnimation:Stop(1)
        end)

        laserBlastAnimation.Stopped:Connect(function()
            for _, component in origin:GetChildren() do
                if component:IsA("BasePart") and component.Name ~= "Core" then
                    local highlight = component:FindFirstChild("Highlight")
                    if highlight then
                        TweenService:Create(highlight, TWEEN_INFO.ORIGIN_TRANSPARENCY, {
                            FillTransparency = 1,
                            OutlineTransparency = 1,
                        }):Play()
                    end
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
end

function LaserBlast:run()
    local character = localPlayer.character
    if not character then
        return
    end

    if character:GetAttribute(Constants.ACTION_ATTRIBUTE_IDENTIFIER) then
		return
	end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return
    end

    if humanoid.Health == 0 then
        return
    end

    channel:publish("laserBlast", {})
end

return LaserBlast