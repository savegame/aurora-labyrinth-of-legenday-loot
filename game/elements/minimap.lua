local Minimap = class("elements.element")
local SIZE = require("draw.measures").MINIMAP_SIZE
local MINIMAP_COLORS = require("draw.colors").MINIMAP
local Common = require("common")
function Minimap:initialize(level, vision, systemIndicator)
    Minimap:super(self, "initialize")
    self._level = level
    self._vision = vision
    self._systemIndicator = systemIndicator
    self.canvas = graphics.newCanvas(level:getDimensions())
    self:refreshCanvas()
end

function Minimap:refreshCanvas()
    graphics.setCanvas(self.canvas)
    graphics.push()
    graphics.clear(0, 0, 0, 0)
    graphics.origin()
    for position, isExplored in self._vision.explored:denseIterator() do
        if isExplored then
            local tile = self._level.tiles:get(position)
                        if tile.isBlocking then
                graphics.wSetColor(MINIMAP_COLORS:get("WALL"))
            elseif tile.isRoom then
                graphics.wSetColor(MINIMAP_COLORS:get("ROOM"))
            else
                graphics.wSetColor(MINIMAP_COLORS:get("FLOOR"))
            end

            graphics.wRectangle(position.x - 1, position.y - 1, 1, 1)
        end

    end

    graphics.pop()
    graphics.setCanvas()
end

function Minimap:draw()
    graphics.push()
    graphics.scale(SIZE)
    graphics.draw(self.canvas)
    for entity in self._systemIndicator.entities() do
        if not entity.indicator.removedFromGrid then
            local position = Common.getPositionComponent(entity):getPosition()
            if self._vision:isExplored(position) then
                local color = entity.indicator.color
                if color ~= "ENEMY" or self._vision:isVisible(position) then
                    graphics.wSetColor(MINIMAP_COLORS:get(color))
                    graphics.wRectangle(position.x - 1, position.y - 1, 1, 1)
                end

            end

        end

    end

    graphics.pop()
end

return Minimap

