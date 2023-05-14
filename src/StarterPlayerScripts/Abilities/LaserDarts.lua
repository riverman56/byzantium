local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedStorageFolder = ReplicatedStorage:WaitForChild("Byzantium")

local Utilities = script.Parent.Parent.Utilities
local castFromMouse = require(Utilities.castFromMouse)

local SharedAssets = replicatedStorageFolder.SharedAssets

local Modules = SharedAssets.Modules
local Portals = require(Modules.Portals)
local Laser = require(Modules.Laser)
local Shockwave = require(Modules.Shockwave)

local Content = SharedAssets.Content
local Animations = require(Content.Animations)

local Packages = replicatedStorageFolder.Packages
local Ropost = require(Packages.Ropost)

local localPlayer = Players.LocalPlayer

local channel = Ropost.channel("Byzantium")

local rng = Random.new()

local LaserDarts = {}
LaserDarts.NAME = "LaserDarts"
LaserDarts.KEYCODE = Enum.KeyCode.Y

function LaserDarts:nonPrivilegedSetup()
    channel:subscribe("laserDarts", function(data)
        local target = data.target
        
        local targetCharacter = target.character
        if not targetCharacter then
            return
        end

        local targetRootPart = targetCharacter:FindFirstChild("HumanoidRootPart")
        if not targetRootPart then
            return
        end

        local amountOfDarts = math.random(6, 10)

        for _ = 0, amountOfDarts do
            local rootWithRandomDirection = targetRootPart.CFrame * CFrame.fromEulerAnglesXYZ(math.rad(rng:NextNumber(-45, 45)), math.rad(rng:NextNumber(-45, 45)), math.rad(rng:NextNumber(-45, 45)))
            local goalCFrame = rootWithRandomDirection + rootWithRandomDirection.UpVector * rng:NextNumber(10, 50)
            Portals.createDartPortal(goalCFrame)
            task.delay(0.4, function()
                Laser:dart(goalCFrame * CFrame.fromEulerAnglesXYZ(math.rad(-90), 0, 0), Color3.fromRGB(111, 100, 255))
                
                task.delay(0.2, function()
                    local result = workspace:Raycast(goalCFrame.Position, -goalCFrame.UpVector * 500)
                    if result then
                        Shockwave:shockwave(CFrame.new(result.Position))
                    end
                end)
            end)

            task.wait(rng:NextNumber(0.25, 0.4))
        end
    end)
end

function LaserDarts:run()
    local character = localPlayer.character
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

	if targetHumanoid.Health == 0 then
		return
	end

    channel:publish("laserDarts", {
        target = targetPlayer,
    })
end

return LaserDarts