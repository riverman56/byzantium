local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local byzantiumRoot = script.Parent.Parent

local Utilities = byzantiumRoot.Utilities
local castFromMouse = require(Utilities.castFromMouse)
local getMass = require(Utilities.getMass)

local replicatedStorageFolder = ReplicatedStorage:WaitForChild("Byzantium")

local Packages = replicatedStorageFolder.Packages
local Ropost = require(Packages.Ropost)

local SharedAssets = replicatedStorageFolder.SharedAssets

local Constants = require(SharedAssets.Constants)

local Content = SharedAssets.Content
local Animations = require(Content.Animations)

local Modules = SharedAssets.Modules
local TopbarPlus = require(Modules.TopbarPlus)

local fakeCharactersFolder = workspace:WaitForChild(Constants.FAKE_CHARACTERS_FOLDER_IDENTIFIER)

local localPlayer = Players.LocalPlayer
local channel = Ropost.channel("Byzantium")

local isFlying = false

local connection = nil

local limbDragForces = {}
local vectorForce = nil
local alignOrientation = nil

local unprojectIcon = TopbarPlus.new()
unprojectIcon:setRight()
unprojectIcon:setLabel("[Q] Leave Astral Dimension")
unprojectIcon:setImage("rbxassetid://13350796392")
unprojectIcon:setEnabled(false)
unprojectIcon:bindToggleKey(Enum.KeyCode.Q)

local RENDER_STEP_IDENTIFIER = string.format("__%d_BYZANTIUM_ASTRAL_PROJECTION", localPlayer.UserId)
local LIMBS_SLOWED_PHYSICS = {
	"Left Arm",
	"Right Arm",
	"Left Leg",
	"Right Leg",
}
local CONFIGURATION = {
	DRAG = 3,
	FORCE = 300,
	DRAG_EXPONENT = 1.4,
	LIMB_DRAG_EXPONENT = 2.4,
	LIMBS_SLOWED_PHYSICS_FACTOR = 0.3,
	GHOST_INTERVAL = 1,
	ALIGN_ORIENTATION_RESPONSIVENESS = 180,
}

local function setProjectionPhysics(enabled: boolean)
	local character = localPlayer.Character
	if not character then
		return
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return
	end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		return
	end

	if enabled then
		if isFlying == true then
			return
		end

		unprojectIcon:setEnabled(true)
		isFlying = true
		vectorForce.Enabled = true
		alignOrientation.Enabled = true
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)
		workspace.Gravity = 0

		-- apply the velocities of the currently playing animations to the
		-- joints for a smoother transition
		local motors = {}
		for _, descendant in character:GetDescendants() do
			if descendant:IsA("Motor6D") then
				table.insert(motors, descendant)
			end
		end
		animator:ApplyJointVelocities(motors)

		for _, animation in animator:GetPlayingAnimationTracks() do
			animation:Stop()
		end

		-- slow down limb physics
		local previousLimbCFrames = {}
		for _, limb in character:GetDescendants() do
			if table.find(LIMBS_SLOWED_PHYSICS, limb.Name) and limb:IsA("BasePart") then
				previousLimbCFrames[limb.Name] = limb.CFrame

				local attachment = Instance.new("Attachment")
				attachment.Parent = limb

				local dragVectorForce = limbDragForces[limb.Name]
				if not dragVectorForce then
					dragVectorForce = Instance.new("VectorForce")
					dragVectorForce.Enabled = false
					dragVectorForce.Force = Vector3.new(0, 0, 0)
					dragVectorForce.RelativeTo = Enum.ActuatorRelativeTo.World
					dragVectorForce.Attachment0 = attachment
					dragVectorForce.Parent = limb

					limbDragForces[limb.Name] = dragVectorForce
				end
			end
		end

		RunService:BindToRenderStep(RENDER_STEP_IDENTIFIER, Enum.RenderPriority.Camera.Value - 1, function()
			for _, limb in character:GetDescendants() do
				if table.find(LIMBS_SLOWED_PHYSICS, limb.Name) and limb:IsA("BasePart") then
					local currentCFrame = limb.CFrame
					limb.CFrame = previousLimbCFrames[limb.Name]:Lerp(currentCFrame, CONFIGURATION.LIMBS_SLOWED_PHYSICS_FACTOR)
					previousLimbCFrames[limb.Name] = limb.CFrame
				end
			end
		end)

		-- constraint & movement math
		connection = RunService.Heartbeat:Connect(function()
			local trueCharacterMass = getMass(character)

			-- align the torso with the camera direction
			local cameraCFrame = workspace.CurrentCamera.CFrame
			alignOrientation.CFrame = cameraCFrame

			-- anti-gravity force
			vectorForce.Force = Vector3.new(0, workspace.Gravity, 0) * trueCharacterMass

			local moveDirection = humanoid.MoveDirection
			if moveDirection.Magnitude > 0 then
				local localizedMoveDirection = rootPart.CFrame:VectorToObjectSpace(moveDirection)

				local influenceUpwards = 0
				local angleToUpwards = math.deg(math.acos(rootPart.CFrame.LookVector:Dot(Vector3.yAxis)))
				if angleToUpwards < 90 then
					-- the character is looking somewhat upwards [0, 1]
					influenceUpwards = 1 - (angleToUpwards / 90)
				else
					-- the character is lookoing somewhat downwards. [-1, 0]
					influenceUpwards = -(angleToUpwards - 90) / 90
				end

				-- apply movement forces
				vectorForce.Force += (moveDirection * CONFIGURATION.FORCE * trueCharacterMass) + Vector3.new(0, influenceUpwards * CONFIGURATION.FORCE * trueCharacterMass * (if localizedMoveDirection.Z > 0 then -1 else 1), 0)
			end

			-- apply a drag force to the moving assembly
			if rootPart.AssemblyLinearVelocity.Magnitude > 0 then
				local dragVector = -rootPart.AssemblyLinearVelocity.Unit
				vectorForce.Force += dragVector * CONFIGURATION.DRAG * trueCharacterMass * (rootPart.AssemblyLinearVelocity.Magnitude ^ CONFIGURATION.DRAG_EXPONENT)
			end

			-- apply a drag force to each limb
			for _, descendant in character:GetDescendants() do
				if descendant:IsA("BasePart") and table.find(LIMBS_SLOWED_PHYSICS, descendant.Name) then
					local dragVectorForce = limbDragForces[descendant.Name]

					if descendant.AssemblyLinearVelocity.Magnitude > 0 then
						local dragVector = -descendant.AssemblyLinearVelocity.Unit
						dragVectorForce.Force = dragVector * CONFIGURATION.DRAG * descendant:GetMass() * (descendant.AssemblyLinearVelocity.Magnitude ^ CONFIGURATION.LIMB_DRAG_EXPONENT)
					end
				end
			end
		end)
	else
		if isFlying == false then
			return
		end

		unprojectIcon:setEnabled(false)
		isFlying = false
		vectorForce.Enabled = false
		alignOrientation.Enabled = false
		humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
		workspace.Gravity = 196.2

		connection:Disconnect()
		connection = nil
		RunService:UnbindFromRenderStep(RENDER_STEP_IDENTIFIER)
	end
end

--[[
	effects that run on the victim's client when a keyframe marker is reached
	in the victim's projection animation
]]
local function onVictimAnimationPlayed(animationTrack: AnimationTrack, fakeCharacter: Model)
	local character = localPlayer.Character
	if not character then
		return
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return
	end

	animationTrack:GetMarkerReachedSignal("project"):Connect(function()
		channel:publish("astralProjectPunch", {
			fakeCharacter = fakeCharacter,
		})

		rootPart.Anchored = false
		rootPart:ApplyImpulseAtPosition(-rootPart.CFrame.LookVector * rootPart.AssemblyMass * 100, rootPart.Position + rootPart.CFrame.LookVector * 2)
		setProjectionPhysics(true)
	end)
end

--[[
	this is nauseous logic that has to be written this specific way to ensure
	that the timing of all effects is consistent across all clients

	the projection animations are played on the server to ensure that they are
	in sync for all clients, and that means that we have to listen for the
	specific animation on the client

	if this client is the victim of this projection, we need to handle effects
	when a specific keyframe marker is reached
]]
fakeCharactersFolder.ChildAdded:Connect(function(fakeCharacter)
	print(string.format("fake character %s added", fakeCharacter.Name))
	-- rudimentary class check just in case something unexpected ends up in the
	-- folder
	if fakeCharacter:IsA("Model") then
		local matchingPlayer = Players:FindFirstChild(fakeCharacter.Name)
		print(string.format("matching player for fake character %s: %s", fakeCharacter.Name, if matchingPlayer then matchingPlayer.Name else "nil"))

		if matchingPlayer == localPlayer then
			print("the matching player is the local player")
			local fakeCharacterHumanoid = fakeCharacter:WaitForChild("Humanoid")
			local fakeCharacterAnimator = fakeCharacterHumanoid:WaitForChild("Animator")

			fakeCharacterAnimator.AnimationPlayed:Connect(function(animationTrack)
				print("animation played on our fake character")
				if animationTrack.Animation.AnimationId == Animations.AstralProjectVictim then
					print("the animation being played is the victim animation. we are being astral projected and are handling the victim's client logic")
					onVictimAnimationPlayed(animationTrack, fakeCharacter)
				end
			end)
			-- we still want to handle in case the animation is already playing
			for _, animationTrack in fakeCharacterAnimator:GetPlayingAnimationTracks() do
				if animationTrack.Animation.AnimationId == Animations.AstralProjectVictim then
					print("the animation being played is the victim animation. we are being astral projected and are handling the victim's client logic")
					onVictimAnimationPlayed(animationTrack, fakeCharacter)
				end
			end
		end
	end
end)

unprojectIcon.toggled:Connect(function()
	if not unprojectIcon.enabled then
		return
	end

	local character = localPlayer.Character
	if not character then
		return
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return
	end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end

	task.spawn(function()
		--humanoid:ApplyDescription(Players:GetHumanoidDescriptionFromUserId(localPlayer.UserId))
	end)

	setProjectionPhysics(false)
	channel:publish("astralProjectStop", {})
end)

local function onLocalCharacterAdded(character: Model)
	local rootPart = character:WaitForChild("HumanoidRootPart")

	alignOrientation = Instance.new("AlignOrientation")
	alignOrientation.Enabled = false
	alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOrientation.MaxTorque = math.huge
	alignOrientation.MaxAngularVelocity = math.huge
	alignOrientation.Responsiveness = CONFIGURATION.ALIGN_ORIENTATION_RESPONSIVENESS
	alignOrientation.Attachment0 = rootPart.RootAttachment
	alignOrientation.Parent = rootPart

	vectorForce = Instance.new("VectorForce")
	vectorForce.Enabled = false
	vectorForce.Force = Vector3.new(0, 0, 0)
	vectorForce.RelativeTo = Enum.ActuatorRelativeTo.World
	vectorForce.Attachment0 = rootPart.RootAttachment
	vectorForce.Parent = rootPart
end

local AstralProjection = {}
AstralProjection.NAME = "AstralProjection"
AstralProjection.KEYCODE = Enum.KeyCode.F

function AstralProjection:nonPrivilegedSetup()
	local character = localPlayer.Character
	if character then
		onLocalCharacterAdded(character)
	end
	localPlayer.CharacterAdded:Connect(onLocalCharacterAdded)
end

function AstralProjection:setup()
end

function AstralProjection:run()
	local character = localPlayer.Character
	if not character then
		localPlayer.CharacterAdded:Wait()
		character = localPlayer.Character
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

	local result = castFromMouse(RaycastParams.new(), 2000, true)
	if not result then
		return
	end

	local targetCharacter = result.Instance:FindFirstAncestorWhichIsA("Model")
	if not targetCharacter then
		return
	end

	local targetPlayer = Players:GetPlayerFromCharacter(targetCharacter)
	if not targetPlayer then
		return
	end

	local targetRootPart = targetCharacter:FindFirstChild("HumanoidRootPart")
	if not targetRootPart then
		return
	end

	local targetHumanoid = targetCharacter:FindFirstChild("Humanoid")
	if not targetHumanoid then
		return
	end

	if targetHumanoid.FloorMaterial == Enum.Material.Air or targetHumanoid.Health == 0 then
		return
	end

	-- this is the initial signal sent immediately upon projection so the
	-- server can handle effects like anchoring the victim's root part
	channel:publish("astralProjectInitial", {
		victim = targetPlayer,
	})

	local targetDestination = targetRootPart.Position + targetRootPart.CFrame.LookVector * 2.6
	humanoid:MoveTo(targetDestination)

	local cframeChangedConnection = nil
	cframeChangedConnection = targetRootPart:GetPropertyChangedSignal("CFrame"):Connect(function()
		local newTargetDestination = targetRootPart.Position + targetRootPart.CFrame.LookVector * 2.6
		humanoid:MoveTo(newTargetDestination)
	end)

	local moveToFinishedConnection = nil
	moveToFinishedConnection = humanoid.MoveToFinished:Connect(function(reached)
		if not reached then
			humanoid:MoveTo(targetDestination)
			return
		end

		moveToFinishedConnection:Disconnect()
		moveToFinishedConnection = nil

		cframeChangedConnection:Disconnect()
		cframeChangedConnection = nil

		rootPart.CFrame = CFrame.lookAt(rootPart.Position, targetRootPart.Position)
		rootPart.Anchored = true

		channel:publish("astralProject", {
			victim = targetPlayer,
		})
	end)
end

return AstralProjection