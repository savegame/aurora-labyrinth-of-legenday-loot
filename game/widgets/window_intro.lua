local WindowIntro = class("widgets.window")
local Vector = require("utils.classes.vector")
local Common = require("common")
local MEASURES = require("draw.measures")
local LORE_OTHER = require("text.lore_other")
local COLORS = require("draw.colors")
local FONT = require("draw.fonts").MEDIUM
local ICON = Vector:new(19, 7)
local AbilityIcon = require("elements.ability_icon")
local GAME_MENU_SIZE = require("elements.button_game_menu").SIZE
local WIDTH = MEASURES.WIDTH_INTRO
local Global = require("global")
local function onDirection(control, widget)
end

local function onButtonClose(button, widget)
    widget.director:publish(Tags.UI_CLEAR, true)
end

local function onButtonNext(button, widget)
    widget.director:publish(Tags.UI_CLEAR, true)
end

function WindowIntro:initialize(director)
    WindowIntro:super(self, "initialize", WIDTH)
    self.director = director
    local currentY = self:addTitle("Your Quest Begins", ICON)
    self.windowTitle.color = COLORS.TEXT_COLOR_PALETTE:get("UPGRADED")
    self:addButtonClose().input.onRelease = onButtonClose
    local textX = MEASURES.BORDER_WINDOW + MEASURES.MARGIN_INTERNAL + 1
    currentY = currentY + MEASURES.MARGIN_INTERNAL
    self.textIndex = 1
    local morgueEntries = Global:get(Tags.GLOBAL_PROFILE).morgueEntries
    local intro = LORE_OTHER.INTRO_INITIAL
    local latest = morgueEntries:maxValue(function(a, b)
                if a.victoryPrize then
            return true
        elseif b.victoryPrize then
            return false
        end

        return a.endTime < b.endTime
    end)
    if (not latest) or latest.victoryPrize then
        intro = intro .. LORE_OTHER.INTRO_FIRST_TIME
    else
        intro = intro .. LORE_OTHER.INTRO_SUBSEQUENT:format(latest.enderName, latest:getOrdinalFloor())
    end

    self.mainText = self:addElement("text_wrapped", textX, currentY, WIDTH - textX * 2, intro, FONT)
    currentY = currentY + self.mainText.rect.height + MEASURES.MARGIN_INTERNAL
    self.lowerDivider = self:addElement("divider", MEASURES.BORDER_WINDOW, currentY, self.window.rect.width - MEASURES.BORDER_WINDOW * 2)
    currentY = currentY + 1 + MEASURES.MARGIN_INTERNAL
    local buttonText = "Close"
    if not PortSettings.IS_MOBILE then
        buttonText = buttonText .. " (" .. Common.getKeyName(Tags.KEYCODE_CONFIRM) .. ")"
    end

    self.nextButton = self:addElement("button_simple_text", MEASURES.BORDER_WINDOW + MEASURES.MARGIN_INTERNAL, currentY, self.window.rect.width - (MEASURES.BORDER_WINDOW + MEASURES.MARGIN_INTERNAL) * 2, MEASURES.HEIGHT_BUTTON, buttonText, FONT)
    self.nextButton.isActivated = true
    self.nextButton.input.shortcut = Tags.KEYCODE_CONFIRM
    self.nextButton.input.onRelease = onButtonNext
    currentY = currentY + self.nextButton.rect.height + MEASURES.MARGIN_INTERNAL
    self.window.rect.height = currentY + MEASURES.BORDER_WINDOW
    self.alignment = CENTER
    self.alignWidth = self.window.rect.width
    if PortSettings.IS_MOBILE then
        self.alignHeight = self.window.rect.height - GAME_MENU_SIZE - MEASURES.MARGIN_SCREEN
    else
        self.alignHeight = self.window.rect.height + AbilityIcon:GetSize() + MEASURES.MARGIN_SCREEN
    end

    self:addHiddenControl(Tags.KEYCODE_UP, onDirection)
    self:addHiddenControl(Tags.KEYCODE_DOWN, onDirection)
    self:addHiddenControl(Tags.KEYCODE_RIGHT, onDirection)
    self:addHiddenControl(Tags.KEYCODE_LEFT, onDirection)
    director:subscribe(Tags.UI_CLEAR, self)
end

function WindowIntro:refreshHeight()
    local currentY = self.mainText.position.y + self.mainText.rect.height + MEASURES.MARGIN_INTERNAL
    self.lowerDivider:setY(currentY)
    currentY = currentY + 1 + MEASURES.MARGIN_INTERNAL
    self.nextButton:setY(currentY)
    currentY = currentY + MEASURES.HEIGHT_BUTTON + MEASURES.MARGIN_INTERNAL
    self.window.rect.height = currentY + MEASURES.BORDER_WINDOW
end

function WindowIntro:receiveMessage(message)
    if message == Tags.UI_CLEAR then
        self:delete()
    end

end

return WindowIntro

