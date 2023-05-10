local DartPortal = require(script.DartPortal)
local TeleportationPortal = require(script.TeleportationPortal)

local Portals = {
    createDartPortal = DartPortal.new,
    createTeleportationPortal = TeleportationPortal.new,
}

return Portals