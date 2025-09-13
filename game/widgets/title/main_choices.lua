local MainChoices = class("widgets.title.main_buttons")
local MEASURES = require("draw.measures")
function MainChoices:initialize(director)
    MainChoices:super(self, "initialize", director)
    self.alignment = DOWN_LEFT
    self:setPosition(MEASURES.MARGIN_TITLE, MEASURES.MARGIN_TITLE)
    if not self.buttons[1].input:evaluateIsEnabled() then
        self.buttons[2].wasLastHovered = true
    else
        self.buttons[1].wasLastHovered = true
    end

    self.skipDisabled = true
end

function MainChoices:createButtonElement(x, y, width, text)
    return self:addElement("title_choice", x, y, text)
end

function MainChoices:nextY(currentY, button, viewport)
    return currentY + MEASURES.TITLE_CHOICE_GAP + button:getTextHeight()
end

return MainChoices

