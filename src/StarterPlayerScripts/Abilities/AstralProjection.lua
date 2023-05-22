local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Chat = game:GetService("Chat")

local byzantiumRoot = script.Parent.Parent

local Utilities = byzantiumRoot.Utilities
local castFromMouse = require(Utilities.castFromMouse)
local getMass = require(Utilities.getMass)
local coreCall = require(Utilities.coreCall)

local replicatedStorageFolder = ReplicatedStorage:WaitForChild("Byzantium")

local Packages = replicatedStorageFolder.Packages
local Flipper = require(Packages.Flipper)
local Ropost = require(Packages.Ropost)

local SharedAssets = replicatedStorageFolder.SharedAssets

local SharedUtilities = SharedAssets.Utilities
local getFakeProjectionCharacter = require(SharedUtilities.getFakeProjectionCharacter)

local Constants = require(SharedAssets.Constants)

local Content = SharedAssets.Content
local ProjectionParticles = Content.ProjectionParticles
local ProjectionOrb = Content.ProjectionOrb
local Animations = require(Content.Animations)

local Modules = SharedAssets.Modules
local Environment = require(Modules.Environment)
local TopbarPlus = require(Modules.TopbarPlus)

local fakeCharactersFolder = workspace:WaitForChild(Constants.FAKE_CHARACTERS_FOLDER_IDENTIFIER)

local localPlayer = Players.LocalPlayer
local channel = Ropost.channel("Byzantium")

local isFlying = false

local connection = nil

local limbDragForces = {}
local vectorForce = nil
local alignOrientation = nil

local postController = Environment.PPEController
local atmosphereController = Environment.AtmosphereController
local cameraController = Environment.CameraController

local CONFIGURATION = {
	DRAG = 3,
	FORCE = 450,

	-- the higher the drag exponent, the faster the part will come to a stop
	DRAG_EXPONENT = 1.4,
	LIMB_DRAG_EXPONENT = 2.4,
	LIMBS_SLOWED_PHYSICS_FACTOR = 0.3,
	GHOST_INTERVAL = 1,
	ALIGN_ORIENTATION_RESPONSIVENESS = 180,

	UNPROJECT_KEYBIND = Enum.KeyCode.Q,

	PPE_STATES = {
		PROJECTED = {
			colorCorrection = {
				Brightness = 0.1,
				Contrast = 0.2,
				Saturation = -0.7,
				TintColor = Color3.fromRGB(149, 135, 255),
			},
			depthOfField = {
				FarIntensity = 1,
				FocusDistance = 50,
				InFocusRadius = 50,
			},
			bloom = {
				Intensity = 4,
			}
		},
	},
	ATMOSPHERE_STATES = {
		PROJECTED = {
			Density = 0.442,
			Color = Color3.fromRGB(179, 163, 255),
			Decay = Color3.fromRGB(151, 155, 252),
			Glare = 3.08,
			Haze = 2.12,
		},
	},
	CAMERA_STATES = {
		PROJECTED = {
			FieldOfView = 120,
		}
	},
}
local TWEEN_INFO = {
	PROJECTION_ORB_POSITION = TweenInfo.new(1.8, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut),
	PROJECTION_ORB_TRANSPARENCY = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
}
local SPRING_CONFIG = {
	PROJECTION_ORB_SCALE = {
		frequency = 1.8,
		dampingRatio = 1,
	},
	PPE = {
		frequency = 1,
		dampingRatio = 1,
	},
	CAMERA1 = {
		frequency = 3.7,
		dampingRatio = 1.5,
	},
	CAMERA2 = {
		frequency = 2,
		dampingRatio = 0.6,
	},
}
local LIMBS_SLOWED_PHYSICS = {
	"Left Arm",
	"Right Arm",
	"Left Leg",
	"Right Leg",
}
local RENDER_STEP_IDENTIFIER = string.format("__%d_BYZANTIUM_ASTRAL_PROJECTION", localPlayer.UserId)

local unprojectIcon = TopbarPlus.new()
unprojectIcon:setRight()
unprojectIcon:setLabel("[Q] Leave Astral Dimension")
unprojectIcon:setImage("rbxassetid://13350796392")
unprojectIcon:setEnabled(false)
unprojectIcon:bindToggleKey(CONFIGURATION.UNPROJECT_KEYBIND)

local function doProjectionParticles(position: Vector3)
	local projectionParticlesClone = ProjectionParticles:Clone()
	projectionParticlesClone.Position = position
	projectionParticlesClone.Parent = workspace
	for _, descendant in projectionParticlesClone:GetDescendants() do
		if descendant:IsA("ParticleEmitter") then
			descendant:Emit(descendant:GetAttribute("EmitCount"))
		end
	end

	task.delay(5, function()
		projectionParticlesClone:Destroy()
	end)
end

-- sets the Transform property of character's motors to that of FakeCharacter's
local function matchMotors(character: Model, fakeCharacter: Model)
	for _, descendant in character:GetDescendants() do
		if descendant:IsA("Motor6D") then
			local matchingMotorParent = fakeCharacter:FindFirstChild(descendant.Parent.Name)
			if not matchingMotorParent then
				return
			end

			local matchingMotor = matchingMotorParent:FindFirstChild(descendant.Name)
			if not matchingMotor or not matchingMotor:IsA("Motor6D") then
				return
			end

			descendant.Transform = matchingMotor.Transform
		end
	end
end

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
		--humanoid:ChangeState(Enum.HumanoidStateType.Physics)

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

			-- apply anti-gravity and drag forces to each limb
			for _, descendant in character:GetDescendants() do
				if descendant:IsA("BasePart") and table.find(LIMBS_SLOWED_PHYSICS, descendant.Name) then
					local dragVectorForce = limbDragForces[descendant.Name]
					dragVectorForce.Force = Vector3.new(0, workspace.Gravity, 0) * descendant.Mass
					
					if descendant.AssemblyLinearVelocity.Magnitude > 0 then
						local dragVector = -descendant.AssemblyLinearVelocity.Unit
						dragVectorForce.Force += dragVector * CONFIGURATION.DRAG * descendant.Mass * (descendant.AssemblyLinearVelocity.Magnitude ^ CONFIGURATION.LIMB_DRAG_EXPONENT)
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
		--humanoid:ChangeState(Enum.HumanoidStateType.Freefall)

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

	local torso = character:FindFirstChild("Torso")
	if not torso then
		return
	end

	local fakeTorso = fakeCharacter:FindFirstChild("Torso")
	if not fakeTorso then
		return
	end

	animationTrack:GetMarkerReachedSignal("project"):Connect(function()
		rootPart.Anchored = false
		rootPart.CFrame = fakeTorso.CFrame
		matchMotors(character, fakeCharacter)
		rootPart:ApplyImpulseAtPosition(-torso.CFrame.LookVector * rootPart.AssemblyMass * 200, (torso.CFrame + torso.CFrame.LookVector * 2).Position)
		setProjectionPhysics(true)
	end)
end

local function onUserAnimationPlayed(animationTrack: AnimationTrack)
	local character = localPlayer.Character
	if not character then
		return
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return
	end

	animationTrack.Ended:Connect(function()
		rootPart.Anchored = false
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
	-- rudimentary class check just in case something unexpected ends up in the
	-- folder
	if fakeCharacter:IsA("Model") then
		local matchingPlayer = Players:FindFirstChild(fakeCharacter.Name)

		if matchingPlayer == localPlayer then
			local fakeCharacterHumanoid = fakeCharacter:WaitForChild("Humanoid")
			local fakeCharacterAnimator = fakeCharacterHumanoid:WaitForChild("Animator")

			fakeCharacterAnimator.AnimationPlayed:Connect(function(animationTrack)
				if animationTrack.Animation.AnimationId == Animations.AstralProjectVictim then
					onVictimAnimationPlayed(animationTrack, fakeCharacter)
				end
			end)
			-- we still want to handle in case the animation is already playing
			for _, animationTrack in fakeCharacterAnimator:GetPlayingAnimationTracks() do
				if animationTrack.Animation.AnimationId == Animations.AstralProjectVictim then
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

	-- if for some reason the fake character no longer exists, create a
	-- fallback that still allows us to leave the astral dimension
	local fakeCharacter = getFakeProjectionCharacter()
	if not fakeCharacter then
		channel:publish("refresh", {
			cframe = rootPart.CFrame,
		})
		return
	end

	channel:publish("unproject", {
		fakeCharacter = fakeCharacter,
	})

	setProjectionPhysics(false)
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

local function onLocalPrivilegedCharacterAdded(character: Model)
	local humanoid = character:WaitForChild("Humanoid")
	local animator = humanoid:WaitForChild("Animator")

	animator.AnimationPlayed:Connect(function(animationTrack)
		if animationTrack.Animation.AnimationId == Animations.AstralProjectUser then
			onUserAnimationPlayed(animationTrack)
		end
	end)
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

	channel:subscribe("project", function(data)
		local victim = data.victim

		local victimCharacter = victim.Character
		if not victimCharacter then
			return
		end

		local victimRootPart = victimCharacter:FindFirstChild("HumanoidRootPart")
		if not victimRootPart then
			return
		end

		postController:set(CONFIGURATION.PPE_STATES.PROJECTED, SPRING_CONFIG.PPE)
		atmosphereController:set(CONFIGURATION.ATMOSPHERE_STATES.PROJECTED, SPRING_CONFIG.PPE)
		cameraController:set(CONFIGURATION.CAMERA_STATES.PROJECTED, SPRING_CONFIG.CAMERA1)
		task.delay(0.5, function()
			cameraController:reset(SPRING_CONFIG.CAMERA2)
		end)

		doProjectionParticles(victimRootPart.Position)

		Chat:SetBubbleChatSettings({
			BackgroundColor3 = Color3.fromRGB(31, 31, 31),
			UserSpecificSettings = {
				[victim.UserId] = {
					BackgroundColor3 = Color3.fromRGB(31, 31, 31),
					TextColor3 = Color3.fromRGB(123, 54, 172),
				},
			},
		})
	end)

	channel:subscribe("unproject", function(data)
		local target = data.target
		local origin = data.origin
		local destination = data.destination

		local targetCharacter = target.Character
		if not targetCharacter then
			return
		end

		Chat:SetBubbleChatSettings({
			UserSpecificSettings = {
				[target.UserId] = {
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					TextColor3 = Color3.fromRGB(0, 0, 0),
				},
			},
		})

		local projectionOrbClone = ProjectionOrb:Clone()
		projectionOrbClone.Position = origin

		local oldSize = projectionOrbClone.Size
		projectionOrbClone.Size = Vector3.new(0, 0, 0)

		projectionOrbClone.Parent = workspace

		projectionOrbClone.Summon:Play()
		projectionOrbClone.Idle:Play()

		projectionOrbClone.Attachment.Pulse:Emit(5)
		projectionOrbClone.Attachment.Burst:Emit(projectionOrbClone.Attachment.Burst:GetAttribute("EmitCount"))

		task.delay(0.15, function()
			targetCharacter:Destroy()
		end)

		local orbTween = TweenService:Create(projectionOrbClone, TWEEN_INFO.PROJECTION_ORB_POSITION, {
			Position = destination,
		})

		local scaleMotor = Flipper.SingleMotor.new(0)
		scaleMotor:onStep(function(alpha)
			projectionOrbClone.Size = Vector3.new(0, 0, 0):Lerp(oldSize, alpha)
		end)

		scaleMotor:setGoal(Flipper.Spring.new(1, SPRING_CONFIG.PROJECTION_ORB_SCALE))

		orbTween:Play()
		orbTween.Completed:Connect(function()
			projectionOrbClone.Attachment.Pulse:Emit(5)
			projectionOrbClone.Attachment.Needles:Emit(projectionOrbClone.Attachment.Needles:GetAttribute("EmitCount"))
			projectionOrbClone.Attachment.Burst:Emit(projectionOrbClone.Attachment.Burst:GetAttribute("EmitCount"))

			for _, descendant in projectionOrbClone:GetDescendants() do
				if descendant:IsA("ParticleEmitter") then
					descendant.Enabled = false
				end
			end

			local transparencyTween = TweenService:Create(projectionOrbClone, TWEEN_INFO.PROJECTION_ORB_TRANSPARENCY, {
				Size = projectionOrbClone.Size * 5,
				Transparency = 1,
			})

			local highlightTween = TweenService:Create(projectionOrbClone.Highlight, TWEEN_INFO.PROJECTION_ORB_TRANSPARENCY, {
				OutlineTransparency = 1,
				FillTransparency = 1,
			})

			transparencyTween:Play()
			highlightTween:Play()
			
			projectionOrbClone.Unsummon:Play()

			task.delay(5, function()
				projectionOrbClone:Destroy()
			end)

			task.delay(0.15, function()
				local fakeCharacter = getFakeProjectionCharacter(target)
				if not fakeCharacter then
					return
				end
				
				fakeCharacter:Destroy()
			end)

			if target == localPlayer then
				channel:publish("refresh", {
					cframe = CFrame.new(destination + Vector3.new(0, 3, 0)),
				})

				coreCall("SetCoreGuiEnabled", Enum.CoreGuiType.Backpack, true)
				coreCall("SetCore", "ResetButtonCallback", true)

				postController:reset(SPRING_CONFIG.PPE)
				atmosphereController:reset(SPRING_CONFIG.PPE)
				cameraController:set(CONFIGURATION.CAMERA_STATES.PROJECTED, SPRING_CONFIG.CAMERA1)
				task.delay(0.2, function()
					cameraController:reset(SPRING_CONFIG.CAMERA2)
				end)
			end
		end)

		if target == localPlayer then
			--selene: allow(incorrect_standard_library_use)
			workspace.CurrentCamera.CameraSubject = projectionOrbClone
		end
	end)

	channel:subscribe("astralProjectInitialVictim", function()
		coreCall("SetCoreGuiEnabled", Enum.CoreGuiType.Backpack, false)
		coreCall("SetCore", "ResetButtonCallback", false)
	end)
end

function AstralProjection:setup()
	local character = localPlayer.Character
	if character then
		onLocalPrivilegedCharacterAdded(character)
	end
	localPlayer.CharacterAdded:Connect(onLocalPrivilegedCharacterAdded)

	channel:subscribe("selfProject", function()
		local currentCharacter = localPlayer.Character
		if not currentCharacter then
			return
		end

		local rootPart = currentCharacter:FindFirstChild("HumanoidRootPart")
		if not rootPart then
			return
		end

		local fakeCharacter = getFakeProjectionCharacter()
		if not fakeCharacter then
			return
		end

		local fakeTorso = fakeCharacter:FindFirstChild("Torso")
		if not fakeTorso then
			return
		end
		
		rootPart.CFrame = fakeTorso.CFrame
		matchMotors(currentCharacter, fakeCharacter)
		rootPart:ApplyImpulseAtPosition(-rootPart.CFrame.LookVector * rootPart.AssemblyMass * 200, (rootPart.CFrame + rootPart.CFrame.LookVector * 2).Position)
		setProjectionPhysics(true)
	end)
end

function AstralProjection:run()
	local character = localPlayer.Character
	if not character then
		localPlayer.CharacterAdded:Wait()
		character = localPlayer.Character
	end

	if character:GetAttribute(Constants.ACTION_ATTRIBUTE_IDENTIFIER) then
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

	-- terminate if the character is currently in the astral dimension or is
	-- projecting someone
	if character:GetAttribute(Constants.ASTRAL_PROJECTION.PROJECTING_ATTRIBUTE_IDENTIFIER) or character:GetAttribute(Constants.ASTRAL_PROJECTION.PROJECTED_ATTRIBUTE_IDENTIFIER) then
		return
	end

	if targetCharacter:GetAttribute(Constants.ASTRAL_PROJECTION.PROJECTED_ATTRIBUTE_IDENTIFIER) or targetCharacter:GetAttribute(Constants.ASTRAL_PROJECTION.PROJECTING_ATTRIBUTE_IDENTIFIER) then
		return
	end

	-- self projection
	if targetPlayer == localPlayer then
		channel:publish("selfProject", {})
		return
	end

	-- this is the initial signal sent immediately upon projection so the
	-- server can handle effects like anchoring the victim's root part
	channel:publish("astralProjectInitial", {
		victim = targetPlayer,
	})

	local targetDestination = targetRootPart.Position + targetRootPart.CFrame.LookVector * 2.4
	humanoid:MoveTo(targetDestination)

	local cframeChangedConnection = nil
	cframeChangedConnection = targetRootPart:GetPropertyChangedSignal("CFrame"):Connect(function()
		local newTargetDestination = targetRootPart.Position + targetRootPart.CFrame.LookVector * 2.4
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