local HexGrid = class()
local Array = require("utils.classes.array")
local Hash = require("utils.classes.hash")
HexGrid.DIRECTIONS_VERTICAL = Hash:new({ [RIGHT] = Vector:new(2, 0), [UP_RIGHT] = Vector:new(1, -1), [UP_LEFT] = Vector:new(-1, -1), [LEFT] = Vector:new(-2, 0), [DOWN_LEFT] = Vector:new(-1, 1), [DOWN_RIGHT] = Vector:new(1, 1) })
HexGrid.DIRECTIONS_HORIZONTAL = Hash:new({ [UP_RIGHT] = Vector:new(1, -1), [UP] = Vector:new(-1, -1), [UP_LEFT] = Vector:new(-2, 0), [DOWN_LEFT] = Vector:new(-1, 1), [DOWN] = Vector:new(1, 1), [DOWN_RIGHT] = Vector:new(2, 0) })
HexGrid.DIR_ORDER_HORIZ = Array:new(UP_RIGHT, UP, UP_LEFT, DOWN_LEFT, DOWN, DOWN_RIGHT)
HexGrid.DIR_ORDER_VERT = Array:new(RIGHT, UP_RIGHT, UP_LEFT, LEFT, DOWN_LEFT, DOWN_RIGHT)
local DEFAULT_MAX_VALUE = 16384
function HexGrid:initialize(default, radius)
    self.container = {  }
    self.default = default
    self.radius = radius
    self.maxValue = maxValue or DEFAULT_MAX_VALUE
end

function HexGrid:hash(position)
    return position.y * self.maxValue * 2 + position.x
end

function HexGrid:unhash(value)
    local x, y = value % (self.maxValue * 2), floor(value / (self.maxValue * 2))
    if x > self.maxValue then
        x = x - self.maxValue * 2
        y = y + 1
    end

    return Vector:new(x, y)
end

function HexGrid:isPositionValid(position)
    if abs(position.x) + abs(position.y) > self.radius * 2 then
        return false
    end

    if abs(position.y) > self.radius then
        return false
    end

    return position.x % 2 == position.y % 2
end

function HexGrid:set(position, value)
    if not self:isPositionValid(position) then
        return 
    end

    if value == self.default then
        value = nil
    end

    self.container[self:hash(position)] = value
end

function HexGrid:get(position)
    if not self:isPositionValid(position) then
        return self.default
    end

    local value = self.container[self:hash(position)]
    if value == nil then
        return self.default
    end

    return value
end

function HexGrid:__call()
    local keys = Array:new()
    for key, value in pairs(self.container) do
        if value ~= self.default then
            keys:push(self:unhash(key))
        end

    end

    local i = 0
    return function()
        i = i + 1
        if i > keys.n then
            return nil
        end

        return keys[i], self:get(keys[i])
    end
end

function HexGrid:denseIterator()
    local distance = 0
    local i = 0
    return function()
        if distance == 0 then
            distance = 1
            return Vector.ORIGIN, self:get(Vector.ORIGIN)
        else
            i = i + 1
            if i > distance * 6 then
                distance = distance + 1
                i = 1
            end

            if distance > self.radius then
                return nil
            end

            local refIndex = floor((i - 1) / distance) + 1
            local movementIndex = modAdd(refIndex, 2, 6)
            local ref = HexGrid.DIRECTIONS_VERTICAL:get(HexGrid.DIR_ORDER_VERT[refIndex]) * distance
            local offset = (i - 1) % distance
            local movement = HexGrid.DIRECTIONS_VERTICAL:get(HexGrid.DIR_ORDER_VERT[movementIndex]) * offset
            local position = ref + movement
            return position, self:get(position)
        end

    end
end

return HexGrid

