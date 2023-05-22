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
    NAMES = {
        BlurEffect = "__PPE_BLUR",
        BloomEffect = "__PPE_BLOOM",
        ColorCorrectionEffect = "__PPE_COLORCORRECTION",
        DepthOfFieldEffect = "__PPE_DEPTHOFFIELD",
        SunRaysEffect = "__PPE_SUNRAYS",
    },

    DEFAULT_PROPERTIES = {
        BlurEffect = {
            Size = 0,
        },
        BloomEffect = {
            Intensity = 1,
            Size = 24,
            Threshold = 2,
        },
        ColorCorrectionEffect = {
            Brightness = 0,
            Contrast = 0,
            Saturation = 0,
            TintColor = Color3.fromRGB(255, 255, 255),
        },
        DepthOfFieldEffect = {
            FarIntensity = 0,
            FocusDistance = 0,
            InFocusRadius = 0,
            NearIntensity = 0,
        },
        SunRaysEffect = {
            Intensity = 0,
        },
    },
}

local PPEController = {}
PPEController.__index = PPEController

local function createPostEffect(class: "BloomEffect" | "BlurEffect" | "ColorCorrectionEffect" | "DepthOfFieldEffect" | "SunRaysEffect"): PostEffect
    local effect = Instance.new(class)
    effect.Name = Constants.NAMES[class]
    applyProperties(effect, Constants.DEFAULT_PROPERTIES[effect.ClassName])
    effect.Parent = workspace.CurrentCamera
    return effect
end

local function getPPEInstances(): Types.PostEffectInstances
    local camera = workspace.CurrentCamera

    local blur = camera:FindFirstChild(Constants.NAMES.BlurEffect) or createPostEffect("BlurEffect")
    local bloom = camera:FindFirstChild(Constants.NAMES.BloomEffect) or createPostEffect("BloomEffect")
    local colorCorrection = camera:FindFirstChild(Constants.NAMES.ColorCorrectionEffect) or createPostEffect("ColorCorrectionEffect")
    local depthOfField = camera:FindFirstChild(Constants.NAMES.DepthOfFieldEffect) or createPostEffect("DepthOfFieldEffect")
    local sunRays = camera:FindFirstChild(Constants.NAMES.SunRaysEffect) or createPostEffect("SunRaysEffect")

    return {
        blur = blur,
        bloom = bloom,
        colorCorrection = colorCorrection,
        depthOfField = depthOfField,
        sunRays = sunRays,
    }
end

function PPEController.new(): Types.PPEController
    local self = setmetatable({}, PPEController)

    self.postEffectInstances = getPPEInstances()
    self._originalState = self:get()
    self._goalState = self:get()
    self.motor = Flipper.SingleMotor.new(0)
    self.motor:onStep(function(alpha)
        if self._goalState.blur then
            applyProperties(self.postEffectInstances.blur, {
                Size = lerp(self._originalState.blur.Size, self._goalState.blur.Size, alpha),
            })
        end
        if self._goalState.bloom then
            applyProperties(self.postEffectInstances.bloom, {
                Intensity = lerp(self._originalState.bloom.Intensity, self._goalState.bloom.Intensity, alpha),
                Size = lerp(self._originalState.bloom.Size, self._goalState.bloom.Size, alpha),
                Threshold = lerp(self._originalState.bloom.Threshold, self._goalState.bloom.Threshold, alpha),
            })
        end
        if self._goalState.colorCorrection then
            applyProperties(self.postEffectInstances.colorCorrection, {
                Brightness = lerp(self._originalState.colorCorrection.Brightness, self._goalState.colorCorrection.Brightness, alpha),
                Contrast = lerp(self._originalState.colorCorrection.Contrast, self._goalState.colorCorrection.Contrast, alpha),
                Saturation = lerp(self._originalState.colorCorrection.Saturation, self._goalState.colorCorrection.Saturation, alpha),
                TintColor = lerpCIELUV(self._originalState.colorCorrection.TintColor, self._goalState.colorCorrection.TintColor, alpha),
            })
        end
        if self._goalState.depthOfField then
            applyProperties(self.postEffectInstances.depthOfField, {
                FarIntensity = lerp(self._originalState.depthOfField.FarIntensity, self._goalState.depthOfField.FarIntensity, alpha),
                FocusDistance = lerp(self._originalState.depthOfField.FocusDistance, self._goalState.depthOfField.FocusDistance, alpha),
                InFocusRadius = lerp(self._originalState.depthOfField.InFocusRadius, self._goalState.depthOfField.InFocusRadius, alpha),
                NearIntensity = lerp(self._originalState.depthOfField.NearIntensity, self._goalState.depthOfField.NearIntensity, alpha),
            })
        end
        if self._goalState.sunRays then
            applyProperties(self.postEffectInstances.sunRays, {
                Intensity = lerp(self._originalState.sunRays.Intensity, self._goalState.sunRays.Intensity, alpha),
            })
        end
    end)

    return self
end

function PPEController:get(): Types.PPEState
    return {
        blur = {
            Size = self.postEffectInstances.blur.Size,
        },
        bloom = {
            Intensity = self.postEffectInstances.bloom.Intensity,
            Size = self.postEffectInstances.bloom.Size,
            Threshold = self.postEffectInstances.bloom.Threshold,
        },
        colorCorrection = {
            Brightness = self.postEffectInstances.colorCorrection.Brightness,
            Contrast = self.postEffectInstances.colorCorrection.Contrast,
            Saturation = self.postEffectInstances.colorCorrection.Saturation,
            TintColor = self.postEffectInstances.colorCorrection.TintColor,
        },
        depthOfField = {
            FarIntensity = self.postEffectInstances.depthOfField.FarIntensity,
            FocusDistance = self.postEffectInstances.depthOfField.FocusDistance,
            InFocusRadius = self.postEffectInstances.depthOfField.InFocusRadius,
            NearIntensity = self.postEffectInstances.depthOfField.NearIntensity,
        },
        sunRays = {
            Intensity = self.postEffectInstances.sunRays.Intensity,
        },
    }
end

function PPEController:set(state: Types.PPEState, springConfig: Types.SpringConfig)
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

function PPEController:reset(springConfig: Types.SpringConfig)
    local goalState = {
        blur = Constants.DEFAULT_PROPERTIES.BlurEffect,
        bloom = Constants.DEFAULT_PROPERTIES.BloomEffect,
        colorCorrection = Constants.DEFAULT_PROPERTIES.ColorCorrectionEffect,
        depthOfField = Constants.DEFAULT_PROPERTIES.DepthOfFieldEffect,
        sunRays = Constants.DEFAULT_PROPERTIES.SunRaysEffect,
    }

    self:set(goalState, springConfig)
end

return PPEController