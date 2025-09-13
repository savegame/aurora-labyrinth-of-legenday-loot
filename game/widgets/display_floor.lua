local DisplayFloor = class("widgets.widget")
local MARGIN_SCREEN = require("draw.measures").MARGIN_SCREEN
local Common = require("common")
local FONT = require("draw.fonts").MEDIUM
local TERMS = require("text.terms")
function DisplayFloor:initialize(currentRun)
    DisplayFloor:super(self, "initialize")
    local text = "Floor: " .. currentRun.currentFloor
        if currentRun.currentFloor == 0 then
        text = "Tutorial"
    elseif currentRun.difficulty ~= Tags.DIFFICULTY_NORMAL then
        text = text .. " - " .. Common.getDifficultyText(currentRun.difficulty)
    end

    self.alignment = UP_LEFT
    self:setPosition(MARGIN_SCREEN, MARGIN_SCREEN)
    local textSpecial = self:addElement("text_special", 0, 0, text, FONT, true)
    self.alignWidth = textSpecial:getWidth()
end

return DisplayFloor

