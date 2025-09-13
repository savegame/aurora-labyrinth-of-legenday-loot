local ButtonSimpleText = class("elements.button")
local DrawText = require("draw.text")
local COLORS = require("draw.colors")
local FONTS = require("draw.fonts")
local DEFAULT_FONT = FONTS.MEDIUM
function ButtonSimpleText:initialize(width, height, text, font)
    ButtonSimpleText:super(self, "initialize", width, height)
    self.text = text
    self.font = font or DEFAULT_FONT
    self.wasLastHovered = false
end

function ButtonSimpleText:evaluateText()
    return Utils.evaluate(self.text, self, self.parent)
end

function ButtonSimpleText:draw(serviceViewport, timePassed)
    ButtonSimpleText:super(self, "draw")
    local text = self:evaluateText()
    graphics.wSetFont(self.font)
    graphics.wSetColor(COLORS.NORMAL)
    DrawText.drawStroked(text, (self.rect.width - self.font:getStrokedWidth(text)) / 2, (self.rect.height - self.font:getStrokedHeight()) / 2)
end

return ButtonSimpleText

