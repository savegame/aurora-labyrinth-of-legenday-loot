local ControlsMovement = class("widgets.controls_arrow")
local Common = require("common")
local Vector = require("utils.classes.vector")
local ACTIONS_BASIC = require("actions.basic")
local DIRECTION_TO_STRING = { [RIGHT] = "RIGHT", [DOWN] = "DOWN", [LEFT] = "LEFT", [UP] = "UP" }
local function onButtonPress(button, widget, fromTrigger)
    if not fromTrigger and widget._systemCaster:hasVisiblePrepared() then
        return 
    end

    local player = widget._player
    if widget._director:canDoTurn() then
        local previousDirection = player.sprite.direction
        if player.player:canTurn() then
            player.sprite:turnToDirection(button.direction)
        end

        if widget.isCasting then
            if button.direction ~= previousDirection then
                widget._director:publish(Tags.UI_CAST_TURN)
            end

        else
            if PortSettings.IS_MOBILE and not widget.isVisible then
                return false
            end

            local hasInteractive = widget._systemFrontInteractive:check(player.body:getPosition() + Vector[button.direction])
            if not hasInteractive then
                local action = player.player:getBasicDirectionalAction(button.direction)
                if action then
                    widget._director:logAction("Direction - " .. DIRECTION_TO_STRING[button.direction])
                    widget._director:executePlayerAction(action)
                end

            end

        end

    end

end

local function onButtonTrigger(button, widget)
    if widget._systemCaster:hasVisiblePrepared() then
        onButtonPress(button, widget, true)
    end

end

local function onCenterButtonPress(button, widget)
    if widget._director:canDoTurn() then
        if not widget.isCasting then
            widget._director:logAction("Wait")
            widget._director:startTurnWithWait()
        end

    end

end

local function onCenterButtonTrigger(button, widget)
    if widget._director:canDoTurn() then
        if widget.isCasting then
            Common.playSFX("CANCEL")
            widget._director:publish(Tags.UI_CLEAR)
            button.input.onPress = doNothing
        end

    end

end

local function onCenterButtonRelease(button, widget)
    button.input.onPress = onCenterButtonPress
end

local function getCenterButtonImage(button, widget)
    if widget.isCasting then
        return "cancel"
    else
        return "wait"
    end

end

function ControlsMovement:initialize(director, player, systemFrontInteractive, systemCaster)
    ControlsMovement:super(self, "initialize")
    self._director = director
    self._player = player
    self._systemFrontInteractive = systemFrontInteractive
    self._systemCaster = systemCaster
    self.isCasting = false
    self.isHidden = (not PortSettings.IS_MOBILE)
    self.buttons[CENTER] = self:addElement("button_image", self.buttons[UP].position.x, self.buttons[LEFT].position.y, self.buttons[UP].rect.width, getCenterButtonImage)
    self.buttons[CENTER].input.shortcut = Tags.KEYCODE_WAIT
    for direction in DIRECTIONS_AA() do
        local buttonInput = self.buttons[direction].input
        buttonInput.onPress = onButtonPress
        buttonInput.onTrigger = onButtonTrigger
        buttonInput.triggerSound = false
    end

    self.buttons[CENTER].input.onPress = onCenterButtonPress
    self.buttons[CENTER].input.onTrigger = onCenterButtonTrigger
    self.buttons[CENTER].input.onRelease = onCenterButtonRelease
    self.buttons[CENTER].input.triggerSound = false
    director:subscribe(Tags.UI_ABILITY_SELECTED, self)
    if PortSettings.IS_MOBILE then
        director:subscribe(Tags.UI_SHOW_WINDOW_EQUIPMENT, self)
        director:subscribe(Tags.UI_SHOW_WINDOW_KEYWORDS, self)
        director:subscribe(Tags.UI_SHOW_INTRO, self)
        director:subscribe(Tags.UI_SHOW_ANVIL, self)
        director:subscribe(Tags.UI_HIDE_CONTROLS, self)
        director:subscribe(Tags.UI_ITEM_STEP, self)
        director:subscribe(Tags.UI_CLEAR, self)
    else
        director:subscribe(Tags.UI_MOUSE_BACKGROUND_PRESS, self)
        director:subscribe(Tags.UI_MOUSE_BACKGROUND_TRIGGER, self)
    end

end

function ControlsMovement:receiveMessage(message, abilityOrPosition, isSlotActive, slot)
            if message == Tags.UI_ABILITY_SELECTED then
        self.isCasting = toBoolean(abilityOrPosition)
    elseif (message == Tags.UI_MOUSE_BACKGROUND_PRESS or message == Tags.UI_MOUSE_BACKGROUND_TRIGGER) then
        self:translateMouseToButton(message, abilityOrPosition)
    elseif PortSettings.IS_MOBILE then
                if message == Tags.UI_SHOW_WINDOW_EQUIPMENT or message == Tags.UI_SHOW_WINDOW_KEYWORDS or message == Tags.UI_ITEM_STEP or message == Tags.UI_SHOW_INTRO or message == Tags.UI_SHOW_ANVIL or message == Tags.UI_HIDE_CONTROLS then
            self.isVisible = false
        elseif message == Tags.UI_CLEAR then
            self.isVisible = true
        end

    end

end

function ControlsMovement:translateMouseToButton(message, gridPosition)
    local player = self._player
    local playerPosition = player.body:getPosition()
    local dx = abs(playerPosition.x - gridPosition.x)
    local dy = abs(playerPosition.y - gridPosition.y)
        if dx ~= dy then
        local direction = Common.getDirectionTowards(playerPosition, gridPosition)
        self.buttons[direction].input:press(message == Tags.UI_MOUSE_BACKGROUND_TRIGGER)
    elseif dx == 0 and dy == 0 then
        self.buttons[CENTER].input:press()
    end

end

return ControlsMovement

