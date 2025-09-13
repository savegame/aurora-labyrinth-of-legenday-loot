local Vector = class()
function Vector:initialize(x, y)
        if type(x) == "string" then
        local sx, sy = x:match("([^,]+),([^,]+)")
        self.x = tonumber(sx)
        self.y = tonumber(sy)
    elseif type(x) == "table" then
        self.x, self.y = x.x, x.y
    else
        self.x = x or 0
        self.y = y or 0
    end

end

function Vector:createFromAngle(angle)
    return Vector:new(cos(angle), sin(angle))
end

function Vector:length()
    return sqrt(self.x * self.x + self.y * self.y)
end

function Vector:gridLength()
    return abs(self.x) + abs(self.y)
end

function Vector:withX(newX)
    return Vector:new(newX, self.y)
end

function Vector:withY(newY)
    return Vector:new(self.x, newY)
end

function Vector:move(dx, dy)
    self.x, self.y = self.x + dx, self.y + dy
end

function Vector:sign()
    return Vector:new(sign(self.x), sign(self.y))
end

function Vector:normalize(targetLength)
    targetLength = targetLength or 1
    local length = self:length()
    return Vector:new(self.x * targetLength / length, self.y * targetLength / length)
end

function Vector:angle()
    if self.x == 0 and self.y == 0 then
        return 0
    end

    return atan2(self.y, self.x)
end

function Vector:angleTo(target)
    return (target - self):angle()
end

function Vector:rotate(angle)
    local cosAngle = cos(angle)
    local sinAngle = sin(angle)
    return Vector:new(self.x * cosAngle + self.y * sinAngle, self.y * cosAngle - self.x * sinAngle)
end

function Vector:__eq(other)
    return (self.x == other.x and self.y == other.y)
end

function Vector:__unm()
    return Vector:new(-self.x, -self.y)
end

function Vector:__add(other)
    return Vector:new(self.x + other.x, self.y + other.y)
end

function Vector:__sub(other)
    return Vector:new(self.x - other.x, self.y - other.y)
end

function Vector:__mul(value)
        if type(value) == "number" then
        return Vector:new(self.x * value, self.y * value)
    elseif type(value) == "table" then
        return Vector:new(self.x * value.x, self.y * value.y)
    end

end

function Vector:__div(value)
        if type(value) == "number" then
        return Vector:new(self.x / value, self.y / value)
    elseif type(value) == "table" then
        return Vector:new(self.x / value.x, self.y / value.y)
    end

end

function Vector:__lt(other)
        if self.x < other.x then
        return true
    elseif self.x > other.x then
        return false
    else
        return self.y < other.y
    end

end

function Vector:floorXY()
    return Vector:new(floor(self.x), floor(self.y))
end

function Vector:ceilXY()
    return Vector:new(ceil(self.x), ceil(self.y))
end

function Vector:roundXY()
    return Vector:new(round(self.x), round(self.y))
end

function Vector:dot(x, y)
    if type(x) == "table" then
        return self.x * x.x + self.y * x.y
    else
        return self.x * x + self.y * y
    end

end

function Vector:boundLower(minX, minY)
    return Vector:new(max(minX, self.x), max(minY, self.y))
end

function Vector:boundUpper(maxX, maxY)
    return Vector:new(min(maxX, self.x), min(maxY, self.y))
end

function Vector:inverted()
    return Vector:new(self.y, self.x)
end

function Vector:xPart()
    return Vector:new(self.x, 0)
end

function Vector:yPart()
    return Vector:new(0, self.y)
end

function Vector:slopeTo(target)
    return (target.y - self.y) / (target.x - self.x)
end

function Vector:__tostring()
    return self.x .. "," .. self.y
end

function Vector:expand()
    return self.x, self.y
end

function Vector:distanceEuclidean(other)
    local dx, dy = (other.x - self.x), (other.y - self.y)
    return sqrt(dx * dx + dy * dy)
end

function Vector:distanceManhattan(other)
    return abs(self.x - other.x) + abs(self.y - other.y)
end

Vector.distance = Vector.distanceEuclidean
function Vector:maxComponentMagnitude()
    return max(abs(self.x), abs(self.y))
end

function Vector:minComponentMagnitude()
    return min(abs(self.x), abs(self.y))
end

function Vector:approachTarget(target, distance)
    local delta = target - self
    local deltaLength = delta:length()
    if deltaLength <= distance then
        return target
    else
        return self + delta * distance / deltaLength
    end

end

Vector.UNIT_XY = Vector:new(1, 1)
Vector.UNIT_X = Vector:new(1, 0)
Vector.UNIT_Y = Vector:new(0, 1)
Vector.ORIGIN = Vector:new(0, 0)
Vector[RIGHT] = Vector:new(1, 0)
Vector[DOWN] = Vector:new(0, 1)
Vector[LEFT] = Vector:new(-1, 0)
Vector[UP] = Vector:new(0, -1)
Vector[CENTER] = Vector.ORIGIN
Vector[DOWN_RIGHT] = Vector:new(1, 1)
Vector[DOWN_LEFT] = Vector:new(-1, 1)
Vector[UP_LEFT] = Vector:new(-1, -1)
Vector[UP_RIGHT] = Vector:new(1, -1)
return Vector

