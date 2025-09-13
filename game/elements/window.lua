local Window = class("elements.element")
local COLORS = require("draw.colors")
local DrawMethods = require("draw.methods")
local Rect = require("utils.classes.rect")
local CLIP = 2
function Window:initialize(width, height)
    Window:super(self, "initialize")
    self.rect = Rect:new(0, 0, width, height)
    self.hasBorder = true
    self.flash = 0
    self.backgroundColor = COLORS.WINDOW_BACKGROUND
end

function Window:setHeight(height)
    self.rect.height = height
end

function Window:draw()
    graphics.wSetColor(self.backgroundColor:blend(COLORS.WINDOW_BORDER, self.flash))
    DrawMethods.fillClippedRect(self.rect, CLIP)
    if self.hasBorder then
        graphics.wSetColor(COLORS.WINDOW_BORDER)
        DrawMethods.lineClippedRect(self.rect:sizeAdjusted(-1), CLIP - 1)
    end

end

return Window

