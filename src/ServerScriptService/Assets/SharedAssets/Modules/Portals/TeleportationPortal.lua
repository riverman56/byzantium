local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Content = script.Parent.Parent.Parent.Content
local portal = Content.Portal

local localPlayer = Players.LocalPlayer
local Character = localPlayer.Character or localPlayer.CharacterAdded:Wait() -- only called once sorry for the bad code - luca
local playerGui = localPlayer:WaitForChild("PlayerGui")

local portalsFolder = workspace:FindFirstChild("BYZANTIUM_PORTALS")
if not portalsFolder then
    portalsFolder = Instance.new("Folder")
    portalsFolder.Name = "BYZANTIUM_PORTALS"
    portalsFolder.Parent = workspace
end

local TWEEN_INFO = {    
    EXPAND1 = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
    EXPAND2 = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    POSITION = TweenInfo.new(0.4, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
}

local TeleportationPortal = {}
TeleportationPortal.__index = TeleportationPortal

--[[
    play the tweens for opening or closing a portal door
    if isOpen is true, the tween will play the opening sequence
    if isOpen is false, the tween will play the closing sequence
--]]
local function tweenDoor(portalDoor: Part, isOpen: boolean)
    local tween1 = TweenService:Create(portalDoor, TWEEN_INFO.EXPAND1, {
        Size = Vector3.new(6, 0, 2),
    })
    local tween2 = TweenService:Create(portalDoor, TWEEN_INFO.EXPAND2, {
        Size = Vector3.new(6, 9, 2),
    })
    local positionTween = TweenService:Create(portalDoor, TWEEN_INFO.POSITION, {
        Position = if isOpen then (portalDoor:FindFirstChild("Goal"):: Attachment).WorldPosition else (portalDoor:FindFirstChild("Origin"):: Attachment).WorldPosition,
    })

    local finalTween = tween2

    if isOpen == true then
        tween1:Play()
        tween1.Completed:Connect(function()
            tween2:Play()
            tween2.Completed:Connect(function()
                positionTween:Play()
                Character:FindFirstChild("FixedBlock").Enabled = true
            end)
        end)
    else
        local tween3 = TweenService:Create(portalDoor, TWEEN_INFO.EXPAND1, {
            Size = Vector3.new(6, 0, 0),
        })

        finalTween = tween3

        positionTween:Play()
        positionTween.Completed:Connect(function()
            tween1:Play()
            tween1.Completed:Connect(function()
                tween3:Play()
            end)
        end)
    end

    return finalTween
end

function TeleportationPortal.new(cframe: CFrame, parent: Instance)
    local self = setmetatable({}, TeleportationPortal)

    self.portal = portal:Clone()
    self.portal:PivotTo(cframe)
    self.portal.Parent = parent
    
    self:open()
    task.delay(5, function()
        self:close()
    end)
end

function TeleportationPortal:open()
    local expandTween = TweenService:Create(self.portal.Core, TWEEN_INFO.POSITION, {
        Size = Vector3.new(8, 9, 2),
    })

    tweenDoor(self.portal.Left, true)
    local doorTween = tweenDoor(self.portal.Right, true)

    doorTween.Completed:Connect(function()
        self.portal.Core.Transparency = 0
        expandTween:Play()
    end)
end

function TeleportationPortal:close()
    local contractTween = TweenService:Create(self.portal.Core, TWEEN_INFO.POSITION, {
        Size = Vector3.new(0, 9, 2),
    })

    tweenDoor(self.portal.Left, false)
    local doorTween = tweenDoor(self.portal.Right, false)
    contractTween:Play()

    contractTween.Completed:Connect(function()
        self.portal.Core.Transparency = 1
    end)

    Character:FindFirstChild("FixedBlock").Enabled = false

    doorTween.Completed:Connect(function()
        self.portal:Destroy()
        for _, viewportFrame in playerGui:GetChildren() do
            if viewportFrame.Name == "PortalViewport" then
                viewportFrame:Destroy()
            end
        end
    end)
end

return TeleportationPortal