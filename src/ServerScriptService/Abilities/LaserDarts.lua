local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local byzantiumRoot = script.Parent.Parent

local Utilities = byzantiumRoot.Utilities
local validateWhitelist = require(Utilities.validateWhitelist)

local replicatedStorageFolder = ReplicatedStorage.Byzantium

local SharedAssets = replicatedStorageFolder.SharedAssets
local Constants = require(SharedAssets.Constants)

local Packages = replicatedStorageFolder.Packages
local Ropost = require(Packages.Ropost)

local channel = Ropost.channel("Byzantium")

local LaserDarts = {}

function LaserDarts:setup()
    channel:subscribe("laserDarts", function(data, envelope)
        local player = envelope.player
        local target = data.target

        local isWhitelisted = validateWhitelist(player)
        if not isWhitelisted then
            return
        end

        local character = player.Character
        if not character then
            return
        end

        local targetCharacter = target.Character
        if not targetCharacter then
            return
        end

        local targetHumanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
        if not targetHumanoid then
            return
        end

        if not character:GetAttribute(Constants.EQUIPPED_ATTRIBUTE_IDENTIFIER) then
		    character:SetAttribute(Constants.EQUIPPED_ATTRIBUTE_IDENTIFIER, true)
	    end

        local amountOfDarts = math.random(6, 10)

        task.spawn(function()
            for _ = 1, amountOfDarts do
                task.wait(0.3)
                targetHumanoid.Health -= 20
            end
        end)

        character:SetAttribute(Constants.ACTION_ATTRIBUTE_IDENTIFIER, true)
        task.delay(1.5, function()
            character:SetAttribute(Constants.ACTION_ATTRIBUTE_IDENTIFIER, false)
        end)

        channel:publish("laserDarts", {
            target = target,
            amountOfDarts = amountOfDarts,
        }, Players:GetPlayers())
    end)
end

return LaserDarts