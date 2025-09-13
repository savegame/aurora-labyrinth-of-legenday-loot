local BlackHole = class("effects.effect")
local Vector = require("utils.classes.vector")
local MEASURES = require("draw.measures")
function BlackHole:initialize()
    BlackHole:super(self, "initialize")
    self.position = false
    self.opacity = 1
    self.radius = 0
end

local CENTER = Vector:new(MEASURES.TILE_SIZE / 2, MEASURES.TILE_SIZE / 2)
function BlackHole:draw(managerCoordinates)
    local position = managerCoordinates:gridToScreen(self.position) + CENTER
    graphics.wSetColor(0, 0, 0, self.opacity)
    graphics.wCircle(position, self.radius)
end

return BlackHole

