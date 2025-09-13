local WindowEquipment = class("widgets.window_item_list")
local CLOSE_MARGIN = 2
local ITEMS = require("definitions.items")
local function isItemSlotEnabled(itemSlot, widget)
    return toBoolean(widget.player.equipment:get(itemSlot.slot))
end

function WindowEquipment:initialize(director, player)
    WindowEquipment:super(self, "initialize", director, player.equipment, ITEMS.SLOTS)
    self.itemWindowClass = "window_item_equipped"
    self.itemWindow = false
    self._director = director
    self.player = player
    for itemSlot in self.itemSlots() do
        itemSlot.input.isEnabled = isItemSlotEnabled
        if not self.selectedSlot and itemSlot.input:evaluateIsEnabled() then
            self.selectedSlot = itemSlot
            self:moveElementToTop(itemSlot)
        end

    end

    director:subscribe(Tags.UI_CLEAR, self)
    director:subscribe(Tags.UI_SHOW_WINDOW_EQUIPMENT, self)
end

function WindowEquipment:selectFirstAvailable()
    for itemSlot in self.itemSlots() do
        if itemSlot.input:evaluateIsEnabled() then
            itemSlot.input:trigger()
            return 
        end

    end

    self.selectedSlot = false
    self:onSelect()
end

function WindowEquipment:receiveMessage(message)
        if message == Tags.UI_CLEAR then
        self.isVisible = false
    elseif message == Tags.UI_SHOW_WINDOW_EQUIPMENT then
        self.isVisible = true
        if not self.selectedSlot then
            self:selectFirstAvailable()
        else
            self:onSelect()
        end

    end

end

function WindowEquipment:getTitle()
    return "Equipment"
end

function WindowEquipment:onSelect()
    WindowEquipment:super(self, "onSelect")
    if self.itemWindow then
        self.itemWindow.alignHeight = self.alignHeight
    end

end

return WindowEquipment

