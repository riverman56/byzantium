local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedStorageFolder = ReplicatedStorage:WaitForChild("Byzantium")

local Packages = replicatedStorageFolder.Packages
local Flipper = require(Packages.Flipper)

local Utilities = script.Parent.Utilities
local applyProperties = require(Utilities.applyProperties)
local lerp = require(Utilities.lerp)
local lerpCIELUV = require(Utilities.lerpCIELUV)

local Types = require(script.Parent.Types)

local Constants = {
    DEFAULT_PROPERTIES = {
        Color = Color3.fromRGB(255, 255, 255),
        Decay = Color3.fromRGB(255, 255, 255),
        Density = 0,
        Glare = 0,
        Haze = 0,
        Offset = 0,
    },
    ATMOSPHERE_INSTANCE_NAME = "__ENV_ATMOSPHERE",
}

local AtmosphereController = {}
AtmosphereController.__index = AtmosphereController

local function getAtmosphereInstance(): Atmosphere
    local atmosphere = Lighting:FindFirstChild(Constants.ATMOSPHERE_INSTANCE_NAME)
    if not atmosphere then
        atmosphere = Instance.new("Atmosphere")
        applyProperties(atmosphere, Constants.DEFAULT_PROPERTIES)
        atmosphere.Parent = Lighting
    end

    return atmosphere
end

function AtmosphereController.new()
    local self = setmetatable({}, AtmosphereController)

    self.instance = getAtmosphereInstance()
    self._originalState = self:get()
    self._goalState = self:get()
    self.motor = Flipper.SingleMotor.new(0)
    self.motor:onStep(function(alpha)
        applyProperties(self.instance, {
            Color = lerpCIELUV(self._originalState.Color, self._goalState.Color, alpha),
            Decay = lerpCIELUV(self._originalState.Decay, self._goalState.Decay, alpha),
            Density = lerp(self._originalState.Density, self._goalState.Density, alpha),
            Glare = lerp(self._originalState.Glare, self._goalState.Glare, alpha),
            Haze = lerp(self._originalState.Haze, self._goalState.Haze, alpha),
            Offset = lerp(self._originalState.Offset, self._goalState.Offset, alpha),
        })
    end)

    return self
end

function AtmosphereController:get()
    return {
        Color = self.instance.Color,
        Decay = self.instance.Decay,
        Density = self.instance.Density,
        Glare = self.instance.Glare,
        Haze = self.instance.Haze,
        Offset = self.instance.Offset,
    }
end

function AtmosphereController:set(state: Types.AtmosphereState, springConfig: Types.SpringConfig)
    self._originalState = self:get()
    self._goalState = state

    self.motor:setGoal(Flipper.Instant.new(0))
    if self.motor:getValue() ~= 0 then
        local onCompleteConnection = nil
        onCompleteConnection = self.motor:onComplete(function()
            onCompleteConnection:disconnect()
            onCompleteConnection = nil
            self.motor:setGoal(Flipper.Spring.new(1, springConfig))
        end)
    else
        self.motor:setGoal(Flipper.Spring.new(1, springConfig))
    end
end

function AtmosphereController:reset(springConfig: Types.SpringConfig)
    self:set(Constants.DEFAULT_PROPERTIES:: Types.AtmosphereState, springConfig)
end

return AtmosphereController