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

local Teleport = {}

function Teleport:setup()
    channel:subscribe("teleport", function(data, envelope)
        local player = envelope.player

        local isWhitelisted = validateWhitelist(player)
        if not isWhitelisted then
            return
        end

        local character = player.Character
        if not character then
            return
        end

        if not character:GetAttribute(Constants.EQUIPPED_ATTRIBUTE_IDENTIFIER) then
		    character:SetAttribute(Constants.EQUIPPED_ATTRIBUTE_IDENTIFIER, true)
	    end

        character:SetAttribute(Constants.ACTION_ATTRIBUTE_IDENTIFIER, true)
        task.delay(1.5, function()
            character:SetAttribute(Constants.ACTION_ATTRIBUTE_IDENTIFIER, false)
        end)

        channel:publish("teleport", {
            origin = data.origin,
            destination = data.destination,
        }, Players:GetPlayers())
    end)
end

return Teleport