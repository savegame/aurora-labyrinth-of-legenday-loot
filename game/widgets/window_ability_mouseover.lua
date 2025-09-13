local WindowAbilityMouseover = class("widgets.window_item")
local MEASURES = require("draw.measures")
local COLORS = require("draw.colors")
function WindowAbilityMouseover:initialize(director, item)
    WindowAbilityMouseover:super(self, "initialize", director, item)
    self.alignment = DOWN_LEFT
    self:setPosition(MEASURES.MARGIN_SCREEN, MEASURES.MARGIN_SCREEN)
end

function WindowAbilityMouseover:addTitleBar()
    return MEASURES.BORDER_WINDOW
end

function WindowAbilityMouseover:addStatLines(currentY)
    return currentY - 1
end

function WindowAbilityMouseover:addPassiveDescription(currentY,...)
    if self.item:getSlot() == Tags.SLOT_AMULET then
        return currentY
    else
        return WindowAbilityMouseover:super(self, "addPassiveDescription", currentY, ...)
    end

end

return WindowAbilityMouseover

