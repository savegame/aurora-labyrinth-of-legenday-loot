local ButtonArrow = class("elements.button")
local Vector = require("utils.classes.vector")
local DrawCommand = require("utils.love2d.draw_command")
function ButtonArrow:initialize(size, direction)
    ButtonArrow:super(self, "initialize", size, size)
    self.direction = direction
    self.drawCommand = DrawCommand:new("arrow")
    self.drawCommand:setOriginToCenter()
    self.drawCommand.angle = Vector.ORIGIN:angleTo(Vector[direction])
end

function ButtonArrow:draw()
    ButtonArrow:super(self, "draw")
    graphics.wSetColor(WHITE)
    self.drawCommand.position = self.rect:center()
    self.drawCommand:draw()
end

return ButtonArrow

