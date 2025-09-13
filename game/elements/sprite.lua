local Sprite = class("elements.element")
local DrawCommand = require("utils.love2d.draw_command")
local Rect = require("utils.classes.rect")
function Sprite:initialize(filename, cellSize)
    Sprite:super(self, "initialize")
    Utils.assert(cellSize, "CellSize required for sprite element")
    self._drawCommand = DrawCommand:new(filename)
    self._drawCommand.rect = Rect:new(0, 0, cellSize, cellSize)
end

function Sprite:setCell(...)
    self._drawCommand:setCell(...)
end

function Sprite:setColor(color)
    self._drawCommand.color = color
end

function Sprite:setShader(shader)
    self._drawCommand.shader = shader
end

function Sprite:setRectPosition(x, y)
    self._drawCommand:setRectPosition(x, y)
end

function Sprite:draw()
    self._drawCommand:draw()
end

return Sprite

