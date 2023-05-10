local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local byzantiumRoot = script.Parent.Parent

local Utilities = byzantiumRoot.Utilities
local validateWhitelist = require(Utilities.validateWhitelist)

local replicatedStorageFolder = ReplicatedStorage.Byzantium

local Packages = replicatedStorageFolder.Packages
local Ropost = require(Packages.Ropost)

local channel = Ropost.channel("Byzantium")

local LaserBlast = {}

function LaserBlast:setup()
    channel:subscribe("laserBlast", function(_, envelope)
        local player = envelope.player

        local isWhitelisted = validateWhitelist(player)
        if not isWhitelisted then
            return
        end

        local character = player.Character
        if not character then
            return
        end

        channel:publish("laserBlast", {
            player = player,
        }, Players:GetPlayers())
    end)
end

return LaserBlast