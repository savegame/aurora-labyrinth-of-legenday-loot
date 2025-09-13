local Item = class("elements.element")
local Vector = require("utils.classes.vector")
local Rect = require("utils.classes.rect")
local MEASURES = require("draw.measures")
local DrawMethods = require("draw.methods")
local DrawCommand = require("utils.love2d.draw_command")
local drawIconCommand = DrawCommand:new("items")
drawIconCommand:setRectFromDimensions(MEASURES.ITEM_SIZE, MEASURES.ITEM_SIZE)
local strokeCommand = DrawCommand:new("items_stroke")
strokeCommand.position = Vector:new(-1, -1)
strokeCommand:setRectFromDimensions(MEASURES.ITEM_SIZE + 2, MEASURES.ITEM_SIZE + 2)
function Item:initialize(item)
    Item:super(self, "initialize")
    self.item = item
    self.rect = Rect:new(-MEASURES.ITEM_SIZE / 2, -MEASURES.ITEM_SIZE / 2, MEASURES.ITEM_SIZE * 2, MEASURES.ITEM_SIZE * 2)
    self:createInput()
end

function Item:draw()
    if DebugOptions.STARTING_LEGENDARY and self.item.legendaryMod then
        local color = self.item.legendaryMod:getLegendaryStrokeColor(self.item)
        strokeCommand:setCell(self.item.icon)
        strokeCommand.color = color
        strokeCommand:draw()
    end

    graphics.wSetColor(WHITE)
    drawIconCommand:setCell(self.item.icon)
    drawIconCommand:draw()
    graphics.wSetColor(WHITE:expandValues(self.input:getOpacity()))
    DrawMethods.lineRect(self.rect)
end

return Item

