local StarterGui = game:GetService("StarterGui")

local MAX_RETRIES = 30

local function coreCall(method: "SetCore" | "SetCoreGuiEnabled", parameter: Enum.CoreGuiType | string, enabled: boolean)
    local retries = 0

    local function try()
        local success = pcall(function()
            if method == "SetCore" then
                return StarterGui:SetCore(parameter, enabled)
            else
                return StarterGui:SetCoreGuiEnabled(parameter, enabled)
            end
        end)

        if not success then
            if retries < MAX_RETRIES then
                retries += 1
                return try()
            end
        end
    end

    return try()
end

return coreCall