local CharacterClone = {}
CharacterClone.__index = CharacterClone

function CharacterClone.new(character)
	local self = setmetatable({}, CharacterClone)
	
	self.Character = character
	self.Clone = character:Clone()

	self.Clone:WaitForChild("Humanoid").DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	self.Lookup = self:GetLookup()
	
	return self
end

function CharacterClone:GetLookup()
	local lookup = {}
	local character = self.Character
	for _, item in next, self.Clone:GetChildren() do
		if (item:IsA("BasePart")) then
			item.Anchored = true
			local match = character:FindFirstChild(item.Name)
			lookup[item] = match
		elseif (item:IsA("Accessory")) then
			local match = character:FindFirstChild(item.Name).Handle
			item = item.Handle
			item.Anchored = true
			lookup[item] = match
		elseif (item:IsA("LuaSourceContainer")) then
			item:Destroy()
		end
	end
	return lookup
end

function CharacterClone:Update()
	for fake, real in next, self.Lookup do
		fake.CFrame = real.CFrame
	end
end

return CharacterClone