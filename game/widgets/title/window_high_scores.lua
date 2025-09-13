local WindowHighScores = class("widgets.window")
local Vector = require("utils.classes.vector")
local Array = require("utils.classes.array")
local MEASURES = require("draw.measures")
local ICON = Vector:new(10, 5)
local Global = require("global")
local ENTRIES_PER_PAGE = 7
local function onButtonClose(button, widget)
    widget.director:publish(Tags.UI_CLEAR)
    widget.director:publish(Tags.UI_TITLE_BACK)
end

local function isPrevButtonEnabled(button, widget)
    return widget.parent.page > 1
end

local function isNextButtonEnabled(button, widget)
    local numEntries = Global:get(Tags.GLOBAL_PROFILE).morgueEntries:size()
    return widget.parent.page < ceil(numEntries / ENTRIES_PER_PAGE)
end

local function onPrevButton(button, widget)
    widget.parent.page = widget.parent.page - 1
    widget.parent:createPageElements()
end

local function onNextButton(button, widget)
    widget.parent.page = widget.parent.page + 1
    widget.parent:createPageElements()
end

function WindowHighScores:initialize(director)
    WindowHighScores:super(self, "initialize", MEASURES.WIDTH_HIGHSCORE, 250)
    self.director = director
    local currentY = self:addTitle("High Scores", ICON) - 1
    self:addButtonClose().input.onRelease = onButtonClose
    director:subscribe(Tags.UI_CLEAR, self)
    director:subscribe(Tags.UI_TITLE_SHOW_STATS, self)
    self.startingY = currentY
    self.itemElements = Array:new()
    self.page = 1
    currentY = self:createPageElements()
    currentY = currentY + 1 + MEASURES.MARGIN_INTERNAL
    self.buttonGroup = self:addChildWidget("button_group", 0, currentY)
    local buttonWidth = floor((self.window.rect.width - MEASURES.MARGIN_INTERNAL * 3 - MEASURES.BORDER_WINDOW * 2) / 2)
    local prevButton = self.buttonGroup:add("Previous", MEASURES.BORDER_WINDOW + MEASURES.MARGIN_INTERNAL, 0, buttonWidth, onPrevButton)
    prevButton.input.isEnabled = isPrevButtonEnabled
    local nextButton = self.buttonGroup:add("Next", self.window.rect.width - MEASURES.BORDER_WINDOW - MEASURES.MARGIN_INTERNAL - buttonWidth, 0, buttonWidth, onNextButton)
    nextButton.input.isEnabled = isNextButtonEnabled
    currentY = currentY + prevButton.rect.height + MEASURES.MARGIN_INTERNAL + MEASURES.BORDER_WINDOW
    self.buttonGroup:addControl(Tags.KEYCODE_LEFT, -1)
    self.buttonGroup:addControl(Tags.KEYCODE_RIGHT, 1)
    self.buttonGroup:selectIndex(2)
    self.alignment = CENTER
    self.alignWidth = self.window.rect.width
    self.window.rect.height = currentY + MEASURES.BORDER_WINDOW
    self.alignHeight = self.window.rect.height
    self.isVisible = false
end

function WindowHighScores:createPageElements()
    if not self.itemElements:isEmpty() then
        for element in self.itemElements() do
            element:delete()
        end

        self.itemElements:clear()
    end

    local currentY = self.startingY
    local morgueEntries = Global:get(Tags.GLOBAL_PROFILE).morgueEntries
    for i = 1, ENTRIES_PER_PAGE do
        local morgueEntry = false
        local index = i + (self.page - 1) * ENTRIES_PER_PAGE
        if index <= morgueEntries:size() then
            morgueEntry = morgueEntries[index]
        end

        local entry = self:addElement("morgue_entry", 1, currentY, MEASURES.WIDTH_HIGHSCORE - 2, morgueEntry)
        self.itemElements:push(entry)
        currentY = currentY + entry.rect.height - 1
    end

    self:moveElementToTop(self.buttonClose)
    return currentY
end

function WindowHighScores:receiveMessage(message)
        if message == Tags.UI_CLEAR then
        self.isVisible = false
    elseif message == Tags.UI_TITLE_SHOW_STATS then
        self.isVisible = true
    end

end

return WindowHighScores

