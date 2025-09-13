local TextWrapped = class("elements.element")
local Rect = require("utils.classes.rect")
local TextSpecial = require("draw.text_special")
function TextWrapped:initialize(width, text, font, isStroked)
    TextWrapped:super(self, "initialize")
    self._text = TextSpecial:new(font, text, toBoolean(isStroked))
    self._text.width = width
    self.rect = Rect:new(0, 0, width, self._text:getTotalHeight())
    self.offsetX = 0
    self._needRefresh = true
    self._canvas = false
end

function TextWrapped:draw(serviceViewport)
    if self._needRefresh then
        self._canvas = graphics.newCanvas(self.rect.width, ceil(self.rect.height + self._text.font.height / 2))
        graphics.push()
        graphics.origin()
        graphics.setCanvas(self._canvas)
        graphics.clear()
        graphics.setColor(1, 1, 1)
        self._text:draw(serviceViewport, 0, 0)
        graphics.setCanvas()
        graphics.pop()
        self._needRefresh = false
    end

    graphics.wSetColor(WHITE)
    graphics.draw(self._canvas, self.offsetX, 0)
end

function TextWrapped:setText(text)
    self._text:setText(text)
    self.rect.height = self._text:getTotalHeight()
    self._needRefresh = true
end

function TextWrapped:setBaseColor(baseColor)
    self._text.baseColor = baseColor
    self._needRefresh = true
end

function TextWrapped:alignRight()
    self.offsetX = -self._text:getTotalWidth()
end

function TextWrapped:alignCenter()
    self.offsetX = -self._text:getTotalWidth() / 2
end

function TextWrapped:onWindowModeChange()
    self._needRefresh = true
end

return TextWrapped

