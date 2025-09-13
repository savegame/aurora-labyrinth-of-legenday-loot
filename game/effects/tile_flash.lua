local TileFlash = class("effects.effect")
local COLOR = require("draw.colors").TILE_FLASH
local TILE_SIZE = require("draw.measures").TILE_SIZE
local DURATION = require("actions.constants").NEGATIVE_FADE_DURATION
local SIZE_ADJUST = 0
function TileFlash:initialize(position)
    TileFlash:super(self, "initialize")
    self.layer = Tags.LAYER_EFFECT_BELOW_CHARACTERS
    self.position = position or false
    self.opacity = 1
    self.color = COLOR
end

function TileFlash:draw(managerCoordinates)
    Utils.assert(self.position, "Tile Flash requires #position")
    graphics.wSetColor(self.color:withAlphaMultiplied(self.opacity))
    local position = managerCoordinates:gridToScreen(self.position)
    graphics.wRectangle(position.x + SIZE_ADJUST, position.y + SIZE_ADJUST, TILE_SIZE - SIZE_ADJUST * 2, TILE_SIZE - SIZE_ADJUST * 2)
end

function TileFlash:update(dt)
    self.opacity = self.opacity - dt / DURATION
    if self.opacity <= 0 then
        self.opacity = 0
        self:delete()
    end

end

return TileFlash

