local DrawCommand = class()
local Vector = require("utils.classes.vector")
local Rect = require("utils.classes.rect")
function DrawCommand:initialize(image)
    self.image = image or false
    self.rect = false
    self.angle = 0
    self.scale = 1
    self.flipX = false
    self.flipY = false
    self.shader = false
    self.stencilRect = false
    self.stencilRectInclude = true
    self.origin = Vector.ORIGIN
    self.position = Vector.ORIGIN
    self.opacity = 1
    self.color = WHITE
    if image then
        self:setRectFromImage()
    end

end

local ASSERT_DRAW_COMMAND_REQUIRED = "DrawCommand requires DrawCommand#image"
function DrawCommand:checkImage()
    Utils.assert(self.image, ASSERT_DRAW_COMMAND_REQUIRED)
end

function DrawCommand:draw(x, y)
    self:checkImage()
    local image = Utils.loadImage(self.image)
    local quad = Utils.loadQuad(self.image)
    if self.rect then
        quad:setViewport(self.rect:expand())
    else
        quad:setViewport(0, 0, image:getDimensions())
    end

    local scaleX, scaleY = self.scale, self.scale
    if self.flipX then
        scaleX = -scaleX
    end

    if self.flipY then
        scaleY = -scaleY
    end

    if self.shader then
        graphics.setShader(self.shader)
    end

    if self.stencilRect then
        if self.stencilRectInclude then
            Utils.stencilInclude(function()
                graphics.wRectangle(self.stencilRect)
            end)
        else
            Utils.stencilExclude(function()
                graphics.wRectangle(self.stencilRect)
            end)
        end

    end

    x = x or 0
    y = y or 0
    graphics.setColor(self.color:expandValues(self.opacity * self.color.a))
    graphics.draw(image, quad, self.position.x + x, self.position.y + y, self.angle, scaleX, scaleY, self.origin.x, self.origin.y)
    if self.stencilRect then
        Utils.stencilDisable()
    end

    if self.shader then
        graphics.setShader()
    end

end

function DrawCommand:getImageDimensions()
    self:checkImage()
    return Utils.loadImage(self.image):getDimensions()
end

function DrawCommand:_getRect()
    if self.rect then
        return self.rect
    else
        return Rect:new(0, 0, self:getImageDimensions())
    end

end

function DrawCommand:getDimensions()
    return self:_getRect():getDimensions()
end

function DrawCommand:getWidth()
    return self:_getRect().width
end

function DrawCommand:getHeight()
    return self:_getRect().height
end

function DrawCommand:getScaledDimensions()
    local width, height = self:getDimensions()
    return width * self.scale, height * self.scale
end

function DrawCommand:setRectFromImage()
    self.rect = Rect:new(0, 0, self:getImageDimensions())
end

function DrawCommand:setRectFromDimensions(width, height)
    self.rect = Rect:new(0, 0, width, height)
end

function DrawCommand:setRectPosition(x, y)
    Utils.assert(self.rect, "DrawCommand#rect required for setRectPosition")
    self.rect:setPosition(x, y)
end

function DrawCommand:setCell(cx, cy)
    if type(cx) == "table" then
        cx, cy = cx.x, cx.y
    end

    Utils.assert(self.rect, "DrawCommand#rect required for setCell")
    self.rect:setPosition((cx - 1) * self.rect.width, (cy - 1) * self.rect.height)
end

function DrawCommand:setOriginToCenter()
    local width, height = self:getDimensions()
    self.origin = Vector:new(width / 2, height / 2)
end

function DrawCommand:setOriginToPixelCenter()
    local width, height = self:getDimensions()
    self.origin = Vector:new((width - 1) / 2, (height - 1) / 2)
end

return DrawCommand

