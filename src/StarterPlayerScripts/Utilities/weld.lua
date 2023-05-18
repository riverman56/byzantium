local function weld(part0: BasePart, part1: BasePart)
    local weldInstance = Instance.new("Weld")
    weldInstance.Name = part1.Name
    weldInstance.Part0 = part0
    weldInstance.Part1 = part1
    weldInstance.C0 = part1.CFrame:ToObjectSpace(part0.CFrame)
    weldInstance.Parent = part1
    return weldInstance
end

return weld