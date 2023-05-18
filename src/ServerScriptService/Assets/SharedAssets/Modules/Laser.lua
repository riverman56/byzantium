local TweenService = game:GetService("TweenService")

local TWEEN_INFO = {
	TRANSPARENCY_IN = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
	SIZE_IN = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
	POSITION_1 = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
	POSITION_2 = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	
	TRANSPARENCY_OUT = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
	
	TIME_SCALE = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
}

local TWEEN_INFO_DART = {
	TRANSPARENCY_IN = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
	SIZE_IN = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
	POSITION_1 = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
	POSITION_2 = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	
	TRANSPARENCY_OUT = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
	
	TIME_SCALE = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
}

local Content = script.Parent.Parent.Content
local laser = Content.Laser
local dart = Content.Dart
local laserOrigin = Content.LaserOrigin

local Laser = {}

local function changeColor(target: Model, color: Color3)
	for _, descendant in target:GetDescendants() do
		if descendant:IsA("ParticleEmitter") then
			descendant.Color = ColorSequence.new(color)
		elseif descendant:IsA("BasePart") or descendant:IsA("Light") then
			descendant.Color = color
		end
	end
end

function Laser:origin(cframe: CFrame)
	local originClone = laserOrigin:Clone()
	originClone:PivotTo(cframe)

	originClone.Core.Charge:Play()
	originClone.Cube.Attachment.Flare:Emit(originClone.Cube.Attachment.Flare:GetAttribute("EmitCount"))
	originClone.Cube.Attachment.Shine:Emit(originClone.Cube.Attachment.Shine:GetAttribute("EmitCount"))
	originClone.Cube.Attachment.Shine2:Emit(originClone.Cube.Attachment.Shine2:GetAttribute("EmitCount"))

	return originClone
end

function Laser:dart(cframe: CFrame, color: Color3)
	local dartClone = dart:Clone()
	dartClone:PivotTo(cframe)

	changeColor(dartClone, color)

	local transparencyTween = TweenService:Create(dartClone.Sphere, TWEEN_INFO_DART.TRANSPARENCY_IN, {
		Transparency = 0,
	})
	local position1Tween = TweenService:Create(dartClone.Sphere, TWEEN_INFO_DART.POSITION_1, {
		CFrame = dartClone.Root.CFrame + (dartClone.Root.CFrame.LookVector.Unit * (26 / 2)),
		Size = Vector3.new(2, 2, 26),
	})
	local position2Tween = TweenService:Create(dartClone.Sphere, TWEEN_INFO_DART.POSITION_2, {
		CFrame = dartClone.Root.CFrame + (dartClone.Root.CFrame.LookVector.Unit * (70 / 2)),
		Size = Vector3.new(0.001, 0.001, 70),
	})
	local transparencyOutTween = TweenService:Create(dartClone.Sphere, TWEEN_INFO_DART.TRANSPARENCY_OUT, {
		Transparency = 1,
	})

	transparencyOutTween.Completed:Connect(function()
		task.wait(5)
		dartClone:Destroy()
	end)

	dartClone.Parent = workspace
	
	dartClone.Sphere.Fire:Play()
		
	transparencyTween:Play()
	position1Tween:Play()
	position1Tween.Completed:Connect(function()
		position2Tween:Play()
		position2Tween.Completed:Connect(function()
			dartClone.Sphere.Embers.Enabled = false
			dartClone.Sphere.Squares.Enabled = false
			transparencyOutTween:Play()
		end)
	end)

	return dartClone
end

function Laser:laser(cframe: CFrame, color: Color3)
	local laserClone = laser:Clone()
	laserClone:PivotTo(cframe)
	
	changeColor(laserClone, color)
	
	local transparencyTween = TweenService:Create(laserClone.Sphere, TWEEN_INFO.TRANSPARENCY_IN, {
		Transparency = 0,
	})
	local position1Tween = TweenService:Create(laserClone.Sphere, TWEEN_INFO.POSITION_1, {
		CFrame = laserClone.Root.CFrame + (laserClone.Root.CFrame.LookVector.Unit * (54 / 2)),
		Size = Vector3.new(4, 4, 54),
	})
	local position2Tween = TweenService:Create(laserClone.Sphere, TWEEN_INFO.POSITION_2, {
		CFrame = laserClone.Root.CFrame + (laserClone.Root.CFrame.LookVector.Unit * (150 / 2)),
		Size = Vector3.new(0.001, 0.001, 150),
	})
	local transparencyOutTween = TweenService:Create(laserClone.Sphere, TWEEN_INFO.TRANSPARENCY_OUT, {
		Transparency = 1,
	})

	transparencyOutTween.Completed:Connect(function()
		task.wait(5)
		laserClone:Destroy()
	end)

	laserClone.Parent = workspace

	laserClone.Sphere.Fire:Play()
		
	transparencyTween:Play()
	position1Tween:Play()
	position1Tween.Completed:Connect(function()
		position2Tween:Play()
		position2Tween.Completed:Connect(function()
			laserClone.Sphere.Embers.Enabled = false
			laserClone.Sphere.Squares.Enabled = false
			transparencyOutTween:Play()
		end)
	end)

	return laserClone
end

return Laser