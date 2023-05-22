local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local byzantiumRoot = script.Parent.Parent

local Utilities = byzantiumRoot.Utilities
local weld = require(Utilities.weld)

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
	HITBOX_LENGTH = 100,
	HITBOX_WIDTH_MULTIPLIER = 1.75,

	ORIGIN_ROTATION_RATE = 410, -- degrees/sec
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
	},
}

local LaserBlast = {}
LaserBlast.NAME = "LaserBlast"
LaserBlast.KEYCODE = Enum.KeyCode.G

local function onLaserBlastAnimationPlayed(character: Model, animationTrack: AnimationTrack)
    local targetPlayer = Players:GetPlayerFromCharacter(character)
    if not targetPlayer then
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

	local origin = Laser:origin((rightArm.CFrame + rightArm.CFrame.UpVector))
	weld(rightArm, origin.Core)

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

	local connection = RunService.Heartbeat:Connect(function(deltaTime)
		origin.Core.Shards.C1 *= CFrame.fromEulerAnglesXYZ(0, 0, -math.rad(CONFIGURATION.ORIGIN_ROTATION_RATE * deltaTime))
		origin.Core.Circle.C1 *= CFrame.fromEulerAnglesXYZ(0, 0, math.rad(CONFIGURATION.ORIGIN_ROTATION_RATE * deltaTime))
		origin.Core.Octagon.C1 *= CFrame.fromEulerAnglesXYZ(0, 0, math.rad(CONFIGURATION.ORIGIN_ROTATION_RATE * deltaTime))
	end)

	origin.Parent = rightArm

	originCubeTween:Play()

	positionMotor:setGoal(Flipper.Spring.new(1, SPRING_CONFIGS.POSITION))

	animationTrack:GetMarkerReachedSignal("fire"):Connect(function()
        if targetPlayer == localPlayer then
            animationTrack:AdjustWeight(0.9, 0.3)

            local humanoidsToDamage = HitDetection:boxInFrontOf(rootPart.CFrame, CONFIGURATION.HITBOX_LENGTH, 4 * CONFIGURATION.HITBOX_WIDTH_MULTIPLIER, 6)
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

            animationTrack:GetMarkerReachedSignal("fade"):Connect(function()
		        animationTrack:Stop(1)
	        end)
        end

		origin.Core.Attachment.Pulse:Emit(origin.Core.Attachment.Pulse:GetAttribute("EmitCount"))
        origin.Core.Attachment.Burst:Emit(origin.Core.Attachment.Burst:GetAttribute("EmitCount"))
		origin.Core.Attachment.Needles:Emit(origin.Core.Attachment.Needles:GetAttribute("EmitCount"))
		Laser:laser(rootPart.CFrame + rootPart.CFrame.LookVector * 2.5, Color3.fromRGB(111, 100, 255), 0)

		positionMotor:setGoal(Flipper.Spring.new(3, SPRING_CONFIGS.BOUNCE))
		task.delay(0.15, function()
			positionMotor:setGoal(Flipper.Spring.new(1, SPRING_CONFIGS.BOUNCE2))
		end)
	end)

	animationTrack.Stopped:Connect(function()
		for _, component in origin:GetChildren() do
			if component:IsA("BasePart") and component.Name ~= "Core" then
				local highlight = component:FindFirstChild("Highlight")
				if highlight then
					TweenService:Create(highlight, TWEEN_INFO.ORIGIN_TRANSPARENCY, {
						FillTransparency = 1,
						OutlineTransparency = 1,
					}):Play()
				end
				local tween = TweenService:Create(component, TWEEN_INFO.ORIGIN_TRANSPARENCY_OUT, { Transparency = 1 })
				tween:Play()

				tween.Completed:Connect(function()
					if connection then
						positionMotor:stop()
						connection:Disconnect()
						connection = nil
					end
				end)
			end
		end
	end)

	task.delay(5, function()
		origin:Destroy()
	end)
end

local function onCharacterAdded(character: Model)
	local humanoid = character:WaitForChild("Humanoid")
	local animator = humanoid:WaitForChild("Animator")

	animator.AnimationPlayed:Connect(function(animationTrack)
        if animationTrack.Animation.AnimationId == Animations.LaserBlast then
            onLaserBlastAnimationPlayed(character, animationTrack)
        end
    end)
end

local function onPlayerAdded(player: Player)
    local character = player.Character
    if character then
        onCharacterAdded(character)
    end
    player.CharacterAdded:Connect(onCharacterAdded)
end

function LaserBlast:nonPrivilegedSetup()
	Players.PlayerAdded:Connect(onPlayerAdded)
    for _, player in Players:GetPlayers() do
        onPlayerAdded(player)
    end
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
    local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		return
	end

	if humanoid.Health == 0 then
		return
	end

	local laserBlastAnimationInstance = Instance.new("Animation")
	laserBlastAnimationInstance.AnimationId = Animations.LaserBlast
	local laserBlastAnimation = animator:LoadAnimation(laserBlastAnimationInstance)
	laserBlastAnimation:Play()

	channel:publish("laserBlast", {})
end

return LaserBlast