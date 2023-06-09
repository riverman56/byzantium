local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local replicatedStorageFolder = ReplicatedStorage:WaitForChild("Byzantium")

local Packages = replicatedStorageFolder.Packages
local Ropost = require(Packages.Ropost)
local Flipper = require(Packages.Flipper)

local SharedAssets = replicatedStorageFolder.SharedAssets

local Modules = SharedAssets.Modules
local Portals = require(Modules.Portals)

local Constants = require(SharedAssets.Constants)
local Configuration = require(SharedAssets.Configuration)

local Content = SharedAssets.Content
local Animations = require(Content.Animations)
local Sounds = require(Content.Sounds)

local SharedUtilities = SharedAssets.Utilities
local debugPrint = require(SharedUtilities.debugPrint)

local Abilities = script.Abilities

local localPlayer = Players.LocalPlayer
local channel = Ropost.channel("Byzantium")

local rng = Random.new()

local cubesFolder = workspace:WaitForChild(Constants.CUBES_FOLDER_IDENTIFIER)

local abilities = {}

local SPRING_CONFIGS = {
    MOVEMENT = {
        frequency = 4,
        dampingRatio = 0.9,
    },
    EQUIP = {
        frequency = 4,
        dampingRatio = 0.6,
    },
}
local TWEEN_INFO = {
    ROTATION = TweenInfo.new(rng:NextNumber(0.5, 0.7), Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    ROTATION_ACTION = TweenInfo.new(1.5, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut),
    HIGHLIGHT = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
    EQUIP = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
    SINK = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
}

local function toggleParticles(instance: Instance, isEnabled: boolean)
    for _, descendant in instance:GetDescendants() do
        if descendant:IsA("ParticleEmitter") then
            if not isEnabled then
                descendant:Clear()
            end
            
            descendant.Enabled = isEnabled
        end
    end
end

local function createCube(player: Player, character: Model)
    debugPrint(string.format("creating Byzantium cube for player \"%s\"", player.Name))
    local rootPart = character:WaitForChild("HumanoidRootPart")

    local offsetAttachment = Instance.new("Attachment")
    offsetAttachment.CFrame = Configuration.CUBE_OFFSET
    offsetAttachment.Name = Constants.CUBE_ATTACHMENT_IDENTIFIER
    offsetAttachment.Parent = rootPart

    local cubeClone = SharedAssets.Cube:Clone()
    cubeClone.Name = player.Name
    cubeClone.Parent = cubesFolder

    local highlightFadeTween = TweenService:Create(cubeClone.Highlight, TWEEN_INFO.HIGHLIGHT, {
        FillTransparency = 0.8,
    })

    local highlightAppearTween = TweenService:Create(cubeClone.Highlight, TWEEN_INFO.HIGHLIGHT, {
        FillTransparency = 0,
    })

    local cubeMotor = Flipper.GroupMotor.new({
        x = offsetAttachment.WorldPosition.X,
        y = offsetAttachment.WorldPosition.Y,
        z = offsetAttachment.WorldPosition.Z,
        equipAlpha = 1,
    })
    
    local lastEquipAlpha = 1
    cubeMotor:onStep(function(values)
        if values.equipAlpha == lastEquipAlpha then
            cubeClone.Position = Vector3.new(values.x, values.y, values.z)
        else
            cubeClone.Position = Vector3.new(offsetAttachment.WorldPosition.X, offsetAttachment.WorldPosition.Y + 25, offsetAttachment.WorldPosition.Z):Lerp(offsetAttachment.WorldPosition, values.equipAlpha)
        end
        lastEquipAlpha = values.equipAlpha
    end)

    cubeClone.Hum:Play()
    cubeClone.ActionOff:Play()

    local isInAction = false

    local lastPosition = offsetAttachment.WorldPosition
    local elapsed = 0
    local goal = rng:NextNumber(2, 4)
    local cubeRotationConnection = RunService.Heartbeat:Connect(function(deltaTime)
        if not character:GetAttribute(Constants.EQUIPPED_ATTRIBUTE_IDENTIFIER) then
            return
        end

        elapsed += deltaTime
        if elapsed >= goal and not isInAction then
            local tween = TweenService:Create(cubeClone, TWEEN_INFO.ROTATION, {
                Orientation = Vector3.new(rng:NextNumber(-520, 520), rng:NextNumber(-520, 520), rng:NextNumber(-520, 520)),
            })
            tween:Play()

            -- randomize the duration of the next rotation and the time to wait
            TWEEN_INFO.ROTATION = TweenInfo.new(rng:NextNumber(0.5, 0.7), Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
            goal = rng:NextNumber(2, 4)
            elapsed = 0
        end

        local newPosition = offsetAttachment.WorldPosition

        -- if the new distance is very large (likely the result of a tp) then
        -- just immediately move the cube
        if (newPosition - lastPosition).Magnitude > 6 then
            cubeMotor:setGoal({
                x = Flipper.Instant.new(newPosition.X),
                y = Flipper.Instant.new(newPosition.Y),
                z = Flipper.Instant.new(newPosition.Z),
            })
        else
            cubeMotor:setGoal({
                x = Flipper.Spring.new(newPosition.X, SPRING_CONFIGS.MOVEMENT),
                y = Flipper.Spring.new(newPosition.Y, SPRING_CONFIGS.MOVEMENT),
                z = Flipper.Spring.new(newPosition.Z, SPRING_CONFIGS.MOVEMENT),
            })
        end

        lastPosition = newPosition
    end)

    local actionAttributeChangedConnection = nil
    actionAttributeChangedConnection = character:GetAttributeChangedSignal(Constants.ACTION_ATTRIBUTE_IDENTIFIER):Connect(function()
        if character:GetAttribute(Constants.ACTION_ATTRIBUTE_IDENTIFIER) then
            local tween = TweenService:Create(cubeClone, TWEEN_INFO.ROTATION_ACTION, {
                Orientation = Vector3.new(rng:NextNumber(-5020, 5020), rng:NextNumber(-5020, 5020), rng:NextNumber(-5020, 5020)),
            })
            tween:Play()
            
            isInAction = true
            cubeClone.Action:Play()
            highlightAppearTween:Play()
        else
            isInAction = false
            cubeClone.ActionOff:Play()
            highlightFadeTween:Play()
        end
    end)

    local equippedAttributeChangedConnection = character:GetAttributeChangedSignal(Constants.EQUIPPED_ATTRIBUTE_IDENTIFIER):Connect(function()
        if character:GetAttribute(Constants.EQUIPPED_ATTRIBUTE_IDENTIFIER) then
            local transparencyTween = TweenService:Create(cubeClone, TWEEN_INFO.EQUIP, {
                Transparency = 0,
            })

            local highlightTransparencyTween = TweenService:Create(cubeClone.Highlight, TWEEN_INFO.EQUIP, {
                FillTransparency = 0.8,
                OutlineTransparency = 0,
            })

            transparencyTween:Play()
            highlightTransparencyTween:Play()

            cubeMotor:setGoal({
                equipAlpha = Flipper.Spring.new(1, SPRING_CONFIGS.EQUIP),
            })

            toggleParticles(cubeClone, true)

            cubeClone.Summon:Play()
        else
            local transparencyTween = TweenService:Create(cubeClone, TWEEN_INFO.EQUIP, {
                Transparency = 1,
            })

            local positionTween = TweenService:Create(cubeClone, TWEEN_INFO.SINK, {
                Position = cubeClone.Position - Vector3.new(0, 2.4, 0),
            })

            local highlightTransparencyTween = TweenService:Create(cubeClone.Highlight, TWEEN_INFO.EQUIP, {
                FillTransparency = 1,
                OutlineTransparency = 1,
            })

            Portals.createDartPortal(CFrame.new(cubeClone.Position - Vector3.new(0, 2, 0)))

            task.delay(0.4, function()
                transparencyTween:Play()
                positionTween:Play()
                highlightTransparencyTween:Play()

                positionTween.Completed:Connect(function()
                    cubeMotor:setGoal({
                        equipAlpha = Flipper.Instant.new(0),
                    })
                end)

                toggleParticles(cubeClone, false)

                cubeClone.Unsummon:Play()
            end)
        end
    end)

    local characterRemovingConnection = nil
    characterRemovingConnection = player.CharacterRemoving:Connect(function()
        characterRemovingConnection:Disconnect()
        characterRemovingConnection = nil
        cubeRotationConnection:Disconnect()
        cubeRotationConnection = nil
        actionAttributeChangedConnection:Disconnect()
        actionAttributeChangedConnection = nil
        equippedAttributeChangedConnection:Disconnect()
        equippedAttributeChangedConnection = nil
        
        cubeClone:Destroy()
    end)
end

local function onRegister(data)
    local target = data.target
    debugPrint(string.format("received Byzantium registration for \"%s\"", target.Name))

    if target == localPlayer then
        for _, ability in abilities do
            debugPrint(string.format("running privileged setup for ability \"%s\"", ability.NAME))
            if ability["setup"] then
                ability:setup()
            end
        end

        UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
            if gameProcessedEvent then
                return
            end

            local ability = abilities[input.KeyCode]
            if ability then
                print(string.format("running ability \"%s\"", ability.NAME))
                ability:run()
            end
        end)
    end

    local targetCharacter = target.Character
    if targetCharacter then
        createCube(target, targetCharacter)
    end

    target.CharacterAdded:Connect(function(newCharacter)
        createCube(target, newCharacter)
    end)
end

channel:subscribe("register", onRegister)

for _, abilityModule in Abilities:GetChildren() do
    local success, ability = pcall(function()
        return require(abilityModule)
    end)
    
    if not success then
        warn(string.format("Error requiring ability module \"%s\": %s", abilityModule.Name, ability))
        continue
    end

    abilities[ability.KEYCODE] = ability

    task.spawn(function()
        if ability["nonPrivilegedSetup"] then
            debugPrint(string.format("running non-privileged setup for ability \"%s\"", abilityModule.Name))
            ability:nonPrivilegedSetup()
        end
    end)
end

local animationsArray = {}
for _, animationId in Animations do
	table.insert(animationsArray, animationId)
end

local soundsArray = {}
for _, soundId in Sounds do
	table.insert(soundsArray, soundId)
end

local now = os.clock()
debugPrint("begin animation preload")
ContentProvider:PreloadAsync(animationsArray)
debugPrint(string.format("end animation preload: %s seconds", tostring(os.clock() - now)))

now = os.clock()
debugPrint("begin sound preload")
ContentProvider:PreloadAsync(soundsArray)
debugPrint(string.format("end sound preload: %s seconds", tostring(os.clock() - now)))