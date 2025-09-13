local Coordinates = class("services.service")
local TILE_SIZE = require("draw.measures").TILE_SIZE
local VISIBLE_ALLOWANCE = TILE_SIZE
local Vector = require("utils.classes.vector")
local Rect = require("utils.classes.rect")
function Coordinates:initialize(viewport)
    Coordinates:super(self, "initialize")
    self.center = Vector.ORIGIN
    self:setDependencies("effects", "viewport")
    self.gridToScreenAdd = Vector.ORIGIN
end

function Coordinates:gridToScreen(gridPosition)
    return self.services.viewport:toNearestScale(gridPosition * TILE_SIZE + self.gridToScreenAdd)
end

function Coordinates:cacheGridToScreen()
    self.gridToScreenAdd = self.services.viewport:getCenter() - (self.center + Vector.UNIT_XY / 2) * TILE_SIZE + self.services.effects.screenOffset
end

function Coordinates:gridToScreenRect(rect)
    local position = self:gridToScreen(rect:getPosition())
    return Rect:new(position.x, position.y, rect.width * TILE_SIZE, rect.height * TILE_SIZE)
end

function Coordinates:screenToGrid(screenPosition)
    local posAtCorner = (screenPosition - self.services.viewport:getCenter()) / TILE_SIZE
    return (posAtCorner + self.center + Vector.UNIT_XY / 2):floorXY()
end

function Coordinates:getLatticeForScreen(screenPosition)
    return self:gridToScreen(self:screenToGrid(screenPosition))
end

function Coordinates:isTileWithinScreen(position)
    local scW, scH = self.services.viewport:getScreenDimensions()
    local topLeft = self:gridToScreen(position)
    if topLeft.x + TILE_SIZE > -VISIBLE_ALLOWANCE and topLeft.x < scW + VISIBLE_ALLOWANCE then
        if topLeft.y + TILE_SIZE > -VISIBLE_ALLOWANCE and topLeft.y < scH + VISIBLE_ALLOWANCE then
            return true
        end

    end

    return false
end

function Coordinates:getTileWithinScreenChecker()
    if not PortSettings.IS_MOBILE then
        return function(position)
            return self:isTileWithinScreen(position)
        end
    else
        local scW, scH = self.services.viewport:getScreenDimensions()
        local toAddX = self.gridToScreenAdd.x
        local toAddY = self.gridToScreenAdd.y
        return function(position)
            local tx = position.x * TILE_SIZE + toAddX
            local ty = position.y * TILE_SIZE + toAddY
            if tx + TILE_SIZE > -VISIBLE_ALLOWANCE and tx < scW + VISIBLE_ALLOWANCE then
                if ty + TILE_SIZE > -VISIBLE_ALLOWANCE and ty < scH + VISIBLE_ALLOWANCE then
                    return true
                end

            end

        end
    end

end

function Coordinates:getScreenBounds()
    local scW, scH = self.services.viewport:getScreenDimensions()
    local minPosition = self:screenToGrid(Vector:new(0, 0))
    local maxPosition = self:screenToGrid(Vector:new(scW, scH))
    return Rect:new(minPosition.x, minPosition.y, maxPosition.x - minPosition.x + 1, maxPosition.y - minPosition.y + 1)
end

return Coordinates

