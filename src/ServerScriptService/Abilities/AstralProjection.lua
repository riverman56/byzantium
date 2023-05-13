local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local byzantiumRoot = script.Parent.Parent

local Utilities = byzantiumRoot.Utilities
local validateWhitelist = require(Utilities.validateWhitelist)

local replicatedStorageFolder = ReplicatedStorage.Byzantium

local SharedAssets = replicatedStorageFolder.SharedAssets

local Constants = require(SharedAssets.Constants)

local Content = SharedAssets.Content
local Shards = Content.Shards
local Animations = require(Content.Animations)

local Modules = SharedAssets.Modules
local Ragdoll = require(Modules.Ragdoll)

local Packages = replicatedStorageFolder.Packages
local Ropost = require(Packages.Ropost)

local channel = Ropost.channel("Byzantium")

local fakeCharactersFolder = nil

local function processDescendant(descendant: any, fakeCharacter: Model)
	if descendant:IsA("Decal") or (descendant:IsA("Accessory") and (descendant.AccessoryType ~= Enum.AccessoryType.Hat or descendant.AccessoryType ~= Enum.AccessoryType.Hair)) or descendant:IsA("Shirt") or descendant:IsA("Pants") or descendant:IsA("LuaSourceContainer") then
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

-- privileged endpoint
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

-- non-privileged endpoint
channel:subscribe("astralProjectStop", function(_, envelope)
	local player = envelope.player
	
	local character = player.Character
	if not character then
		return
	end

	Ragdoll:setRagdoll(character, false)
end)

channel:subscribe("astralProjectPunch", function(data, envelope)
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

	-- apply this small impulse so the character will fall to the floor when
	-- they ragdoll
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
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
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

	victimCharacter:SetAttribute(Constants.ASTRAL_PROJECTION.PROJECTED_ATTRIBUTE_IDENTIFIER, true)
	character:SetAttribute(Constants.ASTRAL_PROJECTION.PROJECTING_ATTRIBUTE_IDENTIFIER, true)
	
	victimHumanoid:UnequipTools()
	victim.Backpack:ClearAllChildren()

	local fakeVictimCharacter = Players:CreateHumanoidModelFromDescription(victimHumanoid:GetAppliedDescription(), Enum.HumanoidRigType.R6)
	fakeVictimCharacter.Name = victim.Name

	local fakeVictimRootPart = fakeVictimCharacter:FindFirstChild("HumanoidRootPart")

	local fakeVictimHumanoid = fakeVictimCharacter:FindFirstChildOfClass("Humanoid")
	local fakeVictimAnimator = fakeVictimHumanoid:FindFirstChildOfClass("Animator")

	--replace the victim's character with the fake one
	fakeVictimRootPart.CFrame = victimRootPart.CFrame
	fakeVictimCharacter.Parent = fakeCharactersFolder

	-- make the original character invisible momentarily
	for _, descendant in victimCharacter:GetDescendants() do
		if descendant:IsA("BasePart") or descendant:IsA("Decal") then
			descendant.Transparency = 1
		elseif descendant:IsA("ParticleEmitter") or descendant:IsA("Light") then
			descendant.Enabled = false
		end
	end

	local victimAnimationInstance = Instance.new("Animation")
	victimAnimationInstance.AnimationId = Animations.AstralProjectVictim
	local victimAnimation = fakeVictimAnimator:LoadAnimation(victimAnimationInstance)

	local userAnimationInstance = Instance.new("Animation")
	userAnimationInstance.AnimationId = Animations.AstralProjectUser
	local userAnimation = animator:LoadAnimation(userAnimationInstance)
	
	victimAnimation:Play()
	userAnimation:Play()

	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://13421836099"
	sound.Volume = 7
	sound.Parent = fakeVictimRootPart
	sound:Play()

	userAnimation.Stopped:Connect(function()
		print("user animation ended")
		rootPart.Anchored = false
		character:SetAttribute(Constants.ASTRAL_PROJECTION.PROJECTING_ATTRIBUTE_IDENTIFIER, false)
	end)
end)

channel:subscribe("unproject", function(data, envelope)
	local player = envelope.player

	local character = player.Character
	if not character then
		return
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return
	end

	local fakeCharacter = data.fakeCharacter

	local fakeRootPart = fakeCharacter:FindFirstChild("HumanoidRootPart")
	if not fakeRootPart then
		return
	end

	--character:Destroy()

	channel:publish("unproject", {
		target = player,
		origin = rootPart.Position,
		destination = fakeRootPart.Position,
	}, Players:GetPlayers())

	task.delay(5, function()
		fakeCharacter:Destroy()
	end)
end)

local AstralProjection = {}

function AstralProjection:setup()
	fakeCharactersFolder = Instance.new("Folder")
	fakeCharactersFolder.Name = Constants.FAKE_CHARACTERS_FOLDER_IDENTIFIER
	fakeCharactersFolder.Parent = workspace
end

return AstralProjection