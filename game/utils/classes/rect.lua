local Rect = class()
local Vector = require("utils.classes.vector")
function Rect:initialize(x, y, width, height)
        if type(x) == "table" then
        x, y, width, height = x.x, x.y, x.width, x.height
    elseif not width then
        x, y, width, height = 0, 0, x, y
    end

    self:set(x or 0, y or 0, width or 1, height or 1)
end

function Rect:set(x, y, width, height)
    self.x, self.y, self.width, self.height = x, y, width, height
end

function Rect:contains(x, y)
    if type(x) == "table" then
        x, y = x.x, x.y
    end

    return self:containsX(x) and self:containsY(y)
end

function Rect:containsX(x)
    return (x >= self.x and x < self.x + self.width)
end

function Rect:containsY(y)
    return (y >= self.y and y < self.y + self.height)
end

function Rect:containsRect(x, y, width, height)
    if type(x) == "table" then
        x, y, width, height = x.x, x.y, x.width, x.height
    end

    if not self:contains(x, y) then
        return false
    end

    return x + width <= self.x + self.width and y + height <= self.y + self.height
end

function Rect:collidesWith(x, y, width, height)
    if type(x) == "table" then
        x, y, width, height = x.x, x.y, x.width, x.height
    end

    return (self.x < x + width and x < self.x + self.width and self.y < y + height and y < self.y + self.height)
end

function Rect:getIntersection(otherRect)
    if not self:collidesWith(otherRect) then
        return false
    end

    local left, top = max(self.x, otherRect.x), max(self.y, otherRect.y)
    local right, bottom = min(self:right(), otherRect:right()), min(self:bottom(), otherRect:bottom())
    return Rect:new(left, top, right - left, bottom - top)
end

function Rect:right()
    return self.x + self.width
end

function Rect:bottom()
    return self.y + self.height
end

function Rect:setRight(value)
    self.x = value - self.width
end

function Rect:setBottom(value)
    self.y = value - self.height
end

function Rect:center()
    return Vector:new(self.x + self.width / 2, self.y + self.height / 2)
end

function Rect:discreteCenter()
    return Vector:new(self.x + (self.width - 1) / 2, self.y + (self.height - 1) / 2)
end

function Rect:intersectsSegment(sx1, sy1, sx2, sy2)
    local rMaxX, rMaxY = Rect.right(self), Rect.bottom(self)
    local minX, maxX = minMax(sx1, sx2)
    if maxX > rMaxX then
        maxX = rMaxX
    end

    if minX < self.x then
        minX = self.x
    end

    if minX > maxX then
        return false
    end

    local minY, maxY = sy1, sy2
    local dx = sx2 - sx1
    if abs(dx) > 0.0001 then
        local m = (sy2 - sy1) / dx
        local b = sy1 - m * sx1
        minY = m * minX + b
        maxY = m * maxX + b
    end

    minY, maxY = minMax(minY, maxY)
    if maxY > rMaxY then
        maxY = rMaxY
    end

    if minY < self.y then
        minY = self.y
    end

    return minY <= maxY
end

function Rect:iterateSide(direction)
    local x, y = self.x, self.y
    if (direction == UP) or (direction == DOWN) then
        local ix, iy = x - 1, choose(direction == UP, y, y + self.height - 1)
        return function()
            ix = ix + 1
            if ix > x + self.width - 1 then
                return nil
            end

            return Vector:new(ix, iy)
        end
    else
        local iy, ix = y - 1, choose(direction == LEFT, x, x + self.width - 1)
        return function()
            iy = iy + 1
            if iy > y + self.height - 1 then
                return nil
            end

            return Vector:new(ix, iy)
        end
    end

end

function Rect:getSideRect(direction)
                if direction == RIGHT then
        return Rect:new(self.x + self.width - 1, self.y, 1, self.height)
    elseif direction == DOWN then
        return Rect:new(self.x, self.y + self.height - 1, self.width, 1)
    elseif direction == UP then
        return Rect:new(self.x, self.y, self.width, 1)
    elseif direction == LEFT then
        return Rect:new(self.x, self.y, 1, self.height)
    else
        return nil
    end

end

function Rect:getCorner(direction)
                if direction == DOWN_RIGHT then
        return Vector:new(self.x + self.width - 1, self.y + self.height - 1)
    elseif direction == DOWN_LEFT then
        return Vector:new(self.x, self.y + self.height - 1)
    elseif direction == UP_LEFT then
        return Vector:new(self.x, self.y)
    elseif direction == UP_RIGHT then
        return Vector:new(self.x + self.width - 1, self.y)
    else
        return nil
    end

end

function Rect:gridIterator()
    local x, y = self.x - 1, self.y
    return function()
        x = x + 1
        if x >= self.x + self.width then
            y = y + 1
            x = self.x
        end

        if y >= self.y + self.height then
            return nil
        end

        return x, y
    end
end

function Rect:gridIteratorV()
    local x, y = self.x - 1, self.y
    return function()
        x = x + 1
        if x >= self.x + self.width then
            y = y + 1
            x = self.x
        end

        if y >= self.y + self.height then
            return nil
        end

        return Vector:new(x, y)
    end
end

function Rect:growDirectionSelf(direction, value)
    value = value or 1
    if direction == RIGHT or direction == UP_RIGHT or direction == DOWN_RIGHT then
        self.width = self.width + value
    end

    if direction == DOWN or direction == DOWN_RIGHT or direction == DOWN_LEFT then
        self.height = self.height + value
    end

    if direction == LEFT or direction == DOWN_LEFT or direction == UP_LEFT then
        self.x = self.x - value
        self.width = self.width + value
    end

    if direction == UP or direction == UP_LEFT or direction == UP_RIGHT then
        self.y = self.y - value
        self.height = self.height + value
    end

    return self
end

function Rect:growDirection(direction, value)
    local result = self:clone()
    result:growDirectionSelf(direction, value)
    return result
end

function Rect:growVector(vector)
    local rect = self:clone()
    rect.width = rect.width + abs(vector.x)
    rect.height = rect.height + abs(vector.y)
    if vector.x < 0 then
        rect.x = rect.x + vector.x
    end

    if vector.y < 0 then
        rect.y = rect.y + vector.y
    end

    return rect
end

function Rect:expand()
    return self.x, self.y, self.width, self.height
end

function Rect:setPosition(x, y)
    if type(x) == "table" then
        self.x, self.y = x.x, x.y
    else
        self.x, self.y = x, y
    end

end

function Rect:setDimensions(width, height)
    if type(width) == "table" then
        self.width, self.height = width.width, width.height
    else
        self.width, self.height = width, height
    end

end

function Rect:getPosition()
    return Vector:new(self.x, self.y)
end

function Rect:getDimensions()
    return self.width, self.height
end

function Rect:fixDimensions()
    if self.width < 0 then
        self.x = self.x + self.width
        self.width = abs(self.width)
    end

    if self.height < 0 then
        self.y = self.y + self.height
        self.height = abs(self.height)
    end

end

function Rect:moveSelf(direction, distance)
    distance = distance or 1
    self:setPosition((Vector:new(self.x, self.y) + Vector[direction] * distance):expand())
    return self
end

function Rect:move(direction, distance)
    local result = self:clone()
    result:moveSelf(direction, distance)
    return result
end

function Rect:scaleSelf(value)
    self:set(self.x * value, self.y * value, self.width * value, self.height * value)
    return self
end

function Rect:scale(value)
    local result = self:clone()
    result:scaleSelf()
    return result
end

function Rect:translateSelf(offset)
    self:setPosition(self:getPosition() + offset)
end

function Rect:translated(offset)
    local result = self:clone()
    result:translateSelf(offset)
    return result
end

function Rect:sizeAdjusted(value)
    return Rect:new(self.x - value, self.y - value, self.width + value * 2, self.height + value * 2)
end

function Rect:horizontalAdjusted(value)
    return Rect:new(self.x - value, self.y, self.width + value * 2, self.height)
end

function Rect:verticalAdjusted(value)
    return Rect:new(self.x, self.y - value, self.width, self.height + value * 2)
end

function Rect:__tostring()
    return ("(%s, %s, %s, %s)"):format(self.x, self.y, self.width, self.height)
end

function Rect:__eq(other)
    return (self.x == other.x and self.y == other.y and self.width == other.width and self.height == other.height)
end

return Rect

