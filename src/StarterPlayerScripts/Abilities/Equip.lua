local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedStorageFolder = ReplicatedStorage:WaitForChild("Byzantium")

local Packages = replicatedStorageFolder.Packages
local Ropost = require(Packages.Ropost)

local localPlayer = Players.LocalPlayer

local channel = Ropost.channel("Byzantium")


local Equip = {}
Equip.NAME = "Equip"
Equip.KEYCODE = Enum.KeyCode.V

function Equip:run()
    local character = localPlayer.character
    if not character then
        return
    end

    channel:publish("toggleEquip", {})
end

return Equip