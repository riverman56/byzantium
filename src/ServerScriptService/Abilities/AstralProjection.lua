local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local byzantiumRoot = script.Parent.Parent

local Utilities = byzantiumRoot.Utilities
local validateWhitelist = require(Utilities.validateWhitelist)

local replicatedStorageFolder = ReplicatedStorage.Byzantium

local SharedAssets = replicatedStorageFolder.SharedAssets

local Content = SharedAssets.Content
local Shards = Content.Shards

local Modules = SharedAssets.Modules
local Ragdoll = require(Modules.Ragdoll)

local Packages = replicatedStorageFolder.Packages
local Ropost = require(Packages.Ropost)

local channel = Ropost.channel("Byzantium")

local AstralProjection = {}

local function processDescendant(descendant: any, fakeCharacter: Model)
	if descendant:IsA("Decal") or (descendant:IsA("Accessory") and (descendant.AccessoryType ~= Enum.AccessoryType.Hat or descendant.AccessoryType ~= Enum.AccessoryType.Hair)) or descendant:IsA("Shirt") or descendant:IsA("Pants") then
		descendant:Destroy()
	elseif descendant:IsA("BasePart") then
		descendant.CanCollide = false

		if descendant.Name ~= "HumanoidRootPart" then
			local shardsClone = Shards:Clone()
			shardsClone.Parent = descendant

			descendant.Transparency = 0
			descendant.CastShadow = false
			descendant.Color = Color3.fromRGB(111, 100, 255)
			descendant.Material = Enum.Material.ForceField
		end
	elseif descendant:IsA("Motor6D") then
		local matchingMotorParent = fakeCharacter:FindFirstChild(descendant.Parent.Name)
		if not matchingMotorParent then
			return
		end

		local matchingMotor = matchingMotorParent:FindFirstChild(descendant.Name)
		if not matchingMotor or not matchingMotor:IsA("Motor6D") then
			return
		end

		descendant.Transform = matchingMotor.Transform
	elseif descendant:IsA("BodyColors") then
		descendant.HeadColor3 = Color3.fromRGB(111, 100, 255)
		descendant.LeftArmColor3 = Color3.fromRGB(111, 100, 255)
		descendant.LeftLegColor3 = Color3.fromRGB(111, 100, 255)
		descendant.RightArmColor3 = Color3.fromRGB(111, 100, 255)
		descendant.RightLegColor3 = Color3.fromRGB(111, 100, 255)
		descendant.TorsoColor3 = Color3.fromRGB(111, 100, 255)
	end
end

channel:subscribe("astralProjectInitial", function(data, envelope)
	local player = envelope.player

	local isWhitelisted = validateWhitelist(player)
    if not isWhitelisted then
        return
    end

	local victim = data.victim

	local victimCharacter = victim.Character
	if not victimCharacter then
		return
	end

	local victimRootPart = victimCharacter:FindFirstChild("HumanoidRootPart")
	if not victimRootPart then
		return
	end

	victimRootPart.Anchored = true
end)

channel:subscribe("astralProjectUser", function(data, envelope)
	local victim = envelope.player
	local fakeCharacter = data.fakeCharacter

	local victimCharacter = victim.Character
	if not victimCharacter then
		return
	end

	local victimHumanoid = victimCharacter:FindFirstChildOfClass("Humanoid")
	if not victimHumanoid then
		return
	end

	local victimRootPart = victimCharacter:FindFirstChild("HumanoidRootPart")
	if not victimRootPart then
		return
	end

	local fakeCharacterRootPart = fakeCharacter:FindFirstChild("HumanoidRootPart")
	if not fakeCharacterRootPart then
		return
	end

	local fakeCharacterHumanoid = fakeCharacter:FindFirstChildOfClass("Humanoid")
	if not fakeCharacterHumanoid then
		return
	end

	-- players cannot interact with the fake character
	for _, descendant in fakeCharacter:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.CollisionGroup = "ByzantiumCharacters"
		end
	end

    -- players cannot interact with the projection ghost
	for _, descendant in victimCharacter:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.CollisionGroup = "ByzantiumCharacters"
		end
	end

	fakeCharacterRootPart:SetNetworkOwner(nil)
    fakeCharacterRootPart:ApplyImpulseAtPosition(-fakeCharacterRootPart.CFrame.LookVector * fakeCharacterRootPart.AssemblyMass * 5, fakeCharacterRootPart.Position + fakeCharacterRootPart.CFrame.LookVector * 2)

    Ragdoll:setup(fakeCharacter)
	Ragdoll:setRagdoll(fakeCharacter, true)

	victimRootPart.Anchored = false
	victimRootPart.CFrame = fakeCharacterRootPart.CFrame
    Ragdoll:setRagdoll(victimCharacter, true)

	for _, descendant in victimCharacter:GetDescendants() do
		processDescendant(descendant, fakeCharacter)
	end

	victimCharacter.DescendantAdded:Connect(function(descendant)
		processDescendant(descendant, fakeCharacter)
	end)

	fakeCharacterHumanoid.MaxHealth = math.huge
	fakeCharacterHumanoid.Health = math.huge

	victimHumanoid.MaxHealth = math.huge
	victimHumanoid.Health = math.huge

	local fakeForcefield = Instance.new("ForceField")
	fakeForcefield.Visible = false
	fakeForcefield.Parent = victimCharacter
end)

channel:subscribe("astralProject", function(data, envelope)
	local player = envelope.player

	local character = player.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		return
	end

	local victim = data.victim

	local victimCharacter = victim.Character
	if not victimCharacter then
		return
	end
	local victimRootPart = victimCharacter:FindFirstChild("HumanoidRootPart")
	if not victimRootPart then
		return
	end
	local victimHumanoid = victimCharacter:FindFirstChildOfClass("Humanoid")
	if not victimHumanoid then
		return
	end
	local victimAnimator = victimHumanoid:FindFirstChildOfClass("Animator")
	if not victimAnimator then
		return
	end

	for _, animationTrack in victimAnimator:GetPlayingAnimationTracks() do
		animationTrack:Stop()
	end
	
	victimRootPart.Anchored = true
	victimHumanoid:UnequipTools()
	victim.Backpack:ClearAllChildren()

	local victimClone = Players:CreateHumanoidModelFromDescription(victimHumanoid:GetAppliedDescription(), Enum.HumanoidRigType.R6)
	victimClone.Name = victim.Name

	local victimCloneRootPart = victimClone:FindFirstChild("HumanoidRootPart")

	--replace the victim's character with the fake one
	victimCloneRootPart.CFrame = victimRootPart.CFrame
	victimClone.Parent = workspace

	for _, descendant in victimCharacter:GetDescendants() do
		if descendant:IsA("BasePart") or descendant:IsA("Decal") then
			descendant.Transparency = 1
		elseif descendant:IsA("ParticleEmitter") or descendant:IsA("Light") then
			descendant.Enabled = false
		end
	end

	channel:publish("astralProjectAnimation", {
		user = player,
		victim = victim,
		fakeCharacter = victimClone,
	}, Players:GetPlayers())
end)

function AstralProjection:setup()
end

return AstralProjection