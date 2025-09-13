local WindowItemGround = class("widgets.window_item")
local MEASURES = require("draw.measures")
local Common = require("common")
local TERMS = require("text.terms")
local BUTTON_WIDTH = floor((MEASURES.WIDTH_ITEM_WINDOW - MEASURES.MARGIN_INTERNAL * 3 - MEASURES.BORDER_WINDOW * 2) / 2)
local function onEquipButton(button, widget)
    widget = widget.parent
    widget.director:logAction("Equip ground")
    widget.director:startTurnWithEquip(widget._itemEntity)
end

local function onSalvageButton(button, widget)
    widget = widget.parent
    widget._itemEntity:delete()
    widget.director:logAction("Salvage ground")
    widget.director:addScrap(widget.item:getSellCost())
    widget.director:flashPlayer()
    widget.director:publish(Tags.UI_CLEAR, true)
    widget.director:publish(Tags.UI_TUTORIAL_CLEAR)
end

local function isSalvageEnabled(button, widget)
    widget = widget.parent
    return widget.director:hasSpaceForScrap(widget.item:getSellCost()) or DebugOptions.MAX_OUT_SCRAP
end

function WindowItemGround:createExtraElements(currentY, textX)
    self.buttonGroup = self:addChildWidget("button_group", 0, currentY)
    local equipButton = self.buttonGroup:add(TERMS.UI.EQUIP, textX - 1, 0, BUTTON_WIDTH, onEquipButton)
    equipButton.input.triggerSound = "EQUIP"
    local salvageButton = self.buttonGroup:add(TERMS.UI.SALVAGE_FORMAT:format(self.item:getSellCost()), MEASURES.WIDTH_ITEM_WINDOW - textX + 1 - BUTTON_WIDTH, 0, BUTTON_WIDTH, onSalvageButton)
    salvageButton.input.isEnabled = isSalvageEnabled
    salvageButton.input.triggerSound = "SALVAGE"
    self.buttonGroup:addControl(Tags.KEYCODE_LEFT, -1)
    self.buttonGroup:addControl(Tags.KEYCODE_RIGHT, 1)
    self.buttonGroup:addControl(Tags.KEYCODE_UP, 0)
    self.buttonGroup:addControl(Tags.KEYCODE_DOWN, 0)
    return currentY + equipButton.rect.height + MEASURES.MARGIN_INTERNAL + MEASURES.BORDER_WINDOW
end

return WindowItemGround

