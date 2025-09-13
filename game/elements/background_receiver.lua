local BackgroundReceiver = class("elements.element")
local Rect = require("utils.classes.rect")
function BackgroundReceiver:initialize()
    BackgroundReceiver:super(self, "initialize")
    self.rect = Rect:new(0, 0, 100, 100)
    self:createInput()
end

function BackgroundReceiver:update(dt, serviceViewport)
    local scW, scH = serviceViewport:getScreenDimensions()
    self.rect.width = scW
    self.rect.height = scH
end

return BackgroundReceiver

