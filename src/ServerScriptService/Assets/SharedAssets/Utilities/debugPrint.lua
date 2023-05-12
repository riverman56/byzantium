local SharedAssets = script.Parent.Parent
local Configuration = require(SharedAssets.Configuration)

local function debugPrint(...)
    if Configuration.DEBUG_PRINT then
        print(...)
    end
end

return debugPrint