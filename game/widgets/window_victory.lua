local WindowVictory = class("widgets.window")
local Common = require("common")
local MEASURES = require("draw.measures")
local FONTS = require("draw.fonts")
local COLORS = require("draw.colors")
local ScreenTitle = require("screens.title")
local LORE_OTHER = require("text.lore_other")
local LORE_AMULET_VICTORY = require("text.lore_amulet_victory")
local WIDTH = MEASURES.WIDTH_OPTIONS
local FONT_TITLE = FONTS.MEDIUM_BOLD
local FONT_TEXT = FONTS.MEDIUM
local function onNextButton(button, widget)
    widget._director:screenTransition(ScreenTitle)
end

local UNLOCKED_FORMAT = " {FORCE_NEWLINE} {FORCE_NEWLINE} {B:STAT_LINE}Unlocked %s difficulty."
function WindowVictory:initialize(director, unlockedDifficulty)
    WindowVictory:super(self, "initialize", WIDTH)
    self._director = director
    local MARGIN_INTERNAL = MEASURES.MARGIN_INTERNAL + 1
    local currentY = MEASURES.BORDER_WINDOW
    local startingX = MEASURES.BORDER_WINDOW
    local title = self:addElement("text", WIDTH / 2, currentY + MARGIN_INTERNAL, "Victory!", FONT_TITLE)
    title.alignment = UP
    title.color = COLORS.TEXT_COLOR_PALETTE:get("UPGRADED")
    local textX = startingX + MARGIN_INTERNAL + 1
    self.textIndex = 1
    currentY = currentY + FONT_TITLE.height + MARGIN_INTERNAL * 2
    self:addElement("divider", startingX, currentY, WIDTH - MEASURES.BORDER_WINDOW * 2)
    currentY = currentY + 1 + MARGIN_INTERNAL
    local player = director:getPlayer()
    local amulet = player.equipment:get(Tags.SLOT_AMULET)
    local fullText = LORE_OTHER.OUTRO:format(amulet.name, LORE_AMULET_VICTORY[amulet.definition.saveKey])
    if unlockedDifficulty then
        fullText = fullText .. UNLOCKED_FORMAT:format(Common.getDifficultyText(unlockedDifficulty))
    end

    self.mainText = self:addElement("text_wrapped", textX, currentY, WIDTH - textX * 2, fullText, FONT_TEXT)
    currentY = currentY + self.mainText.rect.height + MEASURES.MARGIN_INTERNAL
    self.lowerDivider = self:addElement("divider", MEASURES.BORDER_WINDOW, currentY, self.window.rect.width - MEASURES.BORDER_WINDOW * 2)
    currentY = currentY + 1 + MEASURES.MARGIN_INTERNAL
    local buttonText = "Return"
    if not PortSettings.IS_MOBILE then
        buttonText = buttonText .. " (" .. Common.getKeyName(Tags.KEYCODE_CONFIRM) .. ")"
    end

    self.nextButton = self:addElement("button_simple_text", MEASURES.BORDER_WINDOW + MEASURES.MARGIN_INTERNAL, currentY, self.window.rect.width - (MEASURES.BORDER_WINDOW + MEASURES.MARGIN_INTERNAL) * 2, MEASURES.HEIGHT_BUTTON, buttonText, FONT)
    self.nextButton.isActivated = true
    self.nextButton.input.shortcut = Tags.KEYCODE_CONFIRM
    self.nextButton.input.onRelease = onNextButton
    currentY = currentY + self.nextButton.rect.height + MEASURES.MARGIN_INTERNAL
    self.window.rect.height = currentY + MEASURES.BORDER_WINDOW
    self.alignment = CENTER
    self.alignWidth = self.window.rect.width
    self.alignHeight = self.window.rect.height
end

return WindowVictory

