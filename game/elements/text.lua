local Text = class("elements.element")
local Vector = require("utils.classes.vector")
local DEFAULT_FONT = require("draw.fonts").MEDIUM
local MEASURES = require("draw.measures")
local COLORS = require("draw.colors")
local DrawText = require("draw.text")
function Text:initialize(text, font, color, isStroked)
    Text:super(self, "initialize")
    self.text = text
    self.font = font or DEFAULT_FONT
    self.color = color or COLORS.NORMAL
    self.alignment = UP_LEFT
    self.isStroked = isStroked or false
end

function Text:evaluateText()
    return Utils.evaluate(self.text, self, self.parent)
end

function Text:draw()
    graphics.wSetFont(self.font)
    local text = self:evaluateText()
    if #text > 0 then
        graphics.wSetColor(Utils.evaluate(self.color, self, self.parent))
        local position = -MEASURES.ALIGNMENT[self.alignment] * Vector:new(self:getDimensions(text))
        if self.isStroked then
            DrawText.drawStroked(text, position:expand())
        else
            DrawText.draw(text, position:expand())
        end

    end

end

function Text:getDimensions(text)
    local height = choose(self.isStroked, self.font:getStrokedHeight(), self.font.height)
    if not text then
        text = self:evaluateText()
    end

    local width
    if self.isStroked then
        width = self.font:getStrokedWidth(text)
    else
        width = self.font:getWidth(text)
    end

    return width, height
end

return Text

