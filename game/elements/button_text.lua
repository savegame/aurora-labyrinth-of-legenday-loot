local ButtonText = class("elements.button")
local TextSpecial = require("draw.text_special")
local COLORS = require("draw.colors")
local FONTS = require("draw.fonts")
local DEFAULT_FONT = FONTS.MEDIUM
local COLOR_SELECTED = COLORS.TEXT_COLOR_PALETTE:get("STAT_LINE")
local selector = require("utils.love2d.draw_command"):new("selector")
local SELECTOR_MARGIN = 2
local SELECTOR_GAP = 6
function ButtonText:initialize(width, height, text, font)
    ButtonText:super(self, "initialize", width, height)
    self.text = TextSpecial:new(font or DEFAULT_FONT, text, true)
    self.disabledHide = false
    self.wasLastHovered = false
end

function ButtonText:draw(serviceViewport, timePassed)
    if not self.input:evaluateIsEnabled() then
        if self.disabledHide then
            return 
        end

    end

    local textX
    local textHeight = self.text.font:getStrokedHeight()
    ButtonText:super(self, "draw")
    textX = (self.rect.width - self.text:getTotalWidth()) / 2
    self.text:draw(serviceViewport, textX, (self.rect.height - textHeight) / 2)
end

function ButtonText:setText(text)
    self.text:setText(text)
end

return ButtonText

