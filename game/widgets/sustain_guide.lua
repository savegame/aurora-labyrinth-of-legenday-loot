local SustainGuide = class("widgets.widget")
local Common = require("common")
local FONTS = require("draw.fonts")
local FONT = FONTS.MEDIUM
local FONT_MOBILE = FONTS.MEDIUM
local MEASURES = require("draw.measures")
local MARGIN = 5
local AbilityIcon = require("elements.ability_icon")
local TEXT_CONTINUE_FORMAT = "Sustain: {B:NUMBER}%s"
local TEXT_CANCEL_FORMAT = "Cancel: {B:NUMBER}%s"
local BUTTON_FORMAT = "Sustain {B:ABILITY_LABEL}%s"
local SLOTS = require("definitions.items").SLOTS_WITH_ABILITIES
local function onConfirmPress(element, widget)
    if widget._director:canDoTurn() then
        widget._director:startTurnWithWait()
    end

end

local function onCancelTrigger(element, widget)
    if widget._director:canDoTurn() then
        local slot = widget._equipment:getSustainedSlot()
        local cancelAction = widget._director:getCancelModeAction(slot)
        widget._director:executePlayerAction(cancelAction)
    end

end

function SustainGuide:initialize(director, equipment)
    SustainGuide:super(self, "initialize")
    self._director = director
    self._equipment = equipment
    self.alignment = DOWN
    self.anotherVisible = false
    local height = FONT.height * 2 + MARGIN * 3 + 2
    self.window = self:addElement("window", -50, -height / 2, 100, height)
    self.window.hasBorder = false
    self.abilityName = ""
    self.textContinue = self:addElement("text_special", 0, -height / 2 + MARGIN, "", FONT)
    self.textContinue.alignment = UP
    self.textCancel = self:addElement("text_special", 0, height / 2 - MARGIN, "", FONT)
    self.textCancel.alignment = DOWN
    if PortSettings.IS_MOBILE then
        self:setPosition(0, MEASURES.MARGIN_SCREEN + height / 2 + 2)
    else
        self:setPosition(0, MEASURES.MARGIN_SCREEN * 2 + AbilityIcon:GetSize() + height / 2 + 2)
    end

    self.isVisible = function(self)
        if self.anotherVisible then
            return false
        end

        local equipment = self._equipment
        local sustainedSlot = equipment:getSustainedSlot()
        return sustainedSlot and equipment:get(sustainedSlot) and not equipment:isSustainAutocast()
    end
    local buttonY = -MEASURES.HEIGHT_BUTTON + self.window.rect.height / 2
    local BUTTON_WIDTH = 90
    self.buttonSustain = self:addElement("button_text", -BUTTON_WIDTH - MEASURES.MARGIN_INTERNAL / 2, buttonY, BUTTON_WIDTH, MEASURES.HEIGHT_BUTTON, "Sustain", FONT_MOBILE)
    self.buttonCancel = self:addElement("button_text", MEASURES.MARGIN_INTERNAL / 2, buttonY, BUTTON_WIDTH, MEASURES.HEIGHT_BUTTON, "Cancel", FONT_MOBILE)
    self.buttonSustain.input.shortcut = Tags.KEYCODE_CONFIRM
    self.buttonSustain.input.onPress = onConfirmPress
    self.buttonCancel.input.onTrigger = onCancelTrigger
    if PortSettings.IS_MOBILE then
        self.window.isVisible = false
        self.textContinue.isVisible = false
        self.textCancel.isVisible = false
    else
        self.buttonSustain.isHidden = true
        self.buttonCancel.isVisible = false
    end

    director:subscribe(Tags.UI_ABILITY_NOTIFY, self)
    director:subscribe(Tags.UI_CLEAR, self)
end

local function getTextContinue(element)
    local equipment = element.parent._equipment
    local sustainedSlot = equipment:getSustainedSlot()
    local abilityName = equipment:getAbility(sustainedSlot).name
    return TEXT_CONTINUE_FORMAT:format(abilityName, Common.getKeyName(Tags.KEYCODE_CONFIRM))
end

function SustainGuide:update(dt)
    if self:evaluateIsVisible() then
        local equipment = self._equipment
        local sustainedSlot = equipment:getSustainedSlot()
        local abilityName = equipment:getAbility(sustainedSlot).name
        if abilityName ~= self.abilityName then
            self.abilityName = abilityName
            self.textContinue:setText(TEXT_CONTINUE_FORMAT:format(Common.getKeyName(Tags.KEYCODE_CONFIRM)))
            local width = self.textContinue:getWidth() + (MARGIN + 1) * 2
            self.window.rect.width = width
            self.window:setX(-width / 2)
            local key = Tags["KEYCODE_ABILITY_" .. SLOTS:indexOf(sustainedSlot)]
            self.textCancel:setText(TEXT_CANCEL_FORMAT:format(Common.getKeyName(key)))
        end

    end

end

function SustainGuide:receiveMessage(message, isVisibleOrIsFinal)
        if message == Tags.UI_ABILITY_NOTIFY then
        self.anotherVisible = isVisibleOrIsFinal
    elseif message == Tags.UI_CLEAR then
        self.anotherVisible = not isVisibleOrIsFinal
    end

end

return SustainGuide

