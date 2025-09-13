local WindowPause = class("widgets.window")
local Array = require("utils.classes.array")
local Vector = require("utils.classes.vector")
local MEASURES = require("draw.measures")
local WIDTH = MEASURES.WIDTH_PAUSE_WINDOW
local AbilityIcon = require("elements.ability_icon")
local ButtonConfig = require("structures.button_config")
local ScreenTitle = require("screens.title")
local Global = require("global")
local function onButtonClose(button, widget)
    widget._director:publish(Tags.UI_CLEAR, true)
end

local function onButtonResume(button, widget)
    widget.parent._director:publish(Tags.UI_CLEAR, true)
end

local function onButtonOptions(button, widget)
    widget.parent.isVisible = false
    widget.parent._director:publish(Tags.UI_SHOW_OPTIONS)
end

local function onMainMenu(button, widget)
    widget.parent._director:saveGame()
    Global:get(Tags.GLOBAL_AUDIO):fadeoutCurrentBGM()
    widget.parent._director:screenTransition(ScreenTitle)
end

local function onExitGame(button, widget)
    widget.parent._director:saveGame()
    event.quit()
end

local function isExitEnabled(button, widget)
    return widget.parent._director:canDoTurn()
end

local BUTTONS = Array:new(ButtonConfig:new("Resume", onButtonResume), ButtonConfig:new("Options", onButtonOptions), ButtonConfig:new("Main Menu", onMainMenu), ButtonConfig:new("Save and Exit", onExitGame, isExitEnabled))
if PortSettings.IS_MOBILE then
    BUTTONS:pop()
end

function WindowPause:initialize(director)
    WindowPause:super(self, "initialize", WIDTH)
    self._director = director
    local currentY = self:addTitle("Paused", Vector:new(11, 7))
    self:addButtonClose().input.onRelease = onButtonClose
    self.isVisible = false
    local BUTTON_WIDTH = WIDTH - MEASURES.BORDER_WINDOW * 2 - MEASURES.MARGIN_INTERNAL * 2
    currentY = currentY + MEASURES.MARGIN_INTERNAL
    self.buttonGroup = self:addChildWidget("button_group", MEASURES.BORDER_WINDOW + MEASURES.MARGIN_INTERNAL, currentY)
    local buttonY = 0
    for i, buttonConfig in ipairs(BUTTONS) do
        local label = buttonConfig.label
        if i == 4 and director:isTutorial() then
            label = "Exit"
        end

        local button = self.buttonGroup:add(label, 0, buttonY, BUTTON_WIDTH, buttonConfig.callback)
        button.input.triggerSound = "CONFIRM"
        buttonY = buttonY + button.rect.height + MEASURES.MARGIN_INTERNAL
        button.input.isEnabled = buttonConfig.isEnabled
    end

    self.buttonGroup:addControl(Tags.KEYCODE_UP, -1)
    self.buttonGroup:addControl(Tags.KEYCODE_DOWN, 1)
    currentY = currentY + buttonY
    self.window.rect.height = currentY + MEASURES.BORDER_WINDOW
    self.alignment = CENTER
    self.alignWidth = WIDTH
    if PortSettings.IS_MOBILE then
        self.alignHeight = self.window.rect.height
    else
        self.alignHeight = self.window.rect.height + AbilityIcon:GetSize() + MEASURES.MARGIN_SCREEN
    end

    director:subscribe(Tags.UI_CLEAR, self)
    director:subscribe(Tags.UI_SHOW_WINDOW_PAUSE, self)
end

function WindowPause:receiveMessage(message)
        if message == Tags.UI_CLEAR then
        self.isVisible = false
        self.buttonGroup:selectIndex(1)
    elseif message == Tags.UI_SHOW_WINDOW_PAUSE then
        self.isVisible = true
    end

end

return WindowPause

