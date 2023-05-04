local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local replicatedStorageFolder = ReplicatedStorage:WaitForChild("Byzantium")

local Packages = replicatedStorageFolder.Packages
local Ropost = require(Packages.Ropost)
local Flipper = require(Packages.Flipper)

local Abilities = script.Abilities

local SharedAssets = replicatedStorageFolder.SharedAssets
local Configuration = require(SharedAssets.Configuration)

local Content = SharedAssets.Content
local Animations = require(Content.Animations)

local channel = Ropost.channel("Byzantium")

local rng = Random.new()

local SPRING_CONFIG = {
    frequency = 4,
    dampingRatio = 0.9,
}
local ROTATION_TWEEN_INFO = TweenInfo.new(rng:NextNumber(0.5, 0.7), Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local function createCube(player: Player, character: Model)
    local rootPart = character:WaitForChild("HumanoidRootPart")

    local offsetAttachment = Instance.new("Attachment")
    offsetAttachment.CFrame = Configuration.CUBE_OFFSET
    offsetAttachment.Name = "BYZANTIUM_CUBE_ATTACHMENT"
    offsetAttachment.Parent = rootPart

    local cubeClone = SharedAssets.Cube:Clone()
    cubeClone.Parent = character
    local cubeMotor = Flipper.GroupMotor.new({
        x = offsetAttachment.WorldPosition.X,
        y = offsetAttachment.WorldPosition.Y,
        z = offsetAttachment.WorldPosition.Z,
    })
    cubeMotor:onStep(function(values)
        cubeClone.Position = Vector3.new(values.x, values.y, values.z)
    end)

    cubeClone.Hum:Play()

    local lastPosition = offsetAttachment.WorldPosition
    local elapsed = 0
    local goal = rng:NextNumber(2, 4)
    local connection = RunService.Heartbeat:Connect(function(deltaTime)
        elapsed += deltaTime
        if elapsed >= goal then
            local tween = TweenService:Create(cubeClone, ROTATION_TWEEN_INFO, {
                Orientation = Vector3.new(rng:NextNumber(-520, 520), rng:NextNumber(-520, 520), rng:NextNumber(-520, 520)),
            })
            tween:Play()

            -- randomize the duration of the next tween and the time to wait
            ROTATION_TWEEN_INFO = TweenInfo.new(rng:NextNumber(0.5, 0.7), Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
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
                x = Flipper.Spring.new(newPosition.X, SPRING_CONFIG),
                y = Flipper.Spring.new(newPosition.Y, SPRING_CONFIG),
                z = Flipper.Spring.new(newPosition.Z, SPRING_CONFIG),
            })
        end
        lastPosition = newPosition
    end)

    player.CharacterRemoving:Connect(function()
        connection:Disconnect()
    end)
end

local function onSubscribe(data)
    local target = data.target

    local targetCharacter = target.Character
    if targetCharacter then
        createCube(target, targetCharacter)
    end

    target.CharacterAdded:Connect(function(newCharacter)
        createCube(target, newCharacter)
    end)
end

channel:subscribe("register", onSubscribe)

local abilities = {}
for _, abilityModule in Abilities:GetChildren() do
    local success, ability = pcall(function()
        return require(abilityModule)
    end)
    
    if not success then
        warn(string.format("Error requiring ability module %s: %s", abilityModule.Name, ability))
        continue
    end

    abilities[ability.KEYCODE] = ability

    task.spawn(function()
        ability:setup()
    end)
end

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then
        return
    end

    local ability = abilities[input.KeyCode]
    if ability then
        ability:run()
    end
end)

local animationsArray = {}
for _, animationId in Animations do
	table.insert(animationsArray, animationId)
end
ContentProvider:PreloadAsync(animationsArray)