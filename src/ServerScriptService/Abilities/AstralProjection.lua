local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local byzantiumRoot = script.Parent.Parent

local Utilities = byzantiumRoot.Utilities
local validateWhitelist = require(Utilities.validateWhitelist)

local replicatedStorageFolder = ReplicatedStorage.Byzantium

local SharedAssets = replicatedStorageFolder.SharedAssets

local Constants = require(SharedAssets.Constants)

local SharedUtilities = SharedAssets.Utilities
local playSound = require(SharedUtilities.playSound)
local getFakeProjectionCharacter = require(SharedUtilities.getFakeProjectionCharacter)

local Content = SharedAssets.Content
local Sounds = require(Content.Sounds)
local Animations = require(Content.Animations)

local Shards = Content.Shards
local Spikes = Content.Spikes
local Dots = Content.Dots
local Flames = Content.Flames

local Modules = SharedAssets.Modules
local Ragdoll = require(Modules.Ragdoll)

local Packages = replicatedStorageFolder.Packages
local Ropost = require(Packages.Ropost)

local fakeCharactersFolder = workspace:FindFirstChild(Constants.FAKE_CHARACTERS_FOLDER_IDENTIFIER)

local channel = Ropost.channel("Byzantium")

local CONFIGURATION = {
	PROJECTION_GHOST_TRANSPARENCY = 0,
	PROJECTION_GHOST_MATERIAL = Enum.Material.ForceField,
	PROJECTION_GHOST_BODY_COLOR = Color3.fromRGB(111, 100, 255),
}

local function addProjectionParticles(basePart: BasePart)
	local shardsClone = Shards:Clone()
	shardsClone.Parent = basePart

	local spikesClone = Spikes:Clone()
	spikesClone.Parent = basePart

	local dotsClone = Dots:Clone()
	dotsClone.Parent = basePart

	local flamesClone = Flames:Clone()
	flamesClone.Parent = basePart
end

local function processDescendant(descendant: any)
	if descendant:IsA("Decal") or (descendant:IsA("Accessory") and not (descendant.AccessoryType == Enum.AccessoryType.Hat or descendant.AccessoryType == Enum.AccessoryType.Hair)) or descendant:IsA("Shirt") or descendant:IsA("Pants") or descendant:IsA("LuaSourceContainer") then
		descendant:Destroy()
	elseif descendant:IsA("BasePart") then
		descendant.CanCollide = false

		if descendant.Name ~= "HumanoidRootPart" then
			addProjectionParticles(descendant)

			descendant.CastShadow = false
			descendant.Transparency = CONFIGURATION.PROJECTION_GHOST_TRANSPARENCY
			descendant.Color = CONFIGURATION.PROJECTION_GHOST_BODY_COLOR
			descendant.Material = CONFIGURATION.PROJECTION_GHOST_MATERIAL
		end
	elseif descendant:IsA("BodyColors") then
		descendant.HeadColor3 = CONFIGURATION.PROJECTION_GHOST_BODY_COLOR
		descendant.LeftArmColor3 = CONFIGURATION.PROJECTION_GHOST_BODY_COLOR
		descendant.LeftLegColor3 = CONFIGURATION.PROJECTION_GHOST_BODY_COLOR
		descendant.RightArmColor3 = CONFIGURATION.PROJECTION_GHOST_BODY_COLOR
		descendant.RightLegColor3 = CONFIGURATION.PROJECTION_GHOST_BODY_COLOR
		descendant.TorsoColor3 = CONFIGURATION.PROJECTION_GHOST_BODY_COLOR
	end
end

local function setCharacterVisibility(character: Model, isVisible: boolean)
	if isVisible then
		for _, descendant in character:GetDescendants() do
			if descendant:IsA("BasePart") or descendant:IsA("Decal") then
				local originalTransparency = descendant:GetAttribute("__ORIGINAL_TRANSPARENCY")
				if originalTransparency then
					descendant:SetAttribute("__ORIGINAL_TRANSPARENCY", nil)
					descendant.Transparency = originalTransparency
				end
			elseif descendant:IsA("ParticleEmitter") then
				local wasEnabled = descendant:GetAttribute("__WAS_ENABLED")
				if wasEnabled then
					descendant:SetAttribute("__WAS_ENABLED", nil)
					descendant.Enabled = true
				end
			end
		end
	else
		for _, descendant in character:GetDescendants() do
			if descendant:IsA("BasePart") or descendant:IsA("Decal") then
				if descendant.Transparency ~= 1 then
					descendant:SetAttribute("__ORIGINAL_TRANSPARENCY", descendant.Transparency)
					descendant.Transparency = 1
				end
			elseif descendant:IsA("ParticleEmitter") then
				if descendant.Enabled then
					descendant:SetAttribute("__WAS_ENABLED", true)
					descendant:Clear()
					descendant.Enabled = false
				end
			end
		end
	end
end

local function setCollisionGroup(model: Model, collisionGroup: string)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.CollisionGroup = collisionGroup
		end
	end
end

local function createFakeCharacter(player: Player): Model?
	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local appliedDescription = humanoid:GetAppliedDescription()
	local fakeCharacter = Players:CreateHumanoidModelFromDescription(appliedDescription, Enum.HumanoidRigType.R6)

	local fakeRootPart = fakeCharacter:FindFirstChild("HumanoidRootPart")
	if not fakeRootPart then
		return
	end

	local fakeHumanoid = fakeCharacter:FindFirstChildOfClass("Humanoid")
	if not fakeHumanoid then
		return
	end

	setCollisionGroup(fakeCharacter, Constants.BYZANTIUM_CHARACTERS_COLLISION_GROUP_IDENTIFIER)
	fakeCharacter:SetAttribute("Mass", fakeRootPart.AssemblyMass)

	fakeHumanoid.DisplayName = player.DisplayName
	fakeHumanoid.MaxHealth = math.huge
	fakeHumanoid.Health = math.huge

	fakeCharacter.Name = player.Name
	fakeCharacter.Parent = fakeCharactersFolder

	Ragdoll:setup(fakeCharacter)

	return fakeCharacter
end

-- privileged endpoint
channel:subscribe("astralProjectInitial", function(data, envelope)
	local player = envelope.player

	local isWhitelisted = validateWhitelist(player)
    if not isWhitelisted then
        return
    end

	local character = player.Character
	if not character then
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

	local existingFakeCharacter = fakeCharactersFolder:FindFirstChild(victim.Name)
	if existingFakeCharacter then
		existingFakeCharacter:Destroy()
	end

	victimCharacter:SetAttribute(Constants.ASTRAL_PROJECTION.PROJECTED_ATTRIBUTE_IDENTIFIER, true)
	character:SetAttribute(Constants.ASTRAL_PROJECTION.PROJECTING_ATTRIBUTE_IDENTIFIER, true)
	character:SetAttribute(Constants.ACTION_ATTRIBUTE_IDENTIFIER, true)

	victimRootPart.Anchored = true

	local fakeCharacter = createFakeCharacter(victim)
	if not fakeCharacter then
		return
	end

	local fakeRootPart = fakeCharacter:FindFirstChild("HumanoidRootPart")
	if not fakeRootPart then
		return
	end

	-- store the character up in the sky until we need it
	fakeRootPart.Anchored = true
	fakeRootPart.CFrame = CFrame.new(0, 10000, 0)
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
	
	if not character:GetAttribute(Constants.EQUIPPED_ATTRIBUTE_IDENTIFIER) then
		character:SetAttribute(Constants.EQUIPPED_ATTRIBUTE_IDENTIFIER, true)
	end

	channel:publish("astralProjectInitialVictim", {}, { victim })

	victimHumanoid:UnequipTools()
	for _, animationTrack in victimAnimator:GetPlayingAnimationTracks() do
		animationTrack:Stop()
	end

	-- obtain a reference to the fake character that we initially created
	local fakeCharacter = getFakeProjectionCharacter(victim)

	local fakeRootPart = fakeCharacter:FindFirstChild("HumanoidRootPart")
	local fakeTorso = fakeCharacter:FindFirstChild("Torso")
	local fakeHumanoid = fakeCharacter:FindFirstChildOfClass("Humanoid")
	local fakeAnimator = fakeHumanoid:FindFirstChildOfClass("Animator")

	playSound(Sounds.AstralProject, fakeRootPart, 7)

	--replace the victim's character with the fake one
	fakeRootPart.CFrame = victimRootPart.CFrame
	setCharacterVisibility(victimCharacter, false)

	local victimAnimationInstance = Instance.new("Animation")
	victimAnimationInstance.AnimationId = Animations.AstralProjectVictim
	local victimAnimation = fakeAnimator:LoadAnimation(victimAnimationInstance)

	local userAnimationInstance = Instance.new("Animation")
	userAnimationInstance.AnimationId = Animations.AstralProjectUser
	local userAnimation = animator:LoadAnimation(userAnimationInstance)

	victimAnimation:GetMarkerReachedSignal("project"):Connect(function()
		local fakeCharacterMass = fakeCharacter:GetAttribute("Mass")

    	-- players cannot interact with the projection ghost
		setCollisionGroup(victimCharacter, Constants.BYZANTIUM_CHARACTERS_COLLISION_GROUP_IDENTIFIER)

		victimRootPart.Anchored = false
		fakeRootPart.Anchored = false

		Ragdoll:setRagdoll(fakeCharacter, true)
		Ragdoll:setRagdoll(victimCharacter, true)

		-- apply this small impulse so the character will fall to the floor when
		-- they ragdoll
		fakeRootPart:SetNetworkOwner(nil)
    	fakeRootPart:ApplyImpulseAtPosition(-fakeTorso.CFrame.LookVector * fakeCharacterMass * 50, (fakeTorso.CFrame + fakeTorso.CFrame.LookVector * 2).Position)

		for _, descendant in victimCharacter:GetDescendants() do
			processDescendant(descendant)
		end

		fakeHumanoid.MaxHealth = math.huge
		fakeHumanoid.Health = math.huge

		victimHumanoid.MaxHealth = math.huge
		victimHumanoid.Health = math.huge

		local fakeForcefield = Instance.new("ForceField")
		fakeForcefield.Visible = false
		fakeForcefield.Parent = victimCharacter

		channel:publish("project", {
			victim = victim,
		}, Players:GetPlayers())
	end)
	
	victimAnimation:Play()
	userAnimation:Play()

	userAnimation.Stopped:Connect(function()
		character:SetAttribute(Constants.ACTION_ATTRIBUTE_IDENTIFIER, false)
		character:SetAttribute(Constants.ASTRAL_PROJECTION.PROJECTING_ATTRIBUTE_IDENTIFIER, false)
	end)
end)

channel:subscribe("selfProject", function(_, envelope)
	local player = envelope.player

	local isWhitelisted = validateWhitelist(player)
    if not isWhitelisted then
        return
    end

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

	local fakeCharacter = createFakeCharacter(player)
	if not fakeCharacter then
		return
	end

	local fakeRootPart = fakeCharacter:FindFirstChild("HumanoidRootPart")
	if not fakeRootPart then
		return
	end

	local fakeHumanoid = fakeCharacter:FindFirstChildOfClass("Humanoid")
	if not fakeHumanoid then
		return
	end

	if not character:GetAttribute(Constants.EQUIPPED_ATTRIBUTE_IDENTIFIER) then
		character:SetAttribute(Constants.EQUIPPED_ATTRIBUTE_IDENTIFIER, true)
	end

	character:SetAttribute(Constants.ACTION_ATTRIBUTE_IDENTIFIER, true)
    task.delay(1.5, function()
         character:SetAttribute(Constants.ACTION_ATTRIBUTE_IDENTIFIER, false)
    end)

	channel:publish("project", {
		victim = player,
	}, Players:GetPlayers())

	channel:publish("astralProjectInitialVictim", {}, { player })

	playSound(Sounds.SelfProject, fakeRootPart, 7)

    -- players cannot interact with the projection ghost
	setCollisionGroup(character, Constants.BYZANTIUM_CHARACTERS_COLLISION_GROUP_IDENTIFIER)

	humanoid:UnequipTools()
	for _, animationTrack in animator:GetPlayingAnimationTracks() do
		animationTrack:Stop()
	end

	fakeRootPart.CFrame = rootPart.CFrame
	fakeRootPart.Anchored = false

	local fakeCharacterMass = fakeCharacter:GetAttribute("Mass")

	Ragdoll:setRagdoll(fakeCharacter, true)

	-- apply this small impulse so the character will fall to the floor when
	-- they ragdoll
    fakeRootPart:ApplyImpulseAtPosition(-fakeRootPart.CFrame.LookVector * fakeCharacterMass * 5, (fakeRootPart.CFrame + fakeRootPart.CFrame.LookVector * 2).Position)

    Ragdoll:setRagdoll(character, true)

	for _, descendant in character:GetDescendants() do
		processDescendant(descendant)
	end

	fakeHumanoid.MaxHealth = math.huge
	fakeHumanoid.Health = math.huge

	humanoid.MaxHealth = math.huge
	humanoid.Health = math.huge

	local fakeForcefield = Instance.new("ForceField")
	fakeForcefield.Visible = false
	fakeForcefield.Parent = character

	channel:publish("selfProject", {}, { player })
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

	channel:publish("unproject", {
		target = player,
		origin = rootPart.Position,
		destination = fakeRootPart.Position,
	}, Players:GetPlayers())

	task.delay(5, function()
		fakeCharacter:Destroy()
	end)
end)

-- if the player leaves or respawns while projected, clean up their fake
-- character
local function onPlayerAdded(player: Player)
	player.CharacterRemoving:Connect(function(character)
		if character:GetAttribute(Constants.ASTRAL_PROJECTION.PROJECTED_ATTRIBUTE_IDENTIFIER) then
			local fakeCharacter = getFakeProjectionCharacter(player)
			if fakeCharacter then
				fakeCharacter:Destroy()
			end
		end
	end)
end

local AstralProjection = {}

function AstralProjection:setup()
	Players.PlayerAdded:Connect(onPlayerAdded)
end

return AstralProjection