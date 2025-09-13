local HiddenControl = class("elements.element")
local Rect = require("utils.classes.rect")
function HiddenControl:initialize()
    HiddenControl:super(self, "initialize")
    self.rect = Rect:new(0, 0, 0, 0)
    self.isHidden = true
    self.movementValue = 0
    self:createInput()
end

return HiddenControl

