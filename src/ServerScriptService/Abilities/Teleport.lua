local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local byzantiumRoot = script.Parent.Parent

local Utilities = byzantiumRoot.Utilities
local validateWhitelist = require(Utilities.validateWhitelist)

local replicatedStorageFolder = ReplicatedStorage.Byzantium

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

        channel:publish("teleport", {
            origin = data.origin,
            destination = data.destination,
        }, Players:GetPlayers())
    end)
end

return Teleport