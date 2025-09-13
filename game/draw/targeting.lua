local TILE_SIZE = require("draw.measures").TILE_SIZE
local COLORS = require("draw.colors")
return function(mousePosition, managerCoordinates)
    local gridPosition = managerCoordinates:screenToGrid(mousePosition)
    local lattice = managerCoordinates:gridToScreen(gridPosition)
    graphics.wSetColor(COLORS.TARGETING_NORMAL)
    local image = Utils.loadImage("targeting")
    local sw, sh = image:getDimensions()
    graphics.draw(Utils.loadImage("targeting"), lattice.x - (sw - TILE_SIZE) / 2, lattice.y - (sh - TILE_SIZE) / 2)
end

