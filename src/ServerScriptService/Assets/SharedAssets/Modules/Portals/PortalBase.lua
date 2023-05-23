local TweenService = game:GetService("TweenService")

type PortalBaseInstance = BasePart | Model

type PropertyTable = {[string]: any}

type TweenSequence = {
    instance: (Instance | (root: PortalBaseInstance) -> (Instance))?,
    tweenInfo: TweenInfo,
    propertyTable: PropertyTable | (root: PortalBaseInstance) -> (PropertyTable),
    doNotYield: boolean?,
}

type TweenSequencesBase = {[number]: TweenSequence}
type TweenSequences = {
    open: TweenSequencesBase,
    close: TweenSequencesBase,
}

type OnTweenSequenceCompleted = (sequenceIndex: number) -> ()

type Signal = {
    subscribe: () -> (),
    fire: () -> (),
}

type PortalBase = {
    instance: Instance,
    onTweenSequenceCompleted: Signal,
    onOpen: Signal,
    onClose: Signal,
}

local Utilities = script.Parent.Utilities
local createSignal = require(Utilities.createSignal)

local PortalBase = {}
PortalBase.__index = PortalBase

function PortalBase.new(base: PortalBaseInstance, cframe: CFrame, parent: Instance, tweenSequences: TweenSequences): PortalBase
    local self = setmetatable({}, PortalBase)

    self.instance = base:Clone()
    self.parent = parent
    self.tweenSequences = tweenSequences
    self.onTweenSequenceCompleted = createSignal()
    self.onOpen = createSignal()
    self.onClose = createSignal()

    if self.instance:IsA("Model") then
        self.instance:PivotTo(cframe)
    else
        self.instance.CFrame = cframe
    end

    return self
end

function PortalBase:_doTweenSequence(type: "open" | "close")
    task.spawn(function()
        for index, tweenSequence in self.tweenSequences[type] do
            local instance = self.instance
            if tweenSequence.instance then
                if typeof(tweenSequence.instance) == "function" then
                    instance = tweenSequence.instance(self.instance)
                else
                    instance = tweenSequence.instance
                end
            end

            local propertyTable = if typeof(tweenSequence.propertyTable) == "function" then tweenSequence.propertyTable(self.instance) else tweenSequence.propertyTable

            local tween = TweenService:Create(instance, tweenSequence.tweenInfo, propertyTable)
            tween:Play()
            tween.Completed:Connect(function()
                self.onTweenSequenceCompleted:fire(index + (if type == "close" then #self.tweenSequences.open else 0))
            end)
            
            if not tweenSequence.doNotYield then
                tween.Completed:Wait()
            end
        end
    end)
end

function PortalBase:open()
    self.instance.Parent = self.parent

    self:_doTweenSequence("open")
    self.onOpen:fire()
end

function PortalBase:close()
    self:_doTweenSequence("close")
    self.onClose:fire()
    self.instance:Destroy()
end

return PortalBase