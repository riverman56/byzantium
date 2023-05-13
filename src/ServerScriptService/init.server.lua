local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- distribute content to its proper location before referencing anything
local Utilities = script.Utilities
local distribute = require(Utilities.distribute)
distribute()

local Abilities = script.Abilities

local SharedAssets = ReplicatedStorage.Byzantium.SharedAssets

local SharedUtilities = SharedAssets.Utilities
local debugPrint = require(SharedUtilities.debugPrint)

local Modules = SharedAssets.Modules
local Ragdoll = require(Modules.Ragdoll)

local Packages = ReplicatedStorage.Byzantium.Packages
local Ropost = require(Packages.Ropost)

local Whitelist = require(script.Whitelist)

local channel = Ropost.channel("Byzantium")

local playerConnections = {}

local function onCharacterAdded(character: Model)
	Ragdoll:setup(character)
end

local function onPlayerAdded(player: Player)
    local character = player.Character
    if character then
        onCharacterAdded(character)
    end
    
    player.CharacterAdded:Connect(onCharacterAdded)

    playerConnections[player] = {}

    local isWhitelisted = table.find(Whitelist, player.UserId)

    if isWhitelisted then
        debugPrint(string.format("registering Byzantium user \"%s\"", player.Name))
        channel:publish("register", {
            target = player,
        })

        local connection = Players.PlayerAdded:Connect(function(newPlayer)
            channel:publish("register", {
                target = player,
            }, { newPlayer })
        end)
        table.insert(playerConnections[player], connection)
    end
end

local function onPlayerRemoving(player: Player)
    if playerConnections[player] then
        for _, connection in playerConnections[player] do
            connection:Disconnect()
            connection = nil
        end
    end

    playerConnections[player] = nil
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, abilityModule in Abilities:GetChildren() do
    local success, ability = pcall(function()
        return require(abilityModule)
    end)
    
    if not success then
        warn(string.format("Error requiring ability module \"%s\": %s", abilityModule.Name, ability))
        continue
    end

    debugPrint(string.format("running setup on ability \"%s\"", abilityModule.Name))
    ability:setup()
end

channel:subscribe("damage", function(data)
    local humanoidsToDamage = data.humanoidsToDamage
    local damage = data.damage

    for _, humanoid in humanoidsToDamage do
        humanoid.Health -= damage
    end
end)

channel:subscribe("refresh", function(data, envelope)
    local player = envelope.player

    local character = player.Character
    if not character then
        player:LoadCharacter()
        return
    end

    player:LoadCharacter()
    local newCharacter = player.Character
    if not newCharacter then
        player.CharacterAdded:Wait()
        newCharacter = player.Character
    end

    local newRootPart = newCharacter:WaitForChild("HumanoidRootPart")
    newRootPart.CFrame = data.cframe
end)