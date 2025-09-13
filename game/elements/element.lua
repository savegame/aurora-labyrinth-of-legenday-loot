local Element = class()
local Array = require("utils.classes.array")
local Vector = require("utils.classes.vector")
local InputState = require("elements.input_state")
function Element:initialize()
    self.position = Vector.ORIGIN
    self.input = false
    self.textReceiver = false
    self.rect = false
    self.isVisible = true
    self.isHidden = false
    self.parent = false
    self.children = false
end

function Element:evaluateIsVisible()
    return Utils.evaluate(self.isVisible, self, self.parent)
end

function Element:setX(x)
    self.position = Vector:new(x, self.position.y)
end

function Element:setY(y)
    self.position = Vector:new(self.position.x, y)
end

function Element:setPosition(x, y)
    if Vector:isInstance(x) then
        self.position = x
    else
        self.position = Vector:new(x, y)
    end

end

function Element:positionedRect()
    return self.rect:translated(self.position)
end

function Element:rectRight()
    return self.position.x + self.rect.x + self.rect.width
end

function Element:rectBottom()
    return self.position.y + self.rect.y + self.rect.height
end

function Element:createInput()
    self.input = InputState:new(self)
    return self.input
end

function Element:hasInput()
    return toBoolean(self.input)
end

function Element:update(dt)
end

function Element:draw(serviceViewport, timePassed)
end

function Element:delete()
    self.parent:deleteElement(self)
end

function Element:onWindowModeChange()
end

return Element

