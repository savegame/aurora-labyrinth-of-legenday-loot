local WindowCredits = class("widgets.window")
local Vector = require("utils.classes.vector")
local CREDITS = require("text.credits")
local COLORS = require("draw.colors")
local MEASURES = require("draw.measures")
local ICON = Vector:new(11, 17)
local FONTS = require("draw.fonts")
local FONT_LABEL = FONTS.MEDIUM
local FONT_NAME = FONTS.MEDIUM
local function onButtonClose(button, widget)
    widget.director:publish(Tags.UI_CLEAR)
    widget.director:publish(Tags.UI_TITLE_BACK)
end

local NEXT_LINE = FONT_NAME.height + MEASURES.MARGIN_INTERNAL + 1
function WindowCredits:initialize(director)
    local WIDTH = MEASURES.WIDTH_OPTIONS
    WindowCredits:super(self, "initialize", MEASURES.WIDTH_OPTIONS, MEASURES.WIDTH_OPTIONS)
    self.director = director
    local currentY = self:addTitle("Credits", ICON) - 1
    self:addButtonClose().input.onRelease = onButtonClose
    local textX = MEASURES.BORDER_WINDOW + MEASURES.MARGIN_INTERNAL + 1
    local MARGIN_VERT = textX + NEXT_LINE * 2 / 3
    local MARGIN_BETWEEN = ceil(NEXT_LINE * 2 / 3)
    currentY = currentY + 1 + MARGIN_VERT
    director:subscribe(Tags.UI_CLEAR, self)
    director:subscribe(Tags.UI_TITLE_SHOW_CREDITS, self)
    for entry in CREDITS() do
        local label = self:addElement("text", self.window.rect.width / 2, currentY, entry.label, FONT_LABEL, COLORS.CREDIT_LABEL)
        label.alignment = UP
        currentY = currentY + NEXT_LINE
        local name = self:addElement("text", self.window.rect.width / 2, currentY, entry.name, FONT_NAME, COLORS.NORMAL)
        name.alignment = UP
        if entry.extra then
            currentY = currentY + NEXT_LINE
            local extra = self:addElement("text", self.window.rect.width / 2, currentY, entry.extra, FONT_NAME, COLORS.NORMAL)
            extra.alignment = UP
        end

        currentY = currentY + NEXT_LINE + MARGIN_BETWEEN
    end

    self.alignment = CENTER
    self.alignWidth = WIDTH
    self.window.rect.height = currentY + FONT_NAME.height - NEXT_LINE - MARGIN_BETWEEN + MARGIN_VERT + 2
    self.alignHeight = self.window.rect.height
    self.isVisible = false
end

function WindowCredits:receiveMessage(message)
        if message == Tags.UI_CLEAR then
        self.isVisible = false
    elseif message == Tags.UI_TITLE_SHOW_CREDITS then
        self.isVisible = true
    end

end

return WindowCredits

