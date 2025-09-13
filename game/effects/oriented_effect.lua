local OrientedEffect = class("effects.effect")
local Vector = require("utils.classes.vector")
local Entity = require("entities.entity")
local MEASURES = require("draw.measures")
function OrientedEffect:initialize()
    OrientedEffect:super(self, "initialize")
    self.position = false
    self.direction = RIGHT
    self.angle = 0
    self.offset = Vector.ORIGIN
end

function OrientedEffect:evaluatePosition()
    local position = self.position
    if not Vector:isInstance(self.position) then
        position = position:getDisplayPosition()
    end

    return position + Vector:new(0.5, 0.5)
end

function OrientedEffect:isVisible()
    if self.position and not Vector:isInstance(self.position) then
        return self.position:isVisible()
    else
        return true
    end

end

return OrientedEffect

