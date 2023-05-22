local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedStorageFolder = ReplicatedStorage:WaitForChild("Byzantium")

local Packages = replicatedStorageFolder.Packages
local Flipper = require(Packages.Flipper)

local Utilities = script.Parent.Utilities
local applyProperties = require(Utilities.applyProperties)
local lerp = require(Utilities.lerp)

local Types = require(script.Parent.Types)

local Constants = {
    DEFAULT_PROPERTIES = {
        FieldOfView = workspace.CurrentCamera.FieldOfView,
    },
}

local CameraController = {}
CameraController.__index = CameraController

function CameraController.new()
    local self = setmetatable({}, CameraController)
    
    self.instance = workspace.CurrentCamera
    self._originalState = self:get()
    self._goalState = self:get()
    self.motor = Flipper.SingleMotor.new(0)
    self.motor:onStep(function(alpha)
        applyProperties(self.instance, {
            FieldOfView = lerp(self._originalState.FieldOfView, self._goalState.FieldOfView, alpha),
        })
    end)

    return self
end

function CameraController:get()
    return {
        FieldOfView = self.instance.FieldOfView,
    }
end

function CameraController:set(state: Types.AtmosphereState, springConfig: Types.SpringConfig)
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

function CameraController:reset(springConfig: Types.SpringConfig)
    local goalState = Constants.DEFAULT_PROPERTIES
    self:set(goalState, springConfig)
end

return CameraController