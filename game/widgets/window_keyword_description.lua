local WindowKeywordDescription = class("widgets.window")
local COLORS = require("draw.colors")
local MEASURES = require("draw.measures")
local FONT = require("draw.fonts").MEDIUM
local WIDTH = MEASURES.WIDTH_ITEM_WINDOW
local function onButtonClose(button, widget)
    widget.director:publish(Tags.UI_CLEAR, true)
end

function WindowKeywordDescription:initialize(director, keyword, alignHeight)
    WindowKeywordDescription:super(self, "initialize", WIDTH, 100)
    self.director = director
    local MARGIN_INTERNAL = MEASURES.MARGIN_INTERNAL + 1
    local currentY = MEASURES.BORDER_WINDOW
    local startingX = MEASURES.BORDER_WINDOW
    local currentY = self:addTitle(keyword.name, false, false, false, COLORS.TEXT_COLOR_PALETTE:get("KEYWORD"))
    self:addButtonClose()
    self.buttonClose.input.onRelease = onButtonClose
    self.buttonClose.input.shortcut = Tags.KEYCODE_CANCEL
    currentY = currentY + MEASURES.MARGIN_INTERNAL + 2
    local textX = startingX + MEASURES.MARGIN_INTERNAL + 1
    local descElement = self:addElement("text_wrapped", textX, currentY, WIDTH - textX * 2, keyword.description, FONT)
    currentY = currentY + descElement.rect.height + MEASURES.MARGIN_INTERNAL + MEASURES.BORDER_WINDOW + 2
    self.window:setHeight(currentY)
    self.alignment = CENTER
    self.alignWidth = -MEASURES.MARGIN_ITEM_WINDOW
    self.alignHeight = alignHeight
end

function WindowKeywordDescription:update(...)
    WindowKeywordDescription:super(self, "update", ...)
    self.alignWidth = self.director:getRightAlignWidth()
end

return WindowKeywordDescription

