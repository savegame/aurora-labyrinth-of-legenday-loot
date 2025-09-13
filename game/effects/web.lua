local Web = class("effects.effect")
local Vector = require("utils.classes.vector")
local Rect = require("utils.classes.rect")
local Color = require("utils.classes.color")
local COLOR_WEB_BODY = Color:new(0.95, 0.95, 0.95)
local COLOR_WEB_EDGE = Color:new(0.15, 0.15, 0.15)
local MEASURES = require("draw.measures")
local CENTER = Vector:new(MEASURES.TILE_SIZE / 2, MEASURES.TILE_SIZE / 2)
function Web:initialize()
    Web:super(self, "initialize")
    self.position = false
    self.direction = false
    self.length = 0
end

function Web:draw(managerCoordinates)
    local starting = managerCoordinates:gridToScreen(self.position + MEASURES.SHADOWED_OFFSET) + CENTER
    local rect = Rect:new(starting.x - 1, starting.y - 1, 2, 2)
    rect:growDirectionSelf(self.direction, MEASURES.TILE_SIZE * self.length - 1)
    rect:growDirectionSelf(reverseDirection(self.direction), -MEASURES.TILE_SIZE / 4)
    if rect.width > 0 and rect.height > 0 then
        local edgeRect = rect:growDirection(cwDirection(self.direction), 1)
        edgeRect:growDirectionSelf(ccwDirection(self.direction), 1)
        graphics.wSetColor(COLOR_WEB_EDGE)
        graphics.wRectangle(edgeRect)
        graphics.wSetColor(COLOR_WEB_BODY)
        graphics.wRectangle(rect)
    end

end

return Web

