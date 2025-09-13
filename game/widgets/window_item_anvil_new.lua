local WindowItemAnvilNew = class("widgets.window_item")
local Common = require("common")
local MEASURES = require("draw.measures")
local TERMS = require("text.terms")
local Global = require("global")
local BUTTON_WIDTH = floor((MEASURES.WIDTH_ITEM_WINDOW - MEASURES.MARGIN_INTERNAL * 3 - MEASURES.BORDER_WINDOW * 2) / 2)
local function onMainButton(button, widget)
    local widget = widget.parent
    if widget.director:canDoTurn() then
        Common.playSFX("EQUIP")
        widget.director:logAction("Equip Enchanted: " .. tostring(widget.item:getSlot()))
        Global:get(Tags.GLOBAL_PROFILE):discoverItem(widget.item)
        widget.director:decorateSaveRatios(function(player)
            player.equipment:equip(widget.item, widget.item:getSlot())
        end)
        widget.director:publish(Tags.UI_CLEAR)
    end

end

local function onRejectButton(button, widget)
    widget.parent.buttonClose.input:trigger()
end

function WindowItemAnvilNew:createExtraElements(currentY, textX)
    self.buttonGroup = self:addChildWidget("button_group", 0, currentY)
    local mainButton = self.buttonGroup:add(TERMS.UI.ANVIL_NEW_ACCEPT, textX - 1, 0, BUTTON_WIDTH, onMainButton)
    self.buttonGroup:add(TERMS.UI.ANVIL_NEW_REJECT, MEASURES.WIDTH_ITEM_WINDOW - (textX - 1) - BUTTON_WIDTH, 0, BUTTON_WIDTH, onRejectButton)
    self.buttonGroup:addControl(Tags.KEYCODE_LEFT, -1)
    self.buttonGroup:addControl(Tags.KEYCODE_RIGHT, 1)
    self.buttonGroup:addControl(Tags.KEYCODE_UP, 0)
    self.buttonGroup:addControl(Tags.KEYCODE_DOWN, 0)
    return currentY + mainButton.rect.height + MEASURES.MARGIN_INTERNAL + MEASURES.BORDER_WINDOW
end

return WindowItemAnvilNew

