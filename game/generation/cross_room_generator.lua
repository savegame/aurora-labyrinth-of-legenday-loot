local CrossRoomGenerator = class()
local Array = require("utils.classes.array")
local Rect = require("utils.classes.rect")
local Room = require("generation.room")
function CrossRoomGenerator:initialize()
    self.widthRange = false
    self.heightRange = false
    self.nonCrossChance = 0.2
    self.nonCrossShorten = 1
    self.crossMinDimension = 4
    self.crossShorten = 2
end

function CrossRoomGenerator:generate(rng)
    local width = self.widthRange:randomInteger(rng)
    local height = self.heightRange:randomInteger(rng)
    if rng:random() < self.nonCrossChance then
        return Room:new(Array:new(Rect:new(1, 1, width - self.nonCrossShorten, height - self.nonCrossShorten)))
    else
        local longHeight = rng:random(self.crossMinDimension, height - self.crossShorten)
        local longRect = Rect:new(1, 1, width, longHeight)
        local tallWidth = rng:random(self.crossMinDimension, width - self.crossShorten)
        local tallRect = Rect:new(1, 1, tallWidth, height)
        if rng:random() < 0.5 then
            longRect.y = 1 + height - longRect.height
        end

        if rng:random() < 0.5 then
            tallRect.x = 1 + width - tallRect.width
        end

        return Room:new(Array:new(longRect, tallRect):shuffle(rng))
    end

end

return CrossRoomGenerator

