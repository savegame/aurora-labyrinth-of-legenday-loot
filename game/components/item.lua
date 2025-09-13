local Item = require("components.create_class")()
local Vector = require("utils.classes.vector")
local Set = require("utils.classes.set")
local DrawCommand = require("utils.love2d.draw_command")
local MEASURES = require("draw.measures")
local EASING = require("draw.easing")
local COLORS = require("draw.colors")
local Common = require("common")
local TILE_SIZE, ITEM_SIZE = MEASURES.TILE_SIZE, MEASURES.ITEM_SIZE
local OFFSET = Vector.UNIT_XY * (TILE_SIZE - ITEM_SIZE) / 2
local STROKE_OFFSET = Vector.UNIT_XY * (TILE_SIZE - ITEM_SIZE - 2) / 2
function Item:initialize(entity, item)
    Item:super(self, "initialize")
    self._entity = entity
    self.positionSource = Common.getPositionComponent(entity)
    self.item = item
    self.opacity = 1
    entity:callIfHasComponent("serializable", "addComponent", "item")
end

function Item:toData(convertToData)
    return { item = convertToData(self.item) }
end

function Item:fromData(data, convertFromData)
    self.item = convertFromData(data.item)
end

local BOUNCE_HEIGHT = 0.4
local BOUNCE_NEXT = 0.6
local BOUNCE_DURATION = 0.33
function Item:startBounceEvent()
    local offset = self._entity.offset:createProfile()
    local currentEvent = self.system.services.parallelscheduler:createEvent()
    local currentHeight = BOUNCE_HEIGHT
    local currentDuration = BOUNCE_DURATION
    local isFirst = true
    while currentHeight >= BOUNCE_HEIGHT / 20 do
        local thisHeight = currentHeight
        currentEvent = currentEvent:chainProgress(currentDuration, function(progress)
            offset.jump = EASING.PARABOLIC_HEIGHT(progress) * thisHeight
        end)
        if isFirst then
            currentEvent:chainEvent(function()
                Common.playSFX("ORB_DROP")
            end)
            isFirst = false
        end

        currentHeight = currentHeight * BOUNCE_NEXT
        currentDuration = currentDuration * BOUNCE_NEXT
    end

    return currentEvent
end

function Item:getIcon()
    if Vector:isInstance(self.item) then
        return self.item
    else
        return self.item:getIcon()
    end

end

function Item:getStrokeColor()
    if Vector:isInstance(self.item) then
        return false
    else
        return self.item:getStrokeColor()
    end

end

function Item:getDisplayPosition()
    local position = self.positionSource:getPosition()
    if self._entity:hasComponent("offset") then
        position = position + self._entity.offset:getTotal()
    end

    return position
end

function Item.System:initialize()
    Item.System:super(self, "initialize")
    self.storageClass = Set
    self:setDependencies("coordinates", "parallelscheduler")
end

function Item.System:draw()
    local drawCommand = DrawCommand:new("items")
    drawCommand.rect:setDimensions(ITEM_SIZE, ITEM_SIZE)
    graphics.wSetColor(WHITE)
    local coordinates = self.services.coordinates
    for entity in self.entities() do
        local position = entity.item:getDisplayPosition()
        if coordinates:isTileWithinScreen(position) then
            local icon = entity.item:getIcon()
            drawCommand:setCell(icon)
            drawCommand.opacity = entity.item.opacity
            drawCommand.position = coordinates:gridToScreen(position) + OFFSET
            drawCommand:draw()
            local strokeColor = entity.item:getStrokeColor()
            if strokeColor then
                local drawCommand = DrawCommand:new("items_stroke")
                drawCommand.rect:setDimensions(ITEM_SIZE + 2, ITEM_SIZE + 2)
                drawCommand:setCell(icon)
                drawCommand.color = strokeColor
                drawCommand.opacity = entity.item.opacity
                drawCommand.position = coordinates:gridToScreen(position) + STROKE_OFFSET
                drawCommand:draw()
            end

        end

    end

end

return Item

