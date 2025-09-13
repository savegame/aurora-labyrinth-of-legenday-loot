local Damage = class("effects.effect")
local COLORS = require("draw.colors")
local FONT = require("draw.fonts").MEDIUM_BOLD
local DrawText = require("draw.text")
local Vector = require("utils.classes.vector")
local V_HALF = Vector.UNIT_XY / 2
local MAX_HEIGHT = 16
local MAX_WIDTH = 16
local DAMAGE_DURATION = 0.525
function Damage:initialize(value, color)
    Damage:super(self, "initialize")
    self.position = false
    self.progress = 0
    self.value = tostring(abs(value))
    self.negative = value < 0
    self.layer = Tags.LAYER_DAMAGE
    self.color = color or COLORS.NORMAL
    self.xDirection = 0
end

function Damage:draw(managerCoordinates)
    Utils.assert(self.position, "Damage requires #position")
    if self.progress > 0.5 then
        graphics.wSetColor(self.color:expandValues(1 - (self.progress - 0.5) * 2))
    else
        graphics.wSetColor(self.color)
    end

    graphics.wSetFont(FONT)
    local xOffset, yOffset = 0, 0
        if not self.negative then
        local v2 = 2 * (self.progress - 0.5)
        yOffset = (v2 * v2 - 1) * MAX_HEIGHT
        xOffset = self.xDirection * MAX_WIDTH * self.progress
    elseif self.negative then
        yOffset = -self.progress * MAX_HEIGHT
    end

    local position = self.position
    if not Vector:isInstance(position) then
        position = position:getDisplayPosition()
    end

    local screenPos = managerCoordinates:gridToScreen(position + V_HALF)
    DrawText.drawStroked(self.value, screenPos.x - FONT:getStrokedWidth(self.value) / 2 + xOffset, screenPos.y - FONT:getStrokedHeight() / 2 + yOffset)
end

function Damage:update(dt)
    self.progress = self.progress + dt / DAMAGE_DURATION
    if self.progress >= 1 then
        self.progress = 1
        self:delete()
    end

end

return Damage

