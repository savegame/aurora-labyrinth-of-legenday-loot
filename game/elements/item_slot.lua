local ItemSlot = class("elements.list_slot")
local Vector = require("utils.classes.vector")
local COLORS = require("draw.colors")
local TERMS = require("text.terms")
local EMPTY_FORMAT = "(%s)"
function ItemSlot:initialize(width, itemSource, slot)
    ItemSlot:super(self, "initialize", width)
    self._itemSource = itemSource
    self.slot = slot
end

function ItemSlot:getIcon()
    local item = self._itemSource:get(self.slot, false)
    if item then
        return item:getIcon()
    else
        return Vector.UNIT_XY
    end

end

function ItemSlot:getIconStroke()
    local item = self._itemSource:get(self.slot, false)
    if item then
        return item:getStrokeColor()
    else
        return false
    end

end

function ItemSlot:getLabel()
    local item = self._itemSource:get(self.slot, false)
    if item then
        return item:getFullName()
    else
        return EMPTY_FORMAT:format(TERMS.SLOT_NAME[self.slot])
    end

end

function ItemSlot:getLabelColor()
    local item = self._itemSource:get(self.slot, false)
    if item then
        return item.labelColor
    else
        return COLORS.DISABLED.NORMAL
    end

end

return ItemSlot

