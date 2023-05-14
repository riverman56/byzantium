local TweenService = game:GetService("TweenService")
local Content = script.Parent.Parent.Content
local shockwave = Content.Shockwave

local TWEEN_INFO = {
    SIZE = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
}

local Shockwave = {}

function Shockwave:shockwave(cframe: CFrame)
    local shockwaveClone = shockwave:Clone()

    local sizeTween = TweenService:Create(shockwaveClone, TWEEN_INFO.SIZE, {
        Size = Vector3.new(20, 20, 20),
        Transparency = 1,
    })

    shockwaveClone.CFrame = cframe
    shockwaveClone.Parent = workspace

    shockwaveClone.Impact:Play()

    sizeTween:Play()
    for _, descendant in shockwaveClone:GetDescendants() do
        if descendant:IsA("ParticleEmitter") then
            descendant:Emit(descendant:GetAttribute("EmitCount"))
        end
    end

    task.delay(3, function()
        shockwaveClone:Destroy()
    end)
end

return Shockwave