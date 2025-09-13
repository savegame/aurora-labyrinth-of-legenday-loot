local SwingItem = class("effects.oriented_effect")
local Common = require("common")
local DrawCommand = require("utils.love2d.draw_command")
local Vector = require("utils.classes.vector")
local Rect = require("utils.classes.rect")
local Entity = require("entities.entity")
local MEASURES = require("draw.measures")
local SHADERS = require("draw.shaders")
local ITEM_SIZE = MEASURES.ITEM_SIZE
local ITEM_ORIGIN = Vector:new(0, ITEM_SIZE)
function SwingItem:initialize(icon, angle)
    SwingItem:super(self, "initialize")
    self.icon = icon or false
    self.offsetVerticalRelative = false
    self.fillColor = false
    self.fillOpacity = 0
    self.filterOutline = false
    self.originOffset = 0
    self.opacity = 1
    self.scale = 1
    self.followSpriteFrame = false
end

function SwingItem:setSilhouetteColor(color)
    self.fillColor = color
    self.fillOpacity = 1
end

function SwingItem:draw(managerCoordinates, currentTime)
    local drawCommand = self:getDrawCommandGrid(currentTime)
    drawCommand.position = managerCoordinates:gridToScreen(drawCommand.position)
    if not self.fillColor or self.fillOpacity < 1 then
        if self.filterOutline then
            drawCommand.shader = SHADERS.FILTER_OUTLINE
        end

        drawCommand:draw()
    end

    if self.fillColor and self.fillOpacity > 0 then
        if self.filterOutline then
            drawCommand.shader = SHADERS.SILHOUETTE_NO_OUTLINE
        else
            drawCommand.shader = SHADERS.SILHOUETTE
        end

        drawCommand.color = self.fillColor
        drawCommand.opacity = self.fillOpacity
        drawCommand:draw()
    end

end

local ASSERT_MESSAGE = "SwingItem requires SwingItem#icon, position"
function SwingItem:getDrawCommandGrid(currentTime)
    Utils.assert(self.icon and self.position, ASSERT_MESSAGE)
    local drawCommand = DrawCommand:new("items")
    drawCommand.rect = Rect:new((self.icon.x - 1) * ITEM_SIZE, (self.icon.y - 1) * ITEM_SIZE, ITEM_SIZE, ITEM_SIZE)
    local offset = self.offset
    if self.direction == RIGHT then
        drawCommand.angle = self.angle
    else
        drawCommand.flipX = true
        if self.direction == UP then
            drawCommand.angle = -self.angle
        else
                        if self.direction == DOWN then
                drawCommand.angle = -self.angle - math.tau / 2
            elseif self.direction == LEFT then
                drawCommand.angle = -self.angle + math.tau / 4
            end

            offset = offset * Vector[DOWN_LEFT]
        end

    end

    if self.offsetVerticalRelative and (self.direction == UP or self.direction == DOWN) then
        offset = offset:inverted() * Vector[UP_RIGHT]
    end

    drawCommand.angle = -drawCommand.angle + math.tau / 8
    drawCommand.origin = ITEM_ORIGIN
    if self.originOffset ~= 0 then
        drawCommand.origin = drawCommand.origin + Vector[DOWN_LEFT] * self.originOffset * MEASURES.TILE_SIZE / math.sqrtOf2
    end

    drawCommand.position = self:evaluatePosition() + offset
    if self.followSpriteFrame and Common.getSpriteFrame(currentTime) == 1 then
        drawCommand.position = drawCommand.position + Vector:new(0, 1 / MEASURES.TILE_SIZE)
    end

    drawCommand.scale = self.scale
    drawCommand.opacity = self.opacity
    return drawCommand
end

return SwingItem

