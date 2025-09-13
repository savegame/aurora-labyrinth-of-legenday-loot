local Range = class()
local Array = require("utils.classes.array")
function Range:initialize(minValue, maxValue)
    Utils.assert(minValue <= maxValue, "Range: Min value (%s) must be <= max value (%s)", tostring(minValue), tostring(maxValue))
    self.min, self.max = minValue, maxValue
end

function Range:size()
    return self.max - self.min + 1
end

function Range:at(key)
    if type(key) == "number" and key <= self:size() then
        return self.min + key - 1
    end

    return nil
end

function Range:indexOf(value)
    if value < self.min or value > self.max then
        return nil
    end

    return value - self.min + 1
end

function Range:contains(value)
    return value >= self.min and value <= self.max
end

function Range:bound(value)
    return bound(value, self.min, self.max)
end

function Range:average()
    return (self.min + self.max) / 2
end

function Range:toArray()
    local result = Array:new()
    for i = self.min, self.max do
        result:push(i)
    end

    return result
end

function Range:intersects(other)
    return (self:contains(other.min) or self:contains(other.max) or other:contains(self.min) or other:contains(self.max))
end

function Range:randomInteger(rng)
    rng = rng or DEFAULT_RNG
    return rng:random(self.min, self.max)
end

function Range:randomFloat(rng)
    rng = rng or DEFAULT_RNG
    return Utils.randomFloat(rng, self.min, self.max)
end

function Range:__mul(value)
    local result = self:clone()
    result.min = self.min * value
    result.max = self.max * value
    return result
end

function Range:round()
    local result = self:clone()
    result.min = round(self.min)
    result.max = round(self.max)
    return result
end

function Range:__tostring()
    return "[" .. tostring(self.min) .. ", " .. tostring(self.max) .. "]"
end

return Range

