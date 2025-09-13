local ElementTextSpecial = class("elements.element")
local Vector = require("utils.classes.vector")
local TextSpecial = require("draw.text_special")
local MEASURES = require("draw.measures")
function ElementTextSpecial:initialize(text, font, isStroked)
    ElementTextSpecial:super(self, "initialize")
    self._text = TextSpecial:new(font, text, toBoolean(isStroked))
    self.alignment = UP_LEFT
end

function ElementTextSpecial:setText(text)
    self._text:setText(text)
end

function ElementTextSpecial:setBaseColor(color)
    self._text.baseColor = color
end

function ElementTextSpecial:getWidth()
    return self._text:getTotalWidth()
end

function ElementTextSpecial:draw(serviceViewport)
    local position = -MEASURES.ALIGNMENT[self.alignment] * Vector:new(self._text:getTotalWidth(), self._text:getFontHeight())
    self._text:draw(serviceViewport, position.x, position.y)
end

return ElementTextSpecial

