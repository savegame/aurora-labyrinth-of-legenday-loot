local ItemLogEntry = class("elements.element")
local Common = require("common")
local Color = require("utils.classes.color")
local Vector = require("utils.classes.vector")
local Rect = require("utils.classes.rect")
local COLORS = require("draw.colors")
local MEASURES = require("draw.measures")
local SHADERS = require("draw.shaders")
local DrawMethods = require("draw.methods")
local DrawCommand = require("utils.love2d.draw_command")
local drawIconCommand = DrawCommand:new("items")
drawIconCommand:setRectFromDimensions(MEASURES.ITEM_SIZE, MEASURES.ITEM_SIZE)
local glowIconCommand = DrawCommand:new("items")
glowIconCommand:setRectFromDimensions(MEASURES.ITEM_SIZE, MEASURES.ITEM_SIZE)
glowIconCommand.shader = SHADERS.OUTLINE_AS_COLOR
local maxLevel = DrawCommand:new("max_level_reached")
local strokeCommand = DrawCommand:new("items_stroke")
strokeCommand.position = Vector:new(-1, -1)
strokeCommand:setRectFromDimensions(MEASURES.ITEM_SIZE + 2, MEASURES.ITEM_SIZE + 2)
local MARGIN = 4
function ItemLogEntry:initialize(itemDef)
    ItemLogEntry:super(self, "initialize")
    self.itemDef = itemDef
    self.rect = Rect:new(0, 0, MEASURES.ITEM_SIZE + (1 + MARGIN) * 2, MEASURES.ITEM_SIZE + (1 + MARGIN) * 2)
    self:createInput()
    self.discoverState = -1
    self.isActivated = false
    self.isLegendary = false
end

function ItemLogEntry:draw(serviceViewport, timePassed)
    drawIconCommand:setCell(self.itemDef.icon)
    if self.discoverState == -1 then
        drawIconCommand.shader = SHADERS.SILHOUETTE
        drawIconCommand.color = COLORS.UNDISCOVERED_ITEM
    else
        if self.isLegendary then
            strokeCommand:setCell(self.itemDef.icon)
            strokeCommand.color = self.itemDef.legendaryMod:getLegendaryStrokeColor(self.itemDef)
            strokeCommand:draw(1 + MARGIN, 1 + MARGIN)
        end

        drawIconCommand.shader = false
        drawIconCommand.color = WHITE
    end

    drawIconCommand:draw(1 + MARGIN, 1 + MARGIN)
    if self.discoverState >= 10 then
        maxLevel:draw(MARGIN + MEASURES.ITEM_SIZE - 2, MARGIN + MEASURES.ITEM_SIZE - 2)
    end

    local borderColor
    if Utils.evaluate(self.isActivated, self, self.parent) then
        graphics.wSetColor(COLORS.LIST_SLOT_SELECTED)
    else
        graphics.wSetColor(COLORS.NORMAL:expandValues(self.input:getOpacity()))
    end

    DrawMethods.lineRect(self.rect)
end

return ItemLogEntry

