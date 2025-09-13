local Divider = class("elements.element")
local COLOR = require("draw.colors").WINDOW_BORDER
function Divider:initialize(length, isVertical)
    Divider:super(self, "initialize")
    self.length = length
    self.isVertical = toBoolean(isVertical)
end

function Divider:draw()
    graphics.wSetColor(COLOR)
    if self.isVertical then
        graphics.wRectangle(0, 0, 1, self.length)
    else
        graphics.wRectangle(0, 0, self.length, 1)
    end

end

return Divider

