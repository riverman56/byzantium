local TweenService = game:GetService("TweenService")

local TWEEN_INFO = {
	TRANSPARENCY_IN = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
	SIZE_IN = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
	POSITION_1 = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
	POSITION_2 = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	
	TRANSPARENCY_OUT = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
	
	TIME_SCALE = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
}

local Content = script.Parent.Parent.Content
local laser = Content.Laser
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

	return originClone
end

function Laser:dart(cframe: CFrame, color: Color3)
	
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
	
	laserClone.Root.Charge:Play()
	
	laserClone.Sphere.Beam:Play()
		
	transparencyTween:Play()
	position1Tween:Play()
	position1Tween.Completed:Wait()
	position2Tween:Play()
	position2Tween.Completed:Wait()
	transparencyOutTween:Play()

	return Laser
end

return Laser