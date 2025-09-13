local Explosion = class("effects.effect")
local Array = require("utils.classes.array")
local Vector = require("utils.classes.vector")
local Color = require("utils.classes.color")
local MEASURES = require("draw.measures")
local Common = require("common")
local COLOR_1 = Color:new(1, 0.3, 0.3)
local COLOR_2 = Color:new(1, 0.7, 0.3)
local COLOR_3 = Color:new(1, 1, 0.7)
function Explosion:initialize()
    Explosion:super(self, "initialize")
    self.progress = 0
    self.position = false
    self.opacity = 1
    self.eraserProgress = 0
    self.color1 = COLOR_1
    self.color2 = COLOR_2
    self.color3 = COLOR_3
    self.size = 18
    self.extraExclude = false
end

function Explosion:setHue(degrees)
    self.color1 = COLOR_1:hueShift(degrees)
    self.color2 = COLOR_2:hueShift(degrees)
    self.color3 = COLOR_3:hueShift(degrees)
end

function Explosion:multiplyColor(value)
    self.color1 = Color:new(self.color1.r * value, self.color1.g * value, self.color1.b * value)
    self.color2 = Color:new(self.color2.r * value, self.color2.g * value, self.color2.b * value)
    self.color3 = Color:new(self.color3.r * value, self.color3.g * value, self.color3.b * value)
end

function Explosion:desaturate(value)
    self.color1 = COLOR_1:desaturate(value)
    self.color2 = COLOR_2:desaturate(value)
    self.color3 = COLOR_3:desaturate(value)
end

local CENTER = Vector:new(MEASURES.TILE_SIZE / 2, MEASURES.TILE_SIZE / 2)
local PROGRESS_BEFORE_ERASER = 0.5
function Explosion:draw(managerCoordinates)
    Utils.assert(self.position, "Explosion requires position")
    local position = managerCoordinates:gridToScreen(self.position) + CENTER
    local hasStencil = false
    if self.eraserProgress > 0 or self.extraExclude then
        hasStencil = true
        Utils.stencilExclude(function()
            if self.eraserProgress > 0 then
                graphics.wCircle(position, self.eraserProgress * self.size)
            end

            if self.extraExclude then
                self.extraExclude(position, self.size)
            end

        end)
    end

    graphics.wSetColor(self.color1:expandValues(self.opacity))
    graphics.wCircle(position, (self.progress) * self.size)
    graphics.wSetColor(self.color2:expandValues(self.opacity))
    graphics.wCircle(position, (self.progress) * self.size * 0.8)
    graphics.wSetColor(self.color3:expandValues(self.opacity))
    graphics.wCircle(position, (self.progress) * self.size * 0.6)
    if hasStencil then
        Utils.stencilDisable()
    end

end

return Explosion

