local GenerationDisplay = class("services.service")
local Color = require("utils.classes.color")
local Vector = require("utils.classes.vector")
local TILES = require("definitions.tiles")
local TILE_COLOR_HALL = Color:new(0.32, 0.32, 0.27)
local TILE_COLOR_ROOM = Color:new(0.43, 0.3, 0.2)
local TILE_COLOR_WALL = Color:new(0.22, 0.19, 0.13)
local TILE_COLOR_DEBUG = Color:new(1, 0.25, 0.25)
local OBJECT_COLOR = Color:new(0.5, 1, 0.5, 0.5)
function GenerationDisplay:initialize()
    GenerationDisplay:super(self, "initialize")
    self:setDependencies("level", "viewport")
end

function GenerationDisplay:draw()
    local scW, scH = self.services.viewport:getScreenDimensions()
    local level = self.services.level
    local levelWidth, levelHeight = level:getDimensions()
    local tileSize = min(floor(scW / (levelWidth + 2)), floor(scH / (levelHeight + 2)))
    local starting = Vector:new((scW - tileSize * levelWidth) / 2, (scH - tileSize * levelHeight) / 2)
    for position, tile in level.tiles:denseIterator() do
        local color
                        if tile == TILES.DEBUG_1 then
            color = TILE_COLOR_DEBUG
        elseif tile.isRoom then
            color = TILE_COLOR_ROOM
        elseif tile.isBlocking then
            color = TILE_COLOR_WALL
        else
            color = TILE_COLOR_HALL
        end

        graphics.wSetColor(color)
        local drawPosition = starting + (position - Vector.UNIT_XY) * tileSize
        graphics.wRectangle(drawPosition.x, drawPosition.y, tileSize - 1, tileSize - 1)
        local objects = level:getObjects()
        if objects and objects:get(position) then
            graphics.wSetColor(OBJECT_COLOR)
            graphics.wRectangle(drawPosition.x, drawPosition.y, tileSize - 1, tileSize - 1)
        end

    end

end

return GenerationDisplay

