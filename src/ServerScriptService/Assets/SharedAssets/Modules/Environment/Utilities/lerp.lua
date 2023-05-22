local function lerp(a: number, b: number, alpha: number)
    if not b then
        return a
    end

    return a + (b - a) * alpha
end

return lerp