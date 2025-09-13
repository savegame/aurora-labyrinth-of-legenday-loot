local DockWindowButtons = class("widgets.widget")
local Array = require("utils.classes.array")
local Vector = require("utils.classes.vector")
local MEASURES = require("draw.measures")
local BUTTON_SIZE = require("elements.button_game_menu").SIZE
local ICONS = Array:new(Vector:new(1, 1), Vector:new(2, 1), Vector:new(1, 2))
local function onPauseButton(button, widget)
    local previousState = button.isActivated
    widget._director:publish(Tags.UI_CLEAR, previousState)
    button.isActivated = (not previousState)
    if button.isActivated then
        widget._director:publish(Tags.UI_SHOW_WINDOW_PAUSE)
    end

end

local function onEquipmentButton(button, widget)
    local previousState = button.isActivated
    widget._director:publish(Tags.UI_CLEAR, previousState)
    button.isActivated = (not previousState)
    if button.isActivated then
        widget._director:publish(Tags.UI_SHOW_WINDOW_EQUIPMENT)
    end

end

local function onKeywordsButton(button, widget)
    local previousState = button.isActivated
    widget._director:publish(Tags.UI_CLEAR, previousState)
    button.isActivated = (not previousState)
    if button.isActivated then
        widget._director:publish(Tags.UI_SHOW_WINDOW_KEYWORDS)
    end

end

function DockWindowButtons:initialize(director)
    DockWindowButtons:super(self, "initialize")
    self._director = director
    self.alignment = UP_RIGHT
    local BUTTONS = 3
    self.alignHeight = BUTTON_SIZE
    self:setPosition(MEASURES.MARGIN_SCREEN, MEASURES.MARGIN_SCREEN)
    local currentX = 0
    if PortSettings.IS_MOBILE then
        currentX = (BUTTON_SIZE + MEASURES.MARGIN_BUTTON) * (BUTTONS - 1)
    end

    self.buttons = Array:new()
    for i = 1, 3 do
        local button = self:addElement("button_game_menu", currentX, 0, ICONS[i])
        self.buttons:push(button)
        if PortSettings.IS_MOBILE then
            currentX = currentX - BUTTON_SIZE - MEASURES.MARGIN_BUTTON
        else
            currentX = currentX + BUTTON_SIZE + MEASURES.MARGIN_BUTTON
        end

    end

    self.alignWidth = BUTTON_SIZE * BUTTONS + MEASURES.MARGIN_BUTTON * (BUTTONS - 1)
    self.buttons[1].input.onRelease = onEquipmentButton
    self.buttons[1].input.shortcut = Tags.KEYCODE_EQUIPMENT
    self.buttons[2].input.onRelease = onKeywordsButton
    self.buttons[2].input.shortcut = Tags.KEYCODE_KEYWORDS
    self.buttons[3].input.onRelease = onPauseButton
    self.buttons[3].input.shortcut = Tags.KEYCODE_CANCEL
    director:subscribe(Tags.UI_CLEAR, self)
end

function DockWindowButtons:receiveMessage(message)
    if message == Tags.UI_CLEAR then
        for button in self.buttons() do
            button.isActivated = false
        end

    end

end

return DockWindowButtons

