math.tau = math.pi * 2
math.phi = (1 + math.sqrt(5)) / 2
math.sqrtOf2 = math.sqrt(2)
for k, v in pairs(math) do
    _G[k] = v
end

LEFT = 4
RIGHT = 6
BOTTOM = 2
TOP = 8
UP = TOP
DOWN = BOTTOM
DOWN_LEFT = 1
DOWN_RIGHT = 3
UP_LEFT = 7
UP_RIGHT = 9
CENTER = 5
Utils.clone = Object.clone
local Array = require("utils.classes.array")
local Set = require("utils.classes.set")
local Vector = require("utils.classes.vector")
local Range = require("utils.classes.range")
WHITE = require("utils.classes.color").WHITE
BLACK = require("utils.classes.color").BLACK
DIRECTIONS = Array:new(RIGHT, DOWN_RIGHT, DOWN, DOWN_LEFT, LEFT, UP_LEFT, UP, UP_RIGHT)
DIRECTIONS_AA = Array:new(RIGHT, DOWN, LEFT, UP)
DIRECTIONS_DIAGONAL = Array:new(DOWN_RIGHT, DOWN_LEFT, UP_LEFT, UP_RIGHT)
DEFAULT_RNG = { random = function(self, ...)
    return math.random(...)
end }
function string:split(separator)
    local separator, fields = separator or ":", Array:new()
    local pattern = string.format("([^%s]+)", separator)
    self:gsub(pattern, function(c)
        fields:push(c)
    end)
    return fields
end

function string:startsWith(other)
    return self:sub(1, #other) == other
end

function string:contains(p)
    return toBoolean(string.find(self, p, 1, true))
end

function string:trim()
    local starting = 1
    local ending = #self
    while starting <= ending and self:sub(starting, starting):match("%s") do
        starting = starting + 1
    end

    while ending > starting and self:sub(ending, ending):match("%s") do
        ending = ending - 1
    end

    return self:sub(starting, ending)
end

function reverseDirection(d)
    return 10 - d
end

function cwDirection(d, offset)
    offset = offset or 2
    return DIRECTIONS[modAdd(DIRECTIONS:indexOf(d), offset, DIRECTIONS:size())]
end

function ccwDirection(d, offset)
    offset = offset or 2
    return DIRECTIONS[modAdd(DIRECTIONS:indexOf(d), -offset, DIRECTIONS:size())]
end

function isDiagonal(d)
    return d % 2 > 0
end

function toBoolean(v)
    return (not (not v))
end

function choose(condition, a, b)
    if condition then
        return a
    end

    return b
end

function modAdd(value, addend, n)
    return (value - 1 + addend) % n + 1
end

function round(val, decimal)
    if type(decimal) == "number" then
        return floor((val * 10 ^ decimal) + 0.5) / (10 ^ decimal)
    else
        return floor(val + 0.5)
    end

end

function bound(value, minimum, maximum)
    return min(max(value, minimum), maximum)
end

function randomSigned(rng)
    rng = rng or DEFAULT_RNG
    return (random() * 2 - 1)
end

function within(value, minimum, maximum)
    if minimum > maximum then
        minimum, maximum = maximum, minimum
    end

    return value >= minimum and value <= maximum
end

function xor(a, b)
    return (toBoolean(a) == (not b))
end

function sign(x)
    return (x > 0 and 1) or (x < 0 and -1) or 0
end

function table.isEmpty(t)
    for key, value in pairs(t) do
        return false
    end

    return true
end

function table.size(t)
    local count = 0
    for key, value in pairs(t) do
        count = count + 1
    end

    return count
end

function table.assign(t, other)
    for key, value in pairs(other) do
        t[key] = value
    end

    return t
end

function table.getFirstKey(t)
    for key, value in pairs(t) do
        return key
    end

    return nil
end

function table.getFirstValue(t)
    for key, value in pairs(t) do
        return value
    end

    return nil
end

function table.getFirstKeyValue(t)
    for key, value in pairs(t) do
        return key, value
    end

    return nil, nil
end

function table.keys(t)
    local result = Array:new()
    for key, _ in pairs(t) do
        result:push(key)
    end

    return result
end

function table.values(t)
    local result = Array:new()
    for _, value in pairs(t) do
        result:push(value)
    end

    return result
end

function Utils.approachValue(sourceValue, targetValue, speed)
    if sourceValue >= targetValue then
        return max(sourceValue - speed, targetValue)
    else
        return min(sourceValue + speed, targetValue)
    end

end

function Utils.randomFloat(rng, minValue, maxValue)
    return rng:random() * (maxValue - minValue) + minValue
end

function Utils.digits(n)
    if n == math.huge then
        return 1
    end

    n = n - (n % 1)
    if n < 0 then
        return digits(-n) + 1
    end

    if n <= 1 then
        return 1
    end

    return floor(log10(n)) + 1
end

function Utils.angleDifference(a1, a2)
    a1, a2 = a1 % math.tau, a2 % math.tau
    local diff = a1 - a2
        if abs(diff) <= math.tau / 2 then
        return diff
    elseif diff < 0 then
        return diff + math.tau
    else
        return diff - math.tau
    end

end

function Utils.evaluate(value, rngOrArg1,...)
        if Range:isInstance(value) then
        if value.min % 1 > 0 or value.max % 1 > 0 then
            return Utils.randomFloat(rngOrArg1, value.min, value.max)
        end

        return rngOrArg1:random(value.min, value.max)
    elseif type(value) == "function" then
        return value(rngOrArg1, ...)
    end

    return value
end

function Utils.gridIterator(minX, maxX, minY, maxY)
    local ix, iy = minX - 1, minY
    return function()
        ix = ix + 1
        if ix > maxX then
            ix, iy = minX, iy + 1
        end

        if iy > maxY then
            return nil
        end

        return ix, iy
    end
end

function Utils.gridIteratorV(minX, maxX, minY, maxY)
    local ix, iy = minX - 1, minY
    return function()
        ix = ix + 1
        if ix > maxX then
            ix, iy = minX, iy + 1
        end

        if iy > maxY then
            return nil
        end

        return Vector:new(ix, iy)
    end
end

function Utils.reverseGridIteratorV(minX, maxX, minY, maxY)
    local ix, iy = maxX + 1, maxY
    return function()
        ix = ix - 1
        if ix < minX then
            ix, iy = maxX, iy - 1
        end

        if iy < minY then
            return nil
        end

        return Vector:new(ix, iy)
    end
end

function Utils.capitalizeFirst(name)
    local s, _ = name:gsub("^%l", string.upper)
    return s
end

function Utils.nDistinctRandom(n, iMin, iMax, rng)
    rng = rng or DEFAULT_RNG
    Utils.assert(iMax - iMin + 1 >= n, "nDistinctRandom: max (%d) - min (%d) + 1 should be >= than n (%d)", iMin, iMax, n)
    return Range:new(iMin, iMax):toArray():nDistinctRandom(n, rng)
end

function Utils.toXY(str, splitter)
    splitter = splitter or ","
    local x, y = str:match("([^" .. splitter .. "]+)" .. splitter .. "([^" .. splitter .. "]+)")
    return tonumber(x), tonumber(y)
end

function Utils.toXYV(str, splitter)
    return Vector:new(toXY(str, splitter))
end

function Utils.negateFunction(fn)
    return function(...)
        return not fn(...)
    end
end

function Utils.toString(t, levels, isKey, indent, tablesAdded)
    if type(t) ~= "table" then
        return choose((not isKey) and type(t) == "string", "\"" .. tostring(t) .. "\"", tostring(t))
    end

    local mt = getmetatable(t)
    if mt and rawget(mt, "__tostring") then
        return t:__tostring(tablesAdded)
    end

    local tablesAdded = tablesAdded or (Set:new())
    if tablesAdded:contains(t) then
        return "[circular: " .. tostring(t) .. "]"
    end

    if table.isEmpty(t) then
        return "{}"
    end

    tablesAdded:add(t)
    local indent = indent or 0
    local levels = levels or -1
    if levels == indent then
        return tostring(t)
    end

    local result = Array:new("{")
    result:push(choose(isKey, " ", "\n"))
    for k, v in pairs(t) do
        if not isKey then
            result:push(("    "):rep(indent + 1))
        end

        result:push(Utils.toString(k, levels, true, 0, tablesAdded))
        result:push(" = ")
        result:push(Utils.toString(v, levels, false, indent + 1, tablesAdded))
        result:push(",")
        result:push(choose(isKey, " ", "\n"))
    end

    result:pop()
    result:pop()
    result:push(choose(isKey, " ", "\n"))
    if not isKey then
        result:push(("    "):rep(indent))
    end

    result:push("}")
    return result:join()
end

local HEX_CHARACTERS = "0123456789abcdef"
Utils.HEX_PER_BYTE = 2
function Utils.randomHexString(rng, digits)
    local result = Array:new()
    for i = 1, digits do
        local index = rng:random(16)
        result:push(HEX_CHARACTERS:sub(index, index))
    end

    return result:join("")
end


