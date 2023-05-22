local Types = require(script.Parent.Parent.Types)

local function applyProperties(instance: Instance, properties: Types.PropertyValueTable)
    for property, value in properties do
        instance[property] = value
    end
end

return applyProperties