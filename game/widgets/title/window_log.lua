local WindowLog = class("widgets.window")
local Common = require("common")
local Vector = require("utils.classes.vector")
local Array = require("utils.classes.array")
local Hash = require("utils.classes.hash")
local ItemCreateCommand = require("logic.item_create_command")
local MEASURES = require("draw.measures")
local CONSTANTS = require("logic.constants")
local TERMS = require("text.terms")
Tags.add("LOG_SHOW_ALL", 1)
Tags.add("LOG_SHOW_LEGENDARY", 2)
Tags.add("LOG_SHOW_NORMAL", 3)
local ITEMS = require("definitions.items")
local PAGE_1_SLOTS = Array:new(Tags.SLOT_WEAPON, Tags.SLOT_GLOVES, Tags.SLOT_HELM, Tags.SLOT_ARMOR)
local PAGE_2_SLOTS = Array:new(Tags.SLOT_BOOTS, Tags.SLOT_RING, Tags.SLOT_AMULET)
local Global = require("global")
local ICON = Vector:new(21, 4)
local COLUMNS = 10
local MAX_MARGIN = 12
local function itemLessWeapon(a, b)
    local maxAttackA = a:getStatAtMax(Tags.STAT_ATTACK_DAMAGE_MAX)
    local maxAttackB = b:getStatAtMax(Tags.STAT_ATTACK_DAMAGE_MAX)
    local minAttackA = a:getStatAtMax(Tags.STAT_ATTACK_DAMAGE_MIN)
    local minAttackB = b:getStatAtMax(Tags.STAT_ATTACK_DAMAGE_MIN)
    if minAttackA + maxAttackA == minAttackB + maxAttackB then
        return maxAttackA < maxAttackB
    else
        return minAttackA + maxAttackA < minAttackB + maxAttackB
    end

end

local function itemLessNonWeapon(a, b)
    return a:getStatAtMax(Tags.STAT_MAX_HEALTH, 0) > b:getStatAtMax(Tags.STAT_MAX_HEALTH, 0)
end

local function itemLessByName(a, b)
    return a.name < b.name
end

local function onItemTrigger(itemElement, widget)
    widget.buttonGroup:deselect()
    widget.selectedIndex = widget.itemElements:indexOf(itemElement)
    widget:createItemWindow(itemElement.itemDef, itemElement.discoverState, itemElement.isLegendary)
end

local function isItemActivated(itemElement, widget)
    return widget.selectedIndex == widget.itemElements:indexOf(itemElement)
end

local function onControlHorizontal(control, widget)
    Common.playSFX("CURSOR")
    local rangeStart = floor((widget.selectedIndex - 1) / COLUMNS) * COLUMNS
    local value = control.movementValue
    if widget.selectedIndex > widget.itemElements:size() then
        value = value * COLUMNS / 2
    end

    widget:selectByIndex(modAdd(widget.selectedIndex - rangeStart, value, COLUMNS) + rangeStart)
end

local function onControlVertical(control, widget)
    Common.playSFX("CURSOR")
    widget:selectByIndex(modAdd(widget.selectedIndex, control.movementValue, widget.itemElements:size() + COLUMNS))
end

local function onPageButton(control, widget)
    widget = widget.parent
    widget.page = modAdd(widget.page, 1, 2)
    if widget.page == 1 then
        widget.pageButton:setText("Next")
    else
        widget.pageButton:setText("Previous")
    end

    widget:createPageElements()
end

local function onShowButton(control, widget)
    widget = widget.parent
    widget.showMode = modAdd(widget.showMode, 1, 3)
        if widget.showMode == Tags.LOG_SHOW_ALL then
        widget.showButton:setText("Show: All")
    elseif widget.showMode == Tags.LOG_SHOW_LEGENDARY then
        widget.showButton:setText("Show: {C:LEGENDARY}Legendaries")
    else
        widget.showButton:setText("Show: Normal")
    end

    widget:createPageElements()
    widget:selectByIndex(widget.selectedIndex)
end

function WindowLog:initialize(director)
    WindowLog:super(self, "initialize", MEASURES.WIDTH_OPTIONS, 300)
    self.director = director
    self.windowItem = false
    self.windowExtra = false
    self.elementsY = self:addTitle(TERMS.UI.ITEM_LOG, ICON) + MEASURES.MARGIN_INTERNAL
    self.page = 1
    self.selectedIndex = 1
    self.showMode = Tags.LOG_SHOW_ALL
    self.itemElements = Array:new()
    local currentY = self:createPageElements()
    self.alignment = CENTER
    self:setWidth(self.itemElements[1].rect.width * COLUMNS + 4 + MEASURES.MARGIN_INTERNAL * 2)
    self:addElement("divider", MEASURES.BORDER_WINDOW, currentY, self.window.rect.width - MEASURES.BORDER_WINDOW * 2)
    currentY = currentY + 1 + MEASURES.MARGIN_INTERNAL
    self.buttonGroup = self:addChildWidget("button_group", 0, currentY)
    local buttonWidth = floor((self.window.rect.width - MEASURES.MARGIN_INTERNAL * 3 - MEASURES.BORDER_WINDOW * 2) / 2)
    self.pageButton = self.buttonGroup:add("Next", MEASURES.BORDER_WINDOW + MEASURES.MARGIN_INTERNAL, 0, buttonWidth, onPageButton)
    self.showButton = self.buttonGroup:add("Show: All", self.window.rect.width - MEASURES.BORDER_WINDOW - MEASURES.MARGIN_INTERNAL - buttonWidth, 0, buttonWidth, onShowButton)
    currentY = currentY + self.pageButton.rect.height + MEASURES.MARGIN_INTERNAL + MEASURES.BORDER_WINDOW
    self.window.rect.height = currentY + MEASURES.BORDER_WINDOW
    self.alignWidth = self.window.rect.width + MEASURES.WIDTH_ITEM_WINDOW
    self.alignHeight = self.window.rect.height
    self:addHiddenControl(Tags.KEYCODE_LEFT, onControlHorizontal, -1)
    self:addHiddenControl(Tags.KEYCODE_RIGHT, onControlHorizontal, 1)
    self:addHiddenControl(Tags.KEYCODE_UP, onControlVertical, -COLUMNS)
    self:addHiddenControl(Tags.KEYCODE_DOWN, onControlVertical, COLUMNS)
    self.buttonGroup:deselect()
    director:subscribe(Tags.UI_CLEAR, self)
    director:subscribe(Tags.UI_TITLE_SHOW_ITEM_LOG, self)
    self.isVisible = false
end

function WindowLog:createPageElements()
    local isAtButtons = self.itemElements:size() > 0 and self.selectedIndex > self.itemElements:size()
    if not self.itemElements:isEmpty() then
        for element in self.itemElements() do
            element:delete()
        end

        self.itemElements:clear()
    end

    local column = 0
    local itemStats = Global:get(Tags.GLOBAL_PROFILE).itemStats
    local currentY = self.elementsY
    local currentX = 2 + MEASURES.MARGIN_INTERNAL
    local slots = choose(self.page == 1, PAGE_1_SLOTS, PAGE_2_SLOTS)
    for slot in slots() do
        local items = ITEMS.BY_SLOT[slot]:getResults():unstableSort(itemLessByName)
                if slot == Tags.SLOT_WEAPON then
            items:stableSortSelf(itemLessWeapon)
        elseif slot ~= Tags.SLOT_AMULET and slot ~= Tags.SLOT_RING then
            items:stableSortSelf(itemLessNonWeapon)
        end

        for item in items() do
            if item.minFloor <= CONSTANTS.MAX_FLOORS then
                local itemElement = self:addElement("item_log_entry", currentX, currentY, item)
                itemElement.input.onTrigger = onItemTrigger
                itemElement.isActivated = isItemActivated
                local thisStats = itemStats:get(item.saveKey)
                if (self.showMode == Tags.LOG_SHOW_ALL or self.showMode == Tags.LOG_SHOW_LEGENDARY) then
                    if thisStats.highestLevelLegendary >= 0 then
                        itemElement.discoverState = thisStats.highestLevelLegendary
                        itemElement.isLegendary = true
                    end

                end

                if (self.showMode == Tags.LOG_SHOW_ALL or self.showMode == Tags.LOG_SHOW_NORMAL) then
                    if itemElement.discoverState < 0 then
                        itemElement.discoverState = thisStats.highestLevelNormal
                    end

                end

                if DebugOptions.ALL_DISCOVERED then
                    itemElement.discoverState = 10
                    if self.showMode == Tags.LOG_SHOW_ALL or self.showMode == Tags.LOG_SHOW_LEGENDARY then
                        itemElement.isLegendary = true
                    end

                end

                currentX = currentX + itemElement.rect.width
                column = column + 1
                if column == COLUMNS then
                    column = 0
                    currentX = 2 + MEASURES.MARGIN_INTERNAL
                    currentY = currentY + itemElement.rect.height
                end

                self.itemElements:push(itemElement)
            end

        end

        currentY = currentY + MEASURES.MARGIN_INTERNAL
    end

    if isAtButtons then
        self.selectedIndex = self.itemElements:size() + ((self.selectedIndex - 1) % COLUMNS) + 1
    end

    while self.selectedIndex > self.itemElements:size() + COLUMNS do
        self.selectedIndex = self.selectedIndex - 10
    end

    if self.selectedIndex > 1 and self.selectedIndex <= self.itemElements:size() then
        self.itemElements[self.selectedIndex].input:trigger()
    end

    return currentY
end

function WindowLog:selectByIndex(index)
    self.selectedIndex = index
        if index > self.itemElements:size() + COLUMNS / 2 then
        self.buttonGroup:selectIndex(2)
    elseif index > self.itemElements:size() then
        self.buttonGroup:selectIndex(1)
    else
        self.itemElements[index].input:trigger()
    end

end

function WindowLog:createItemWindow(itemDef, discoverState, isLegendary)
    local itemCreate = ItemCreateCommand:new(1)
    itemCreate.itemDef = itemDef
    if isLegendary then
        itemCreate.modifierDef = itemDef.legendaryMod
    end

    itemCreate.upgradeLevel = discoverState
    if self.windowItem then
        self.windowItem:delete()
        self.windowExtra:delete()
    end

    local item = itemCreate:create()
    self.windowItem = self.director:createWidget("title.window_log_item", self.director, item, self, discoverState)
    local itemStats = Global:get(Tags.GLOBAL_PROFILE).itemStats:get(itemDef.saveKey)
    self.windowExtra = self.director:createWidget("title.window_log_extra", self.director, item, self, self.windowItem, discoverState >= 0, itemStats)
end

function WindowLog:getMidMargin(serviceViewport)
    local scW, scH = serviceViewport:getScreenDimensions()
    return min(MAX_MARGIN, (scW - self.window.rect.width - MEASURES.WIDTH_ITEM_WINDOW) / 3)
end

function WindowLog:update(dt, serviceViewport)
    WindowLog:super(self, "update", dt, serviceViewport)
    self.alignWidth = self.window.rect.width + self:getMidMargin(serviceViewport) + MEASURES.WIDTH_ITEM_WINDOW
end

function WindowLog:receiveMessage(message)
        if message == Tags.UI_CLEAR then
        self.isVisible = false
    elseif message == Tags.UI_TITLE_SHOW_ITEM_LOG then
        self.isVisible = true
        if not self.windowItem then
            self.itemElements[1].input:trigger()
        end

    end

end

return WindowLog

