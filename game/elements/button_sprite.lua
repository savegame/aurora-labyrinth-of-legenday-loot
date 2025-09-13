local ButtonSprite = class("elements.button")
local Common = require("common")
local DrawMethods = require("draw.methods")
local DrawCommand = require("utils.love2d.draw_command")
local TILE_SIZE = require("draw.measures").TILE_SIZE
local Vector = require("utils.classes.vector")
local COLORS = require("draw.colors")
function ButtonSprite:initialize(size)
    ButtonSprite:super(self, "initialize", size, size)
    self.cell = false
end

function ButtonSprite:setCell(x, y)
    self.cell = Vector:new(x, y)
end

function ButtonSprite:draw(serviceViewport, timePassed)
    ButtonSprite:super(self, "draw")
    local drawCommand = DrawCommand:new("sprites_animated")
    local frame = 0
    if self.isActivated then
        frame = Common.getSpriteFrame(timePassed)
    end

    drawCommand:setRectFromDimensions(TILE_SIZE, TILE_SIZE)
    drawCommand:setCell(self.cell.x, (self.cell.y - 1) * 2 + 1 + frame)
    drawCommand:draw((self.rect.width - TILE_SIZE) / 2, (self.rect.height - TILE_SIZE) / 2 - 1)
end

return ButtonSprite

