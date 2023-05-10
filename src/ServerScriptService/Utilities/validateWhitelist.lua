local Whitelist = require(script.Parent.Parent.Whitelist)

local KICK_MESSAGE = "unauthorized"

local function validateWhitelist(player: Player): boolean
    local isWhitelisted = false
    if table.find(Whitelist, player.UserId) then
        isWhitelisted = true
    end

    if not isWhitelisted then
        player:Kick(KICK_MESSAGE)
    end

    return isWhitelisted
end

return validateWhitelist