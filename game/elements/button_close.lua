local ButtonClose = class("elements.button")
local Common = require("common")
local COLORS = require("draw.colors")
local FONTS = require("draw.fonts")
local FONT = FONTS.SMALL
local SHORTCUT_FONT = FONTS.MEDIUM
local MEASURES = require("draw.measures")
ButtonClose.SIZE = MEASURES.ITEM_SIZE
if PortSettings.IS_MOBILE then
    ButtonClose.SIZE = MEASURES.WINDOW_ITEM_MARGIN * 2 + MEASURES.ITEM_SIZE + MEASURES.BORDER_WINDOW * 2 + 2
    FONT = FONTS.LARGE
end

local DrawText = require("draw.text")
function ButtonClose:initialize()
    ButtonClose:super(self, "initialize", ButtonClose.SIZE, ButtonClose.SIZE)
    self.rect.x = -ButtonClose.SIZE
    self.input.triggerSound = "CANCEL"
    self.clip = self.clip - 1
    self.margin = (ButtonClose.SIZE - FONT:getStrokedHeight()) / 2
    if PortSettings.IS_MOBILE then
    end

end

function ButtonClose:getColorSource()
    return COLORS.CLOSE
end

local function getText()
    return "X"
end

function ButtonClose:draw()
    ButtonClose:super(self, "draw")
    graphics.wSetColor(COLORS.STROKE)
    graphics.wRectangle(-2, 1, 1, 1)
    graphics.wSetColor(COLORS.NORMAL)
    graphics.wSetFont(FONT)
    local text = getText()
    DrawText.drawStroked(text, self.rect.x + self.margin, self.margin)
    if not PortSettings.IS_MOBILE and self.input.state == Tags.INPUT_HOVERED then
        text = Common.getKeyName(self.input.shortcut)
        local width = SHORTCUT_FONT:getWidth(text)
        graphics.wSetFont(SHORTCUT_FONT)
        graphics.wSetColor(COLORS.NORMAL)
        DrawText.draw(text, self.rect.x - width - MEASURES.MARGIN_BUTTON, (self.rect.height - SHORTCUT_FONT.height) / 2)
    end

end

return ButtonClose

