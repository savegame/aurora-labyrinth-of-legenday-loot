local ObjectGroupDef = class()
local Array = require("utils.classes.array")
function ObjectGroupDef:initialize(data)
    self.floors = data.floors
    self.width = data.width
    self.height = data.height
    self.prefab = data.prefab
    self.args = Array:Convert(data.args)
end

function ObjectGroupDef:evaluateExpandedDimensions(rng)
    return Utils.evaluate(self.width, rng) + 2, Utils.evaluate(self.height, rng) + 2
end

function ObjectGroupDef:evaluateArgs(rng)
    local evaluated = Array:new()
    for arg in self.args() do
        evaluated:push(Utils.evaluate(arg, rng))
    end

    return evaluated:expand()
end

return ObjectGroupDef

