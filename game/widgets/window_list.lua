local WindowList = class("widgets.window")
local Array = require("utils.classes.array")
local MEASURES = require("draw.measures")
local Common = require("common")
local function isItemSlotActivated(itemSlot, widget)
    return itemSlot == widget.selectedSlot
end

local function onControl(control, widget)
    if not widget.selectedSlot then
        return 
    end

    local index = widget.itemSlots:indexOf(widget.selectedSlot)
    for i = 1, widget.itemSlots:size() do
        index = modAdd(index, control.movementValue, widget.itemSlots:size())
        if widget.itemSlots[index].input:evaluateIsEnabled() then
            widget.itemSlots[index].input:trigger()
            break
        end

    end

end

local function onItemSlotTrigger(itemSlot, widget)
    if widget.selectedSlot ~= itemSlot then
        Common.playSFX("CURSOR")
        widget.selectedSlot = itemSlot
        widget:moveElementToTop(itemSlot)
        widget:onSelect()
    end

end

function WindowList:initialize(width, itemCount)
    WindowList:super(self, "initialize", width)
    local MARGIN_INTERNAL = MEASURES.MARGIN_INTERNAL + 1
    local startingX = MEASURES.BORDER_WINDOW
    local currentY = MEASURES.BORDER_WINDOW
    local title = self:getTitle()
    if title then
        currentY = self:addTitle(title, self:getIcon())
    end

    self.itemCount = itemCount
    self.itemSlots = Array:new()
    self.selectedSlot = false
    for i = 1, itemCount do
        local itemSlot = self:createItemSlot(i, startingX - 1, currentY - 1, width - (startingX - 1) * 2)
        currentY = currentY + itemSlot.rect.height - 1
        itemSlot.isActivated = isItemSlotActivated
        itemSlot.input.onTrigger = onItemSlotTrigger
        self.itemSlots:push(itemSlot)
    end

    self.window.rect.height = currentY + MEASURES.BORDER_WINDOW - 1
    self:addHiddenControl(Tags.KEYCODE_UP, onControl, -1)
    self:addHiddenControl(Tags.KEYCODE_DOWN, onControl, 1)
end

function WindowList:createItemSlot(index, x, y, width)
end

function WindowList:getTitle()
    return "List"
end

function WindowList:getIcon()
    return false
end

function WindowList:onSelect()
end

return WindowList

