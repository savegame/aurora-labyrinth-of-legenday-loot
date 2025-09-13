local WindowItemCompare = class("widgets.window_item")
local MEASURES = require("draw.measures")
local FONT = require("draw.fonts").MEDIUM_BOLD
local COLORS = require("draw.colors")
function WindowItemCompare:createExtraElements(currentY, textX)
    local equippedText = self:addElement("text", MEASURES.WIDTH_ITEM_WINDOW / 2, currentY + 1, "Currently Equipped", FONT, COLORS.TEXT_COLOR_PALETTE:get("NOTE"))
    equippedText.alignment = UP
    return currentY + FONT.height + MEASURES.MARGIN_INTERNAL + 2 + MEASURES.BORDER_WINDOW
end

return WindowItemCompare

