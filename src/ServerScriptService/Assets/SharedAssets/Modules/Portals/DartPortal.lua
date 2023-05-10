local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Content = script.Parent.Parent.Parent.Content
local dartPortal = Content.DartPortal

local localPlayer = Players.LocalPlayer
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
}

local DartPortal = {}
DartPortal.__index = DartPortal

--[[
    play the tweens for opening or closing a dart portal
    if isOpen is true, the tween will play the opening sequence
    if isOpen is false, the tween will play the closing sequence
--]]
local function tween(portal: Part, isOpen: boolean)
    local highlight = portal:FindFirstChild("Highlight")

    local tween1 = TweenService:Create(portal, TWEEN_INFO.EXPAND1, {
        Size = Vector3.new(4, 0.3, 0),
    })
    local tween2 = TweenService:Create(portal, TWEEN_INFO.EXPAND2, {
        Size = Vector3.new(4, 0.3, 4),
    })

    local highlightTween = TweenService:Create(highlight, TWEEN_INFO.EXPAND1, {
        FillTransparency = if isOpen then 0 else 1,
        OutlineTransparency = if isOpen then 0 else 1,
    })

    if isOpen == true then
        tween1:Play()
        highlightTween:Play()
        tween1.Completed:Connect(function()
            tween2:Play()
        end)
    else
        local tween3 = TweenService:Create(portal, TWEEN_INFO.EXPAND1, {
            Size = Vector3.new(4, 0, 0),
        })

        tween1:Play()
        tween1.Completed:Connect(function()
            tween3:Play()
            highlightTween:Play()
        end)
    end
end

function DartPortal.new(cframe: CFrame)
    local self = setmetatable({}, DartPortal)

    self.portal = dartPortal:Clone()
    self.portal:PivotTo(cframe)
    self.portal.Parent = portalsFolder
    
    self:open()
end

function DartPortal:open()
    tween(self.portal, true)
end

function DartPortal:close()
    tween(self.portal, false)

    task.delay(0.7, function()
        self.portal:Destroy()
        for _, viewportFrame in playerGui:GetChildren() do
            if viewportFrame.Name == "PortalViewport" then
                viewportFrame:Destroy()
            end
        end
    end)
end

return DartPortal