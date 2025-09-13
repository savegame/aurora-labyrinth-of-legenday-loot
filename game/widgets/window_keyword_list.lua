local WindowKeywordList = class("widgets.window")
local Common = require("common")
local Array = require("utils.classes.array")
local Vector = require("utils.classes.vector")
local COLORS = require("draw.colors")
local MEASURES = require("draw.measures")
local FONT = require("draw.fonts").MEDIUM
local WIDTH = MEASURES.WIDTH_ITEM_WINDOW
local COLUMNS = 3
local LIST = require("text.keywords").LIST
local AbilityIcon = require("elements.ability_icon")
local GAME_MENU_SIZE = require("elements.button_game_menu").SIZE
local function isItemSlotActivated(itemSlot, widget)
    return itemSlot == widget.selectedSlot
end

local function onItemSlotTrigger(itemSlot, widget)
    if widget.selectedSlot ~= itemSlot then
        widget.selectedSlot = itemSlot
        widget:moveElementToTop(itemSlot)
        widget:onSelect(widget.itemSlots:indexOf(widget.selectedSlot))
    end

end

local function onControlVertical(control, widget)
    Common.playSFX("CURSOR")
    local index = widget.itemSlots:indexOf(widget.selectedSlot)
    index = modAdd(index, control.movementValue, widget.itemSlots:size())
    widget.itemSlots[index].input:trigger()
end

local function onControlHorizontal(control, widget)
    Common.playSFX("CURSOR")
    local index = widget.itemSlots:indexOf(widget.selectedSlot)
    local rangeStart = floor((index - 1) / COLUMNS) * COLUMNS
    index = modAdd(index - rangeStart, control.movementValue, COLUMNS) + rangeStart
    widget.itemSlots[index].input:trigger()
end

function WindowKeywordList:initialize(director)
    WindowKeywordList:super(self, "initialize", WIDTH)
    self.director = director
    local startingX = MEASURES.BORDER_WINDOW
    local currentY = self:addTitle("Game Terms", Vector:new(18, 4))
    self.windowTitle.color = COLORS.TEXT_COLOR_PALETTE:get("KEYWORD")
    self.itemSlots = Array:new()
    self.descriptionWindow = false
    self.selectedSlot = false
    self.isVisible = false
    local currentX = startingX - 1
    for i = 1, LIST:size() do
        local itemSlot = self:addElement("list_slot", currentX, currentY - 1, ceil(WIDTH / COLUMNS) - (startingX - 1), true)
        if i % 3 ~= 2 then
            itemSlot.rect.width = itemSlot.rect.width + 1
        end

        itemSlot.label = LIST[i].name
        itemSlot.isActivated = isItemSlotActivated
        itemSlot.input.onTrigger = onItemSlotTrigger
        itemSlot.labelColor = COLORS.TEXT_COLOR_PALETTE:get("KEYWORD")
        itemSlot.roundBottom = (i >= LIST:size() - COLUMNS + 1)
        if i % COLUMNS == 0 then
            currentY = currentY + itemSlot.rect.height - 1
            currentX = startingX - 1
        else
            currentX = currentX + itemSlot.rect.width - 1
        end

        self.itemSlots:push(itemSlot)
    end

    self.window.rect.height = currentY + MEASURES.BORDER_WINDOW - 1
    self.alignment = CENTER
    self.alignWidth = MEASURES.WIDTH_ITEM_WINDOW * 2 + MEASURES.MARGIN_ITEM_WINDOW
    if PortSettings.IS_MOBILE then
        self.alignHeight = self.window.rect.height - GAME_MENU_SIZE - MEASURES.MARGIN_SCREEN
    else
        self.alignHeight = self.window.rect.height + AbilityIcon:GetSize() + MEASURES.MARGIN_SCREEN
    end

    self:addHiddenControl(Tags.KEYCODE_UP, onControlVertical, -COLUMNS)
    self:addHiddenControl(Tags.KEYCODE_DOWN, onControlVertical, COLUMNS)
    self:addHiddenControl(Tags.KEYCODE_RIGHT, onControlHorizontal, 1)
    self:addHiddenControl(Tags.KEYCODE_LEFT, onControlHorizontal, -1)
    director:subscribe(Tags.UI_CLEAR, self)
    director:subscribe(Tags.UI_SHOW_WINDOW_KEYWORDS, self)
    self.itemSlots[1].input:trigger()
end

function WindowKeywordList:onSelect(index)
    if self.descriptionWindow then
        self.descriptionWindow:delete()
    end

    self.descriptionWindow = self.director:createWidget("window_keyword_description", self.director, LIST[index], self.alignHeight)
end

function WindowKeywordList:receiveMessage(message)
        if message == Tags.UI_CLEAR then
        if self.descriptionWindow then
            self.descriptionWindow:delete()
            self.descriptionWindow = false
        end

        self.isVisible = false
    elseif message == Tags.UI_SHOW_WINDOW_KEYWORDS then
        self.isVisible = true
        local selected = self.selectedSlot or self.itemSlots[1]
        self.selectedSlot = false
        selected.input:trigger()
    end

end

function WindowKeywordList:update(...)
    WindowKeywordList:super(self, "update", ...)
    self.alignWidth = self.director:getLeftAlignWidth()
end

return WindowKeywordList

