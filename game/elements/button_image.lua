local ButtonImage = class("elements.button")
local DrawCommand = require("utils.love2d.draw_command")
local COLORS = require("draw.colors")
function ButtonImage:initialize(size, getImage)
    ButtonImage:super(self, "initialize", size, size)
    self.getImage = getImage
    self.drawCommand = DrawCommand:new()
end

function ButtonImage:getColorSource()
    local image = Utils.evaluate(self.getImage, self, self.parent)
    if image == "cancel" then
        return COLORS.CLOSE
    else
        return ButtonImage:super(self, "getColorSource")
    end

end

function ButtonImage:draw()
    ButtonImage:super(self, "draw")
    graphics.wSetColor(WHITE)
    local image = Utils.evaluate(self.getImage, self, self.parent)
    self.drawCommand.image = image
    self.drawCommand:setRectFromImage()
    self.drawCommand:setOriginToCenter()
    self.drawCommand.position = self.rect:center()
    self.drawCommand:draw()
end

return ButtonImage

