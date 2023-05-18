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

local Equip = {}

function Equip:setup()
    channel:subscribe("toggleEquip", function(_, envelope)
        local player = envelope.player

        local isWhitelisted = validateWhitelist(player)
        if not isWhitelisted then
            return
        end

        local character = player.character
        if not character then
            return
        end

        character:SetAttribute(Constants.EQUIPPED_ATTRIBUTE_IDENTIFIER, not character:GetAttribute(Constants.EQUIPPED_ATTRIBUTE_IDENTIFIER))
    end)
end

return Equip