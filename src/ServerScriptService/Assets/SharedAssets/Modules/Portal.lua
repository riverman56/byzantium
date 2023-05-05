local TweenService = game:GetService("TweenService")
local Content = script.Parent.Parent.Content
local portal = Content.Portal

local TWEEN_INFO = {    
    EXPAND1 = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
    EXPAND2 = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    POSITION = TweenInfo.new(0.4, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
}

local Portal = {}
Portal.__index = Portal

local function openTween(portalDoor: Part)
    local expandTween1 = TweenService:Create(portalDoor, TWEEN_INFO.EXPAND1, {
        Size = Vector3.new(6, 0, 2),
    })
    local expandTween2 = TweenService:Create(portalDoor, TWEEN_INFO.EXPAND2, {
        Size = Vector3.new(6, 9, 2),
    })
    local positionTween = TweenService:Create(portalDoor, TWEEN_INFO.POSITION, {
        Position = (portalDoor:FindFirstChild("Goal"):: Attachment).WorldPosition,
    })

    expandTween1:Play()
    expandTween1.Completed:Connect(function()
        expandTween2:Play()
        expandTween2.Completed:Connect(function()
            positionTween:Play()
        end)
    end)
end

function Portal.new(cframe: CFrame)
    local self = setmetatable({}, Portal)

    self.portal = portal:Clone()
    self.portal:PivotTo(cframe)
    local portals = workspace:FindFirstChild("Portals") or Instance.new("Folder", workspace)
    self.portal.Parent = portals
    self:open()
end

function Portal:open()
    local expandTween = TweenService:Create(self.portal.Core, TWEEN_INFO.POSITION, {
        Size = Vector3.new(8, 9, 2),
    })

    openTween(self.portal.Left)
    openTween(self.portal.Right)

    task.delay(0.7, function()
        self.portal.Core.Transparency = 0
        expandTween:Play()
    end)
end

function Portal:close()
        self.portal:Destroy()
end

return Portal