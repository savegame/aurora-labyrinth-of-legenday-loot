local BlockerWall = class("elements.element")
local Rect = require("utils.classes.rect")
local DEFAULT_DURATION = 0.1
function BlockerWall:initialize()
    BlockerWall:super(self, "initialize")
    self.rect = Rect:new(-1, -1, 100, 100)
    self:createInput()
    self.opacity = 0
    self.targetOpacity = 0
    self.targetDuration = DEFAULT_DURATION
    self.onTargetReach = doNothing
end

function BlockerWall:update(dt, serviceViewport)
    local scW, scH = serviceViewport:getScreenDimensions()
    self.rect.width = scW + 2
    self.rect.height = scH + 2
    self.opacity = min(self.targetOpacity, self.opacity + dt * self.targetOpacity / self.targetDuration)
    if self.opacity >= self.targetOpacity then
        self.onTargetReach()
    end

end

function BlockerWall:draw()
    graphics.wSetColor(0, 0, 0, self.opacity)
    graphics.wRectangle(self.rect)
end

return BlockerWall

