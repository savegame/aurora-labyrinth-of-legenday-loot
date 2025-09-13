local WindowItemFinal = class("widgets.window_item")
local MEASURES = require("draw.measures")
local Common = require("common")
local TERMS = require("text.terms")
local BUTTON_WIDTH = floor((MEASURES.WIDTH_ITEM_WINDOW - MEASURES.MARGIN_INTERNAL * 2 - MEASURES.BORDER_WINDOW * 2))
local function onEquipButton(button, widget)
    widget.director:logAction("Equip ground")
    widget.director:startTurnWithEquipFinal(widget._itemEntity)
end

function WindowItemFinal:createExtraElements(currentY, textX)
    local buttonText = "Equip"
    if not PortSettings.IS_MOBILE then
        buttonText = buttonText .. " (" .. Common.getKeyName(Tags.KEYCODE_CONFIRM) .. ")"
    end

    local button = self:addElement("button_text", MEASURES.MARGIN_INTERNAL + MEASURES.BORDER_WINDOW, currentY, BUTTON_WIDTH, MEASURES.HEIGHT_BUTTON, buttonText)
    button.input.triggerSound = "CONFIRM"
    button.isActivated = true
    button.input.shortcut = Tags.KEYCODE_CONFIRM
    button.input.onTrigger = onEquipButton
    self:addHiddenControl(Tags.KEYCODE_LEFT, doNothing)
    self:addHiddenControl(Tags.KEYCODE_RIGHT, doNothing)
    self:addHiddenControl(Tags.KEYCODE_UP, doNothing)
    self:addHiddenControl(Tags.KEYCODE_DOWN, doNothing)
    return currentY + button.rect.height + MEASURES.MARGIN_INTERNAL + MEASURES.BORDER_WINDOW
end

return WindowItemFinal

