local TitleChoice = class("elements.element")
local Common = require("common")
local FONT = require("draw.fonts").MEDIUM_BOLD_2
local COLORS = require("draw.colors")
local MEASURES = require("draw.measures")
local DrawText = require("draw.text")
local Rect = require("utils.classes.rect")
local INPUT_MARGIN = floor(MEASURES.TITLE_CHOICE_GAP / 2)
local SELECTOR_GAP = 8
local selector = require("utils.love2d.draw_command"):new("selector")
selector.scale = 2
local COLOR_SELECTED = COLORS.TEXT_COLOR_PALETTE:get("STAT_LINE")
local function onHover(button, parent)
    if not button.wasLastHovered then
        Common.playSFX("CURSOR")
        parent:dehover()
        parent:selectButton(button)
        button.wasLastHovered = true
    end

end

function TitleChoice:initialize(text)
    TitleChoice:super(self, "initialize")
    self.text = text
    self.rect = Rect:new(-INPUT_MARGIN, -INPUT_MARGIN, FONT:getWidth(text) + INPUT_MARGIN * 2 + selector:getWidth() + SELECTOR_GAP, FONT.height + INPUT_MARGIN * 2)
    self:createInput()
    self.isActivated = false
    self.wasLastHovered = false
    self.disabledHide = false
    self.input.onHover = onHover
end

function TitleChoice:getTextHeight()
    return FONT.height
end

function TitleChoice:evaluateIsActivated()
    return Utils.evaluate(self.isActivated, self, self.parent)
end

function TitleChoice:draw(_, timePassed)
    local isActivated = self:evaluateIsActivated()
        if not self.input:evaluateIsEnabled() then
        if self.disabledHide then
            return 
        end

        graphics.wSetColor(COLORS.DISABLED.NORMAL)
    elseif isActivated then
        graphics.wSetColor(COLOR_SELECTED)
    else
        graphics.wSetColor(COLORS.NORMAL)
    end

    graphics.wSetFont(FONT)
    DrawText.draw(self.text, selector:getWidth() * selector.scale + SELECTOR_GAP, 0)
    if isActivated then
        selector:draw(0, (FONT.height - selector:getHeight() * selector.scale) / 2 + math.sin(math.tau * timePassed))
    end

end

return TitleChoice

