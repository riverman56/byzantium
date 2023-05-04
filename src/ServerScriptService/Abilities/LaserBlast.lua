local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedStorageFolder = ReplicatedStorage.Byzantium

local Packages = replicatedStorageFolder.Packages
local Ropost = require(Packages.Ropost)

local channel = Ropost.channel("Byzantium")

local LaserBlast = {}

function LaserBlast:setup()
    channel:subscribe("laserBlast", function(_, envelope)
        local player = envelope.player

        local character = player.Character
        if not character then
            return
        end

        channel:publish("laserBlast", {
            target = character,
        }, Players:GetPlayers())
    end)
end

return LaserBlast