local RunService = game:GetService("RunService")

assert(RunService:IsClient(), "Environment library may only be used on the client")

local PPEController = require(script.PPEController)
local AtmosphereController = require(script.AtmosphereController)
local CameraController = require(script.CameraController)

local Environment = {
    PPEController = PPEController.new(),
    AtmosphereController = AtmosphereController.new(),
    CameraController = CameraController.new(),
}

return Environment