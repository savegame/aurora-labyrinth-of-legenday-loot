local MainButtons = class("widgets.button_group")
local Array = require("utils.classes.array")
local Vector = require("utils.classes.vector")
local FILENAMES = require("text.filenames")
local TERMS = require("text.terms")
local BUTTON_WIDTH = require("draw.measures").TITLE_BUTTON_WIDTH
local MEASURES = require("draw.measures")
local BUTTON_MARGIN = 8
local ButtonConfig = require("structures.button_config")
local function onNewGame(button, widget)
    widget._director:publish(Tags.UI_CLEAR)
    widget._director:publish(Tags.UI_TITLE_SHOW_NEW_GAME)
end

local function onOptions(button, widget)
    widget._director:publish(Tags.UI_CLEAR)
    widget._director:cover()
    widget._director:publish(Tags.UI_SHOW_OPTIONS)
end

local function onStats(button, widget)
    widget._director:publish(Tags.UI_CLEAR)
    widget._director:cover()
    widget._director:publish(Tags.UI_TITLE_SHOW_STATS)
end

local function onItemLog(button, widget)
    widget._director:publish(Tags.UI_CLEAR)
    widget._director:cover()
    widget._director:publish(Tags.UI_TITLE_SHOW_ITEM_LOG)
end

local function onContinue(button, widget)
    local success = widget._director:continueGame()
    if not success then
        button.input.isEnabled = false
    end

end

local function onCredits(button, widget)
    widget._director:publish(Tags.UI_CLEAR)
    widget._director:cover()
    widget._director:publish(Tags.UI_TITLE_SHOW_CREDITS)
end

local function onExit(button, widget)
    love.errorhandler = alwaysNil
    event.quit()
end

function MainButtons:getButtonConfigs()
    local buttons = Array:new(ButtonConfig:new("Continue", onContinue, toBoolean(filesystem.getInfo(FILENAMES.CURRENT_RUN, "file"))), ButtonConfig:new("New Game", onNewGame), ButtonConfig:new("High Scores", onStats), ButtonConfig:new(TERMS.UI.ITEM_LOG, onItemLog), ButtonConfig:new("Options", onOptions), ButtonConfig:new("Credits", onCredits), ButtonConfig:new("Exit", onExit))
    if PortSettings.IS_MOBILE then
        buttons:pop()
    end

    return buttons
end

function MainButtons:getButtonMargin(viewport)
    if PortSettings.IS_MOBILE then
        local scW, scH = viewport:getScreenDimensions()
        if scH < 340 then
            return BUTTON_MARGIN - 4
        end

    end

    return BUTTON_MARGIN
end

function MainButtons:nextY(currentY, button, viewport)
    return currentY + button.rect.height + self:getButtonMargin(viewport)
end

function MainButtons:initialize(director)
    MainButtons:super(self, "initialize")
    self._director = director
    self.alignment = DOWN_LEFT
    for config in (self:getButtonConfigs())() do
        local button = self:add(config.label, 0, 0, BUTTON_WIDTH, config.callback)
        button.input.isEnabled = config.isEnabled
        button.input.triggerSound = "CONFIRM"
    end

    self.alignWidth = BUTTON_WIDTH
    local bw, bh = Utils.loadImage("banner"):getDimensions()
    self:setPosition(MEASURES.MARGIN_TITLE + (bw * 2 - BUTTON_WIDTH) / 2, MEASURES.MARGIN_TITLE - 12)
    self.selectedButton = false
    if not self.buttons[1].input:evaluateIsEnabled() then
        self:selectIndex(2)
    else
        self:selectIndex(1)
    end

    self:addControl(Tags.KEYCODE_UP, -1)
    self:addControl(Tags.KEYCODE_DOWN, 1)
    if PortSettings.IS_MOBILE then
        self:addHiddenControl(Tags.KEYCODE_CANCEL, event.quit)
    end

    director:subscribe(Tags.UI_CLEAR, self)
    director:subscribe(Tags.UI_TITLE_BACK, self)
end

function MainButtons:update(dt, viewport)
    MainButtons:super(self, "update", dt)
    self:updateButtonPositions(viewport)
end

function MainButtons:updateButtonPositions(viewport)
    local currentY = 0
    for button in self.buttons() do
        button:setPosition(0, currentY)
        currentY = self:nextY(currentY, button, viewport)
    end

    self.alignHeight = (currentY - self:getButtonMargin(viewport))
end

function MainButtons:receiveMessage(message)
        if message == Tags.UI_CLEAR then
        self.isVisible = false
    elseif message == Tags.UI_TITLE_BACK then
        self.isVisible = true
    end

end

return MainButtons

