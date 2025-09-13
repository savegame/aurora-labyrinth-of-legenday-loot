local WindowAnvil = class("widgets.window_item_list")
local ITEMS = require("definitions.items")
local function isItemSlotEnabled(itemSlot, widget)
    return toBoolean(widget.player.equipment:get(itemSlot.slot))
end

function WindowAnvil:initialize(director, player, anvilEntity, isGolden)
    local slots = ITEMS.SLOTS_WITH_ABILITIES
    if isGolden then
        slots = ITEMS.SLOTS_WITH_LEGENDARIES
    end

    WindowAnvil:super(self, "initialize", director, player.equipment, slots)
    self.itemWindowClass = "window_item_anvil"
    self._director = director
    self.player = player
    self.anvilEntity = anvilEntity
    self.isGolden = isGolden or false
    for itemSlot in self.itemSlots() do
        itemSlot.input.isEnabled = isItemSlotEnabled
        if not self.selectedSlot and itemSlot.input:evaluateIsEnabled() then
            self.selectedSlot = itemSlot
            self:moveElementToTop(itemSlot)
        end

    end

    director:subscribe(Tags.UI_CLEAR, self)
    self:onSelect()
end

function WindowAnvil:receiveMessage(message)
    if message == Tags.UI_CLEAR then
        self:delete()
    end

end

function WindowAnvil:getTitle()
    return "Enchant Equipment"
end

function WindowAnvil:onSelect()
    WindowAnvil:super(self, "onSelect")
    if self.itemWindow then
        self.itemWindow.isGolden = self.isGolden
    end

end

return WindowAnvil

