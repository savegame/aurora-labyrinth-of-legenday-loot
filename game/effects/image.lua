local Image = class("effects.oriented_effect")
local DrawCommand = require("utils.love2d.draw_command")
local Vector = require("utils.classes.vector")
local Rect = require("utils.classes.rect")
local MEASURES = require("draw.measures")
function Image:initialize(image)
    Image:super(self, "initialize")
    Utils.assert(image, "Image requires Image#image")
    self.image = image
    self.opacity = 1
    self.cellSize = false
    self.cell = false
    self.color = WHITE
    self.shader = false
    self.originOffset = Vector.ORIGIN
    self.orientOffset = true
    self.flipRight = false
end

function Image:draw(managerCoordinates)
    local drawCommand = self:getDrawCommandGrid()
    drawCommand.position = managerCoordinates:gridToScreen(drawCommand.position)
    drawCommand:draw()
end

function Image:getDrawCommandGrid()
    Utils.assert(self.image and self.position, "Image requires Image#image, #position")
    local drawCommand = DrawCommand:new(self.image)
    if self.cellSize then
        drawCommand.rect = Rect:new((self.cell.x - 1) * self.cellSize, (self.cell.y - 1) * self.cellSize, self.cellSize, self.cellSize)
    else
        drawCommand:setRectFromImage()
    end

    drawCommand:setOriginToCenter()
    local originOffset = self.originOffset
    local offset = self.offset
    if self.direction == RIGHT then
        if self.flipRight then
            drawCommand.flipX = true
            drawCommand.angle = self.angle - math.tau / 2
        else
            drawCommand.angle = self.angle
        end

    else
        drawCommand.flipX = true
                        if self.direction == LEFT then
            drawCommand.angle = -self.angle
            offset = offset * Vector[DOWN_LEFT]
        elseif self.direction == DOWN then
            drawCommand.angle = -self.angle - math.tau / 4
            offset = offset:inverted()
        elseif self.direction == UP then
            drawCommand.angle = -self.angle + math.tau / 4
            offset = offset:inverted() * Vector[UP_LEFT]
        end

    end

    if not self.orientOffset then
        offset = self.offset
    end

    drawCommand.color = self.color
    drawCommand.shader = self.shader
    drawCommand.opacity = self.opacity
    drawCommand.origin = drawCommand.origin + originOffset * MEASURES.TILE_SIZE
    drawCommand.position = self:evaluatePosition() + offset
    return drawCommand
end

return Image

