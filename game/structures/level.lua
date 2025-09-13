local Level = class()
function Level:initialize(generationLevel)
    self.tiles = generationLevel.tiles
    self.hallPositions = generationLevel.hallPositions
end

function Level:isPassable(position)
    if not self.tiles:within(position) then
        return false
    end

    local tile = self.tiles:get(position)
    return not tile.isBlocking
end

function Level:getDimensions()
    return self.tiles:getDimensions()
end

return Level

