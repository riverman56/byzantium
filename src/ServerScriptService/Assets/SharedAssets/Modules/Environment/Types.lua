export type PropertyValueTable = {[string]: any}
export type PostEffectInstances = {[string]: PostEffect}

export type PPEState = {
    blur: PropertyValueTable?,
    bloom: PropertyValueTable?,
    colorCorrection: PropertyValueTable?,
    depthOfField: PropertyValueTable?,
    sunRays: PropertyValueTable?,
}

export type PPEController = {
    postEffectInstances: PostEffectInstances,
    _originalState: PPEState,
    _goalstate: PPEState,
    motor: {},
}

export type SpringConfig = {
    frequency: number,
    dampingRatio: number,
}

export type AtmosphereState = {
    Color: Color3?,
    Decay: Color3?,
    Density: number?,
    Glare: number?,
    Haze: number?,
    Offet: number?,
}

export type CameraState = {
    FieldOfView: number?,
}

return {}