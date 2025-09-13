local WindowItemList = class("widgets.window_list")
local Array = require("utils.classes.array")
local MEASURES = require("draw.measures")
local WIDTH = MEASURES.WIDTH_ITEM_WINDOW
local AbilityIcon = require("elements.ability_icon")
local GAME_MENU_SIZE = require("elements.button_game_menu").SIZE
local CLOSE_MARGIN = 2
local function onButtonClose(button, widget)
    widget._director:publish(Tags.UI_CLEAR, true)
    widget._director:publish(Tags.UI_TUTORIAL_CLEAR)
end

function WindowItemList:initialize(director, itemSource, slots)
    self.itemWindow = false
    self._director = director
    self._itemSource = itemSource
    self._slots = slots
    self.itemWindowClass = "window_item"
    WindowItemList:super(self, "initialize", WIDTH, slots:size())
    self.alignment = CENTER
    self.alignWidth = director:getLeftAlignWidth()
    if PortSettings.IS_MOBILE then
        self.alignHeight = self.window.rect.height - GAME_MENU_SIZE - MEASURES.MARGIN_SCREEN
    else
        self.alignHeight = self.window.rect.height + AbilityIcon:GetSize() + MEASURES.MARGIN_SCREEN
    end

    self:addButtonClose()
    self.buttonClose.input.onRelease = onButtonClose
    self.buttonClose.input.shortcut = Tags.KEYCODE_CANCEL
    self.buttonClose.isVisible = function(button, widget)
        return not widget.selectedSlot
    end
end

function WindowItemList:update(...)
    WindowItemList:super(self, "update", ...)
    self.alignWidth = self._director:getLeftAlignWidth()
end

function WindowItemList:createItemSlot(index, x, y, width)
    local itemSlot = self:addElement("item_slot", x, y, width, self._itemSource, self._slots[index])
    itemSlot.roundBottom = (index == self._slots:size())
    return itemSlot
end

function WindowItemList:getTitle()
    return "Item List"
end

function WindowItemList:onSelect()
    local item = false
    if self.selectedSlot then
        item = self._itemSource:get(self.selectedSlot.slot)
    end

    if self.itemWindow then
        self.itemWindow:delete()
        self.itemWindow = false
    end

    if item then
        self.itemWindow = self._director:createItemWindow(self.itemWindowClass, item, RIGHT)
        self.itemWindow.parentList = self
    end

end

return WindowItemList

