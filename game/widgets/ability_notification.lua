local AbilityNotification = class("widgets.widget")
local FONT = require("draw.fonts").MEDIUM
local MEASURES = require("draw.measures")
local MARGIN = 5
local AbilityIcon = require("elements.ability_icon")
local TEMPORARY_DURATION = 2.25
local TERMS = require("text.terms")
local function onCancelTrigger(control, widget)
    widget.timeBeforeTempClear = 0
end

local function isCancelVisible(control, widget)
    return toBoolean(widget.temporaryText) and not widget.tempTextFromDirection
end

function AbilityNotification:initialize(director)
    AbilityNotification:super(self, "initialize")
    self._director = director
    self.abilityLabel = false
    self.temporaryText = false
    self.tempTextFromDirection = false
    self.timeBeforeTempClear = math.huge
    self.alignment = DOWN
    local height = FONT.height + MARGIN * 2
    self.window = self:addElement("window", 0, -height / 2, 0, height)
    self.window.hasBorder = false
    self.textElement = self:addElement("text", 0, 0, "", FONT)
    self.textElement.alignment = CENTER
    if PortSettings.IS_MOBILE then
        self:setPosition(0, MEASURES.MARGIN_SCREEN + height / 2 + 2)
    else
        self:setPosition(0, MEASURES.MARGIN_SCREEN * 2 + AbilityIcon:GetSize() + height / 2 + 2)
    end

    self.isVisible = false
    director:subscribe(Tags.UI_ABILITY_SELECTED, self)
    director:subscribe(Tags.UI_ABILITY_DISABLE_TRIGGER, self)
    director:subscribe(Tags.UI_ABILITY_INVALID_DIRECTION, self)
    local cancelControl = self:addElement("hidden_control")
    cancelControl.isVisible = isCancelVisible
    cancelControl.input.shortcut = Tags.KEYCODE_CANCEL
    cancelControl.input.onTrigger = onCancelTrigger
end

function AbilityNotification:receiveMessage(message, abilityOrReason, isSlotActive)
            if message == Tags.UI_ABILITY_SELECTED then
        if abilityOrReason then
            self.abilityLabel = abilityOrReason.name
            if isSlotActive then
                if abilityOrReason:hasTag(Tags.ABILITY_TAG_NON_QUICK_CANCEL) then
                    self.abilityLabel = self.abilityLabel .. ": Cancel"
                else
                    self.abilityLabel = self.abilityLabel .. ": Cancel (Quick)"
                end

            end

        else
            self.abilityLabel = false
        end

        self.temporaryText = false
        self.tempTextFromDirection = false
    elseif message == Tags.UI_ABILITY_DISABLE_TRIGGER then
        self.temporaryText = abilityOrReason
        self.timeBeforeTempClear = TEMPORARY_DURATION
        self.tempTextFromDirection = false
    elseif message == Tags.UI_ABILITY_INVALID_DIRECTION then
        self.temporaryText = abilityOrReason
        self.timeBeforeTempClear = TEMPORARY_DURATION
        self.tempTextFromDirection = true
    end

end

function AbilityNotification:update(dt)
    self.timeBeforeTempClear = self.timeBeforeTempClear - dt
    if self.timeBeforeTempClear <= 0 then
        self.temporaryText = false
        self.tempTextFromDirection = false
    end

    local text = self.temporaryText
    if not text then
        text = self.abilityLabel
    end

        if text then
        if not self.isVisible then
            self.isVisible = true
            self._director:publish(Tags.UI_ABILITY_NOTIFY, true)
        end

        if self.textElement.text ~= text then
            local width = FONT:getWidth(text) + (MARGIN + 1) * 2
            self.window.rect.width = width
            self.window:setX(-width / 2)
            self.textElement.text = text
        end

    elseif self.isVisible then
        self.isVisible = false
        self._director:publish(Tags.UI_ABILITY_NOTIFY, false)
    end

end

return AbilityNotification

