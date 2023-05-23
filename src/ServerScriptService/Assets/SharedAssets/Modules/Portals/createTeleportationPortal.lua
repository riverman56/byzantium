local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Content = script.Parent.Parent.Parent.Content
local teleportationPortal = Content.Portal

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local PortalBase = require(script.Parent.PortalBase)

local TWEEN_INFO = {
	EXPAND1 = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
	EXPAND2 = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	POSITION = TweenInfo.new(0.4, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
}

local TWEEN_SEQUENCES = {
    open = {
        -- expand width
        {
            instance = function(root)
                return root.Left
            end,
            tweenInfo = TWEEN_INFO.EXPAND1,
            propertyTable = {
                Transparency = 0,
                Size = Vector3.new(6, 0, 2),
            },
            doNotYield = true,
        },
        {
            instance = function(root)
                return root.Right
            end,
            tweenInfo = TWEEN_INFO.EXPAND1,
            propertyTable = {
                Transparency = 0,
                Size = Vector3.new(6, 0, 2),
            },
        },

        -- expand height
        {
            instance = function(root)
                return root.Left
            end,
            tweenInfo = TWEEN_INFO.EXPAND2,
            propertyTable = {
                Size = Vector3.new(6, 9, 2),
            },
            doNotYield = true,
        },
        {
            instance = function(root)
                return root.Right
            end,
            tweenInfo = TWEEN_INFO.EXPAND2,
            propertyTable = {
                Size = Vector3.new(6, 9, 2),
            },
        },

        -- expand core
        {
            instance = function(root)
                return root.Core
            end,
            tweenInfo = TWEEN_INFO.POSITION,
            propertyTable = {
                Size = Vector3.new(8, 9, 2),
            },
            doNotYield = true,
        },
        -- core transparency
        {
            instance = function(root)
                return root.Core
            end,
            tweenInfo = TWEEN_INFO.EXPAND1,
            propertyTable = {
                Transparency = 0,
            },
            doNotYield = true,
        },

        -- positions
        {
            instance = function(root)
                return root.Left
            end,
            tweenInfo = TWEEN_INFO.POSITION,
            propertyTable = function(root)
                local goalAttachment = root.Left:FindFirstChild("Goal")
                return {
                    Position = goalAttachment.WorldPosition,
                }
            end,
            doNotYield = true,
        },
        {
            instance = function(root)
                return root.Right
            end,
            tweenInfo = TWEEN_INFO.POSITION,
            propertyTable = function(root)
                local goalAttachment = root.Right:FindFirstChild("Goal")
                return {
                    Position = goalAttachment.WorldPosition,
                }
            end,
        },
    },
    close = {
        -- contract core
        {
            instance = function(root)
                return root.Core
            end,
            tweenInfo = TWEEN_INFO.POSITION,
            propertyTable = {
                Size = Vector3.new(0, 9, 2),
            },
            doNotYield = true,
        },
        -- core transparency
        {
            instance = function(root)
                return root.Core
            end,
            tweenInfo = TWEEN_INFO.EXPAND1,
            propertyTable = {
                Transparency = 1,
            },
            doNotYield = true,
        },

        -- positions
        {
            instance = function(root)
                return root.Left
            end,
            tweenInfo = TWEEN_INFO.POSITION,
            propertyTable = function(root)
                local originAttachment = root.Left:FindFirstChild("Origin")
                return {
                    Position = originAttachment.WorldPosition,
                }
            end,
            doNotYield = true,
        },
        {
            instance = function(root)
                return root.Right
            end,
            tweenInfo = TWEEN_INFO.POSITION,
            propertyTable = function(root)
                local originAttachment = root.Right:FindFirstChild("Origin")
                return {
                    Position = originAttachment.WorldPosition,
                }
            end,
        },
        --contract height
        {
            instance = function(root)
                return root.Left
            end,
            tweenInfo = TWEEN_INFO.EXPAND1,
            propertyTable = {
                Size = Vector3.new(6, 0, 2),
            },
            doNotYield = true,
        },
        {
            instance = function(root)
                return root.Right
            end,
            tweenInfo = TWEEN_INFO.EXPAND1,
            propertyTable = {
                Size = Vector3.new(6, 0, 2),
            },
        },
        -- contract final
        {
            instance = function(root)
                return root.Left
            end,
            tweenInfo = TWEEN_INFO.EXPAND2,
            propertyTable = {
                Transparency = 1,
                Size = Vector3.new(6, 0, 0),
            },
            doNotYield = true,
        },
        {
            instance = function(root)
                return root.Right
            end,
            tweenInfo = TWEEN_INFO.EXPAND2,
            propertyTable = {
                Transparency = 1,
                Size = Vector3.new(6, 0, 0),
            },
        },
    },
}

local function tweenHighlight(highlight: Highlight, isOn: boolean)
    TweenService:Create(highlight, TWEEN_INFO.EXPAND2, {
        FillTransparency = if isOn then 0.8 else 1,
        OutlineTransparency = if isOn then 0 else 1,
    }):Play()
end

local function createTeleportationPortal(cframe: CFrame, parent: Instance)
    local portal = PortalBase.new(teleportationPortal, cframe, parent, TWEEN_SEQUENCES)
    portal.onOpen:subscribe(function()
        portal.instance.Core.Open:Play()
        portal.instance.Core.Hum:Play()
        tweenHighlight(portal.instance.Left.Highlight, true)
        tweenHighlight(portal.instance.Right.Highlight, true)
    end)
    portal.onClose:subscribe(function()
        for _, viewportFrame in playerGui:GetChildren() do
		    if viewportFrame.Name == "PortalViewport" then
			    viewportFrame:Destroy()
		    end
	    end

        portal.instance.Core.Close:Play()
        portal.instance.Core.Close.Ended:Wait()
    end)
    portal.onTweenSequenceCompleted:subscribe(function(index)
        if index == 1 or index == 11 then
            local character = localPlayer.Character
            if not character then
                return
            end

            local portalInit = character:FindFirstChild("PortalInit")
            if not portalInit then
                return
            end
            
            portalInit.Enabled = if index == 1 then true else false
        elseif index == 14 then
            tweenHighlight(portal.instance.Left.Highlight, false)
            tweenHighlight(portal.instance.Right.Highlight, false)
        end
    end)

    portal:open()
    task.delay(5, function()
        portal:close()
    end)

    return portal
end

return createTeleportationPortal