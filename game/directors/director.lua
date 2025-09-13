local Director = class("services.service")
Tags.add("UI_CLEAR")
local MEASURES = require("draw.measures")
local Hash = require("utils.classes.hash")
local Array = require("utils.classes.array")
local Global = require("global")
function Director:initialize()
    Director:super(self, "initialize")
    self:setDependencies("timing", "controls", "viewport", "cursor")
    self.widgets = Array:new()
    self.focusedElement = false
    self.activeTextReceiver = false
    self.screenTransitioning = false
    self._subscriptions = Hash:new()
end

function Director:createWidget(config,...)
    local widget = require("widgets." .. config):new(...)
    widget.config = config
    self.widgets:push(widget)
    return widget
end

function Director:onWindowModeChange()
    for widget in self.widgets() do
        widget:onWindowModeChange()
    end

end

function Director:moveToTop(widget)
    if self.widgets:contains(widget) then
        self.widgets:delete(widget)
        self.widgets:push(widget)
    end

end

local ASSERT_DNE_WIDGET = "Must pass self to director:subscribe"
function Director:subscribe(message, widget)
    Utils.assert(widget, ASSERT_DNE_WIDGET)
    local subscriptions = self._subscriptions:get(message, false)
    if not subscriptions then
        subscriptions = Array:new()
        self._subscriptions:set(message, subscriptions)
    end

    subscriptions:push(widget)
end

function Director:setActiveTextReceiver(element)
    if not element then
        self.activeTextReceiver = false
    else
        self.activeTextReceiver = element.textReceiver
    end

end

local function shouldDeleteWidget(widget)
    return widget.toDelete
end

function Director:publish(message,...)
    local subscriptions = self._subscriptions:get(message, false)
    if subscriptions then
        subscriptions:rejectSelf(shouldDeleteWidget)
        for widget in subscriptions() do
            widget:receiveMessage(message, ...)
        end

    end

    self:receiveMessage(message, ...)
end

function Director:receiveMessage(message,...)
end

function Director:updateWidgets(dt)
    local viewport = self.services.viewport
    local controls = self.services.controls
    local cursor = self.services.cursor
    local mousePosition = viewport:getMousePosition()
    self.widgets:rejectSelf(shouldDeleteWidget)
    for widget in self.widgets() do
        widget:resetInput()
    end

    local mouseState = controls:getLeftMouseState()
    if self.focusedElement then
        Debugger.drawText("FOCUSED", self.focusedElement.parent.config)
        local state = mouseState
        local shortcut = self.focusedElement.input.shortcut
        if shortcut then
            state = max(state, controls:getState(shortcut))
        end

        state = min(state, Tags.INPUT_PRESSED)
        self.focusedElement.parent:interactWithElement(viewport, self.focusedElement, state, mousePosition)
        cursor:updateCursor(self.focusedElement.input.cursor, viewport:getScale())
        if state <= Tags.INPUT_RELEASED then
            self.focusedElement = false
        end

    else
        local element = false
        for widget in self.widgets:reverseIterator() do
            element = widget:checkMouseReception(viewport, mouseState, mousePosition)
            if element then
                if mouseState == Tags.INPUT_TRIGGERED then
                    self.focusedElement = element
                end

                break
            end

        end

        if element then
            cursor:updateCursor(element.input.cursor, viewport:getScale())
        else
            cursor:updateCursor(cursor.defaultCursor, viewport:getScale())
        end

        if mouseState <= Tags.INPUT_HOVERED then
            local rightTriggerReceived = false
            if element and controls:getRightMouseState() == Tags.INPUT_TRIGGERED then
                element.input:rightMouseTrigger()
                rightTriggerReceived = true
            end

            if not rightTriggerReceived then
                for widget in self.widgets:reverseIterator() do
                    local element, state = widget:checkShortcutReception(controls)
                    if element then
                        if not widget.isHidden and state == Tags.INPUT_TRIGGERED then
                            self.focusedElement = element
                        end

                        break
                    end

                end

            end

        end

    end

    self.widgets:rejectSelf(shouldDeleteWidget)
    for widget in self.widgets() do
        widget:update(dt, viewport)
    end

end

function Director:drawWidgets()
    self.widgets:rejectSelf(shouldDeleteWidget)
    for widget in self.widgets() do
        widget:draw(self.services.viewport, self.services.timing.timePassed)
    end

end

function Director:screenTransition(screenClass,...)
    self.screenTransitioning = true
    local inputBlocker = self:createWidget("input_blocker", self).blocker
    inputBlocker.targetOpacity = 1
    inputBlocker.targetDuration = MEASURES.COVER_FADE_DURATION
    local args = Array:new(...)
    inputBlocker.onTargetReach = function()
        Global:set(Tags.GLOBAL_CURRENT_SCREEN, screenClass:new(args:expand()))
    end
end

function Director:createInputBlocker()
    return self:createWidget("input_blocker", self)
end

return Director

