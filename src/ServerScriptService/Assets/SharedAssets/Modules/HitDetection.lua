local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local localPlayer = Players.LocalPlayer

local HitDetection = {}

function HitDetection:boxInFrontOf(cframe: CFrame, length: number, width: number, height: number): {[number]: Humanoid}
    local overlapParams = OverlapParams.new()
    overlapParams.FilterType = Enum.RaycastFilterType.Include
    overlapParams.FilterDescendantsInstances = CollectionService:GetTagged("BYZANTIUM_CHARACTER")

    local partBoundsInBox = workspace:GetPartBoundsInBox(cframe + cframe.LookVector * (length / 2), Vector3.new(width, height, length))
    local humanoidsInBox = {}
    for _, part in partBoundsInBox do
        local targetCharacter = part:FindFirstAncestorOfClass("Model")
        if not targetCharacter then
            continue
        end

        local targetPlayer = Players:GetPlayerFromCharacter(targetCharacter)
        if not targetPlayer then
            continue
        end

        local targetHumanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
        if not targetHumanoid then
            continue
        end

        if targetPlayer ~= localPlayer and targetHumanoid.Health > 0 and not table.find(humanoidsInBox, targetHumanoid) then
            table.insert(humanoidsInBox, targetHumanoid)
        end
    end

    return humanoidsInBox
end

return HitDetection