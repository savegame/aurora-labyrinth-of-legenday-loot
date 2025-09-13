local FeatureDef = class()
function FeatureDef:initialize(floors, minWidth, maxWidth, minHeight, maxHeight)
    self.minWidth = minWidth or 1
    self.maxWidth = maxWidth or self.minWidth
    self.minHeight = minHeight or 1
    self.maxHeight = maxHeight or self.maxHeight
    self.floors = floors
    self.fillCallback = doNothing
    self.roomRectMode = false
    self.maxOne = false
    self.isItemHolder = false
end

function FeatureDef:evaluateDimensions(rng)
    local width, height
    if self.maxWidth == math.huge then
        width = math.huge
    else
        width = rng:random(self.minWidth, self.maxWidth)
    end

    if self.maxHeight == math.huge then
        height = math.huge
    else
        height = rng:random(self.minHeight, self.maxHeight)
    end

    return width, height
end

return FeatureDef

