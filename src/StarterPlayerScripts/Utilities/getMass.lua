local function getMass(instance: Instance): number
	local mass = if instance:IsA("BasePart") and not (instance:: BasePart).Massless then (instance:: BasePart):GetMass() else 0

	for _, basePart in instance:GetDescendants() do
		if basePart:IsA("BasePart") and basePart.Massless ~= true then
			mass += basePart.Mass
		end
	end

	return mass
end

return getMass