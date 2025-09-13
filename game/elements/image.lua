local Image = class("elements.element")
local Vector = require("utils.classes.vector")
local DrawCommand = require("utils.love2d.draw_command")
local MEASURES = require("draw.measures")
function Image:initialize(filename)
    Image:super(self, "initialize")
    self._drawCommand = DrawCommand:new(filename)
    self._drawCommand:setRectFromImage()
    self.alignment = UP_LEFT
end

function Image:draw()
    graphics.wSetColor(WHITE)
    self._drawCommand.position = -MEASURES.ALIGNMENT[self.alignment] * Vector:new(self._drawCommand.rect:getDimensions())
    self._drawCommand:draw()
end

return Image

