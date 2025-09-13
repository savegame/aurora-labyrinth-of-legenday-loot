local BackgroundInput = class("widgets.widget")
local Vector = require("utils.classes.vector")
local function onReceiverHover(receiver, widget)
    local mousePosition = widget._serviceViewport:getMousePosition()
    local gridPosition = widget._serviceCoordinates:screenToGrid(mousePosition)
    if widget.lastGridPosition ~= gridPosition then
        widget.lastGridPosition = gridPosition
        widget._director:publish(Tags.UI_MOUSE_TILE_CHANGED, gridPosition)
    end

end

local function onReceiverTrigger(receiver, widget)
    if widget._serviceVision:isVisible(widget.lastGridPosition) then
        widget._director:publish(Tags.UI_MOUSE_BACKGROUND_TRIGGER, widget.lastGridPosition)
    end

end

local function onReceiverPress(receiver, widget)
    if widget._serviceVision:isVisible(widget.lastGridPosition) then
        widget._director:publish(Tags.UI_MOUSE_BACKGROUND_PRESS, widget.lastGridPosition)
    end

end

local function onReceiverRightMouseTrigger(receiver, widget)
    widget._director:publish(Tags.UI_MOUSE_RIGHT_TRIGGER)
end

function BackgroundInput:initialize(director, serviceViewport, serviceCoordinates, serviceVision)
    BackgroundInput:super(self, "initialize")
    self._director = director
    self._serviceViewport = serviceViewport
    self._serviceCoordinates = serviceCoordinates
    self._serviceVision = serviceVision
    self.lastGridPosition = Vector:new(-1, -1)
    self.receiver = self:addElement("background_receiver", 0, 0)
    self.receiver.input.onHover = onReceiverHover
    self.receiver.input.onPress = onReceiverPress
    self.receiver.input.onTrigger = onReceiverTrigger
    self.receiver.input.onRightMouseTrigger = onReceiverRightMouseTrigger
end

return BackgroundInput

