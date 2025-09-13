local Color = class()
local Array = require("utils.classes.array")
local VALUES = { "r", "g", "b" }
function Color:initialize(r, g, b, a)
    self.r = r
    self.g = g
    self.b = b
    self.a = a or 1
end

function Color:__tostring()
    return "(" .. self.r .. "," .. self.g .. "," .. self.b .. "," .. self.a .. ")"
end

function Color:expand()
    return self.r, self.g, self.b, self.a
end

function Color:expandValues(alpha)
    if alpha then
        return self.r, self.g, self.b, alpha
    end

    return self.r, self.g, self.b
end

function Color:withAlpha(alpha)
    return Color:new(self.r, self.g, self.b, alpha)
end

function Color:withAlphaMultiplied(alpha)
    return Color:new(self.r, self.g, self.b, self.a * alpha)
end

function Color:blend(other, value, includeAlpha)
    Utils.assert(value <= 1.5, "Colors should be in range 0-1")
    local r = (self.r * (1 - value) + other.r * value)
    local g = (self.g * (1 - value) + other.g * value)
    local b = (self.b * (1 - value) + other.b * value)
    local a = 1
    if includeAlpha then
        a = (self.a * (1 - value) + other.a * value)
    end

    return Color:new(r, g, b, a)
end

function Color:hueShift(degrees)
    local newColor = Color:new(self.r, self.g, self.b, self.a)
    for i = 1, floor((degrees % 360) / 120) do
        newColor.r, newColor.g, newColor.b = newColor.b, newColor.r, newColor.g
    end

    local minValue, maxValue = min(newColor.r, newColor.g, newColor.b), max(newColor.r, newColor.g, newColor.b)
    local values = Array:new(newColor.r, newColor.g, newColor.b):stableSortSelf()
    local rem = (degrees % 120) / 120
    local newR = rem * newColor.b + (1 - rem) * newColor.r
    local newG = rem * newColor.r + (1 - rem) * newColor.g
    local newB = rem * newColor.g + (1 - rem) * newColor.b
    newColor.r, newColor.g, newColor.b = newR, newG, newB
    local newMin, newMax = min(newColor.r, newColor.g, newColor.b), max(newColor.r, newColor.g, newColor.b)
    if newMax == newMin then
        return Color:new(maxValue, maxValue, maxValue, self.a)
    end

    for _, value in ipairs(VALUES) do
        local normalized = bound((newColor[value] - newMin) / (newMax - newMin), 0, 1)
        newColor[value] = normalized * (maxValue - minValue) + minValue
    end

    return newColor
end

function Color:desaturate(coefficient)
    Utils.assert(coefficient <= 1.5, "Colors should be in range 0-1")
    coefficient = coefficient or 0.5
    local minValue, maxValue = min(self.r, self.g, self.b), max(self.r, self.g, self.b)
    local value = (maxValue - minValue) * coefficient + minValue
    return Color:new(value, value, value, self.a)
end

function Color:__eq(other)
    return ((self.r == other.r) and (self.g == other.g) and (self.b == other.b) and (self.a == other.a))
end

Color.WHITE = Color:new(1, 1, 1)
Color.SILVER = Color:new(0.75, 0.75, 0.75)
Color.GRAY = Color:new(0.5, 0.5, 0.5)
Color.BLACK = Color:new(0, 0, 0)
Color.RED = Color:new(1, 0, 0)
Color.MAROON = Color:new(0.5, 0, 0)
Color.YELLOW = Color:new(1, 1, 0)
Color.OLIVE = Color:new(0.5, 0.5, 0)
Color.LIME = Color:new(0, 1, 0)
Color.GREEN = Color:new(0, 0.5, 0)
Color.CYAN = Color:new(0, 1, 1)
Color.TEAL = Color:new(0, 0.5, 0.5)
Color.BLUE = Color:new(0, 0, 1)
Color.NAVY = Color:new(0, 0, 0.5)
Color.MAGENTA = Color:new(1, 0, 1)
Color.TRANSPARENT = Color:new(0, 0, 0, 0)
return Color

