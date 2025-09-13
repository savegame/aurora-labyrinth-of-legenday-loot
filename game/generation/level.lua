local GenerationLevel = class()
local Array = require("utils.classes.array")
local Hash = require("utils.classes.hash")
local Vector = require("utils.classes.vector")
local SparseGrid = require("utils.classes.sparse_grid")
local LevelObject = struct("name", "args")
function GenerationLevel:initialize(defaultTile, width, height)
    self.tiles = SparseGrid:new(defaultTile, width, height)
    self._objects = false
    self.startPosition = Vector.UNIT_XY
    self.startDirection = LEFT
    self.hallPositions = Array:new()
    self.objectPositions = false
end

function GenerationLevel:initializeObjects()
    self._objects = SparseGrid:new(false, self.tiles.width, self.tiles.height)
end

function GenerationLevel:getObjects()
    return self._objects
end

function GenerationLevel:saveHallPositions(tileHall)
    for position, tile in self.tiles:denseIterator() do
        if tile == tileHall then
            self.hallPositions:push(position)
        end

    end

end

function GenerationLevel:setObject(position, name,...)
    self._objects:set(position, LevelObject:new(name, Array:new(...)))
end

function GenerationLevel:deleteObject(position)
    self._objects:delete(position)
end

function GenerationLevel:getDimensions()
    return self.tiles:getDimensions()
end

function GenerationLevel:getWidth()
    return self.tiles.width
end

function GenerationLevel:getHeight()
    return self.tiles.height
end

function GenerationLevel:pad(amount, value)
    if not value then
        value = self.tiles:get(Vector.UNIT_XY)
    end

    self.tiles:pad(amount, value)
    if self._objects then
        self._objects:pad(amount)
    end

end

function GenerationLevel:isPassable(position)
    if not self.tiles:within(position) then
        return false
    end

    local tile = self.tiles:get(position)
    return not tile.isBlocking
end

function GenerationLevel:isAllBlocking(rect)
    for position in rect:gridIteratorV() do
        local tile = self.tiles:get(position)
        if not tile.isBlocking then
            return false
        end

    end

    return true
end

function GenerationLevel:within(position)
    return self.tiles:within(position)
end

return GenerationLevel

