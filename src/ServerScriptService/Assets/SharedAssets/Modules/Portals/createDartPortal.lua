local TweenService = game:GetService("TweenService")
local Content = script.Parent.Parent.Parent.Content
local dartPortal = Content.DartPortal

local PortalBase = require(script.Parent.PortalBase)

local TWEEN_INFO = {    
    EXPAND1 = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
    EXPAND2 = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
}

local TWEEN_SEQUENCES = {
    open = {
        {
            tweenInfo = TWEEN_INFO.EXPAND1,
            propertyTable = {
                Transparency = 0,
                Size = Vector3.new(4, 0.3, 0),
            },
        },
        {
            tweenInfo = TWEEN_INFO.EXPAND2,
            propertyTable = {
                Size = Vector3.new(4, 0.3, 4),
            },
        },
    },
    close = {
        {
            tweenInfo = TWEEN_INFO.EXPAND1,
            propertyTable = {
                Size = Vector3.new(4, 0.3, 0),
            },
        },
        {
            tweenInfo = TWEEN_INFO.EXPAND2,
            propertyTable = {
                Transparency = 1,
                Size = Vector3.new(4, 0, 0),
            },
        },
    },
}

local function tweenHighlight(highlight: Highlight, isOn: boolean)
    TweenService:Create(highlight, TWEEN_INFO.EXPAND2, {
        FillTransparency = if isOn then 0 else 1,
        OutlineTransparency = if isOn then 0 else 1,
    }):Play()
end

local function createDartPortal(cframe: CFrame, parent: Instance)
    local portal = PortalBase.new(dartPortal, cframe, parent or workspace, TWEEN_SEQUENCES)
    portal.onOpen:subscribe(function()
        portal.instance.Open:Play()
        tweenHighlight(portal.instance.Highlight, true)
    end)
    portal.onClose:subscribe(function()
        portal.instance.Close:Play()
        portal.instance.Close.Ended:Wait()
    end)
    portal.onTweenSequenceCompleted:subscribe(function(index)
        if index == 3 then
            tweenHighlight(portal.instance.Highlight, false)
        end
    end)

    portal:open()
    task.delay(1, function()
        portal:close()
    end)
    
    return portal
end

return createDartPortal