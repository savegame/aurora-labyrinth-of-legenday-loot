local Lightning = class("effects.effect")
local Array = require("utils.classes.array")
local Vector = require("utils.classes.vector")
local Common = require("common")
local MEASURES = require("draw.measures")
local DEFAULT_COLOR = require("utils.classes.color"):new(1, 1, 0.5)
function Lightning:initialize(positionStart, positionEnd, isBeam)
    Lightning:super(self, "initialize")
    Utils.assert(positionStart and positionEnd, "Lighting: requires positionStart and positionEnd")
    self.color = DEFAULT_COLOR
    self.lineProgress = 0
    self.glowOpacity = 0
    self.positionEnd = positionEnd
    self:_createOffsets(positionStart, positionEnd, isBeam)
    self.angle = positionStart:angleTo(positionEnd)
    self.opacity = 1
    self.thickness = 2
    self.sideOffset = 0
end

function Lightning:_createOffsets(positionStart, positionEnd, isBeam)
    local length = ceil(positionStart:distance(positionEnd) * MEASURES.TILE_SIZE)
    self.offsets = Array:new()
    if isBeam then
        for i = 1, length do
            self.offsets:push(0)
        end

    else
        local currentOffsets = Array:new()
        for i = 1, floor((length - 1) / 3) do
            currentOffsets:pushMultiple(-1, 0, 1)
        end

                if (length - 1) % 3 == 1 then
            currentOffsets:push(0)
        elseif (length - 1) % 3 == 2 then
            currentOffsets:pushMultiple(-1, 1)
        end

        currentOffsets:shuffleSelf(Common.getMinorRNG())
        currentOffsets:push(0)
        local current = 0
        for i = 1, length do
            self.offsets:push(current)
            current = current + currentOffsets[i]
        end

    end

end

local CENTER = Vector:new(MEASURES.TILE_SIZE / 2, MEASURES.TILE_SIZE / 2)
function Lightning:draw(managerCoordinates)
    local length = self.offsets:size()
    local last = ceil(length * self.lineProgress)
    graphics.wSetColor(self.color)
    local positionEnd = managerCoordinates:gridToScreen(self.positionEnd) + CENTER
    graphics.push()
    graphics.translate(positionEnd.x, positionEnd.y)
    graphics.rotate(self.angle - math.tau / 4)
    for i = 1, last do
        local offset = self.offsets[i] + self.sideOffset
        local position = Vector:new(0, i - length)
        if self.glowOpacity > 0 then
            graphics.wSetColor(self.color:expandValues(self.color.a * self.opacity * self.glowOpacity * 0.15))
            graphics.wRectangle(position.x - self.thickness / 2 + offset - 2, position.y - 0.5, self.thickness + 4, 1)
            graphics.wSetColor(self.color:expandValues(self.color.a * self.opacity * self.glowOpacity * 0.5))
            graphics.wRectangle(position.x - self.thickness / 2 + offset - 1, position.y - 0.5, self.thickness + 2, 1)
        end

        graphics.wSetColor(self.color:expandValues(self.opacity))
        graphics.wRectangle(position.x - self.thickness / 2 + offset, position.y - 0.5, self.thickness, 1)
    end

    graphics.pop()
end

return Lightning

