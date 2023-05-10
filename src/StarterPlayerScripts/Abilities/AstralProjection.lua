local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local byzantiumRoot = script.Parent.Parent

local Utilities = byzantiumRoot.Utilities
local castFromMouse = require(Utilities.castFromMouse)
local getMass = require(Utilities.getMass)

local replicatedStorageFolder = ReplicatedStorage:WaitForChild("Byzantium")

local SharedAssets = replicatedStorageFolder.SharedAssets

local Content = SharedAssets.Content
local Animations = require(Content.Animations)

local Packages = replicatedStorageFolder.Packages
local Ropost = require(Packages.Ropost)

local localPlayer = Players.LocalPlayer

local channel = Ropost.channel("Byzantium")

local isFlying = false

local connection = nil
local projectionConnections = {}

local limbDragForces = {}
local vectorForce = nil
local alignOrientation = nil

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
}

local PROJECTION_GHOST_WHITELISTED_CLASSES = {
	"BasePart",
	"Accoutrement",
	"Attachment",
	"Humanoid",
	"Motor6D",
	"VectorForce",
}

local TWEEN_INFO = {
	PROJECTION_GHOST_TRANSPARENCY = TweenInfo.new(1.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
}

local function processCharacterCloneForGhost(character: Model)
	for _, descendant in character:GetDescendants() do
		print(descendant.Name)

		local isWhitelisted = false
		for _, whitelistedClass in PROJECTION_GHOST_WHITELISTED_CLASSES do
			if descendant:IsA(whitelistedClass) then
				isWhitelisted = true
			end
		end

		if not isWhitelisted then
			descendant:Destroy()
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

		RunService:BindToRenderStep(RENDER_STEP_IDENTIFIER, Enum.RenderPriority.Camera.Value, function()
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

channel:subscribe("astralProjectAnimation", function(data)
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

	local user = data.user
	local victim = data.victim
	local fakeCharacter = data.fakeCharacter

	local victimCharacter = data.victim.Character
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

	local fakeCharacterHumanoid = fakeCharacter:FindFirstChildOfClass("Humanoid")
	if not fakeCharacterHumanoid then
		return
	end

	local fakeCharacterAnimator = fakeCharacterHumanoid:FindFirstChildOfClass("Animator")
	if not fakeCharacterAnimator then
		return
	end

	victimCharacter.Archivable = true
	local projectionGhost = victimCharacter:Clone()

	local projectionGhostRootPart = projectionGhost:FindFirstChild("HumanoidRootPart")
	if not projectionGhostRootPart then
		print("no projection ghost root")
		return
	end

	local projectionCloneVectorForce = Instance.new("VectorForce")
	vectorForce.Enabled = false
	vectorForce.Force = Vector3.new(0, 0, 0)
	vectorForce.RelativeTo = Enum.ActuatorRelativeTo.World
	vectorForce.Attachment0 = projectionGhostRootPart.RootAttachment
	vectorForce.Parent = projectionGhostRootPart

	processCharacterCloneForGhost(projectionGhost)

	local elapsed = 0
	projectionConnections[victim] = RunService.Heartbeat:Connect(function(deltaTime)
		elapsed += deltaTime
		if elapsed >= CONFIGURATION.GHOST_INTERVAL then
			elapsed = 0

			local projectionGhostClone = projectionGhost:Clone()

			local projectionCloneRootPart = projectionGhostClone:FindFirstChild("HumanoidRootPart")
			if not projectionCloneRootPart then
				return
			end

			projectionGhostClone.Parent = workspace

			if rootPart.AssemblyLinearVelocity.Magnitude > 0 then
				local dragVector = -projectionCloneRootPart.AssemblyLinearVelocity.Unit
				projectionCloneVectorForce.Force = dragVector * CONFIGURATION.DRAG * getMass(projectionGhostClone) * (projectionCloneRootPart.AssemblyLinearVelocity.Magnitude ^ CONFIGURATION.DRAG_EXPONENT)
			end

			for _, descendant in projectionGhostClone:GetDescendants() do
				if descendant:isA("BasePart") then
					local transparencyTween = TweenService.new(descendant, TWEEN_INFO.PROJECTION_GHOST_TRANSPARENCY, {
						Transparency = 1
					})

					transparencyTween:Play()
				end
			end

			task.delay(1.3, function()
				projectionGhostClone:Destroy()
			end)
		end
	end)

	if localPlayer == user then
		local animationInstance = Instance.new("Animation")
		animationInstance.AnimationId = Animations.AstralProjectUser
		local animation = animator:LoadAnimation(animationInstance)
		animation:Play()
	end

	if localPlayer == victim then
		local animationInstance = Instance.new("Animation")
		animationInstance.AnimationId = Animations.AstralProjectVictim
		local animation = fakeCharacterAnimator:LoadAnimation(animationInstance)
		animation:Play()

		animation:GetMarkerReachedSignal("project"):Connect(function()
			channel:publish("astralProjectUser", {
				fakeCharacter = fakeCharacter,
			})
			victimRootPart.Anchored = false
			victimRootPart:ApplyImpulseAtPosition(-victimRootPart.CFrame.LookVector * victimRootPart.AssemblyMass * 1000, victimRootPart.Position + victimRootPart.CFrame.LookVector * 2)
			setProjectionPhysics(true)
		end)
	end
end)

local function onLocalCharacterAdded(character: Model)
	local rootPart = character:WaitForChild("HumanoidRootPart")

	alignOrientation = Instance.new("AlignOrientation")
	alignOrientation.Enabled = false
	alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOrientation.MaxTorque = math.huge
	alignOrientation.MaxAngularVelocity = math.huge
	alignOrientation.Responsiveness = 180
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
AstralProjection.KEYCODE = Enum.KeyCode.F

function AstralProjection:setup()
	local character = localPlayer.Character
	if character then
		onLocalCharacterAdded(character)
	end
	localPlayer.CharacterAdded:Connect(onLocalCharacterAdded)
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

	-- if the target is not on the ground, don't proceed
	if targetHumanoid.FloorMaterial == Enum.Material.Air then
		return
	end

	-- this is the initial signal sent immediately upon projection so the
	-- server can handle things like anchoring the victim's root part
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

		channel:publish("astralProject", {
			victim = targetPlayer,
		})
	end)
end

return AstralProjection