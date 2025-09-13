local Vector3 = class()
function Vector3:initialize(x, y, z)
        if type(x) == "string" then
        local sx, sy, sz = x:match("([^,]+),([^,]+),([^,]+)")
        self.x = tonumber(sx)
        self.y = tonumber(sy)
        self.z = tonumber(sz)
    elseif type(x) == "table" then
        self.x, self.y, self.z = x.x, x.y, x.z
    else
        self.x = x or 0
        self.y = y or 0
        self.z = z or 0
    end

end

function Vector3:length()
    return sqrt(self.x * self.x + self.y * self.y + self.z * self.z)
end

function Vector3:move(dx, dy, dz)
    self.x, self.y, self.z = self.x + dx, self.y + dy, self.z + dz
end

function Vector3:__eq(other)
    return (self.x == other.x and self.y == other.y and self.z == other.z)
end

function Vector3:__unm()
    return Vector3:new(-self.x, -self.y, -self.z)
end

function Vector3:__add(other)
    return Vector3:new(self.x + other.x, self.y + other.y, self.z + other.z)
end

function Vector3:__sub(other)
    return Vector3:new(self.x - other.x, self.y - other.y, self.z - other.z)
end

function Vector3:__mul(value)
        if type(value) == "number" then
        return Vector3:new(self.x * value, self.y * value, self.z * value)
    elseif type(value) == "table" then
        return Vector3:new(self.x * value.x, self.y * value.y, self.z * value.z)
    end

end

function Vector3:__div(scalar)
    return Vector3:new(self.x / scalar, self.y / scalar, self.z / scalar)
end

function Vector3:floorXYZ()
    return Vector3:new(floor(self.x), floor(self.y), floor(self.z))
end

function Vector3:ceilXYZ()
    return Vector3:new(ceil(self.x), ceil(self.y), ceil(self.z))
end

function Vector3:dot(other)
    return self.x * other.x + self.y * other.y + self.z * other.z
end

function Vector3:xPart()
    return Vector3:new(self.x, 0, 0)
end

function Vector3:yPart()
    return Vector3:new(0, self.y, 0)
end

function Vector3:zPart()
    return Vector3:new(0, 0, self.z)
end

function Vector3:expand()
    return self.x, self.y, self.z
end

function Vector3:distanceEuclidean(other)
    local dx, dy, dz = (other.x - self.x), (other.y - self.y), (other.z - self.z)
    return sqrt(dx * dx + dy * dy + dz * dz)
end

function Vector3:distanceManhattan(other)
    return abs(self.x - other.x) + abs(self.y - other.y) + abs(self.z + other.z)
end

function Vector3:maxComponentMagnitude()
    return max(abs(self.x), abs(self.y), abs(self.z))
end

function Vector3:__tostring()
    return self.x .. "," .. self.y .. "," .. self.z
end

Vector3.UNIT_XYZ = Vector3:new(1, 1, 1)
Vector3.UNIT_X = Vector3:new(1, 0, 0)
Vector3.UNIT_Y = Vector3:new(0, 1, 0)
Vector3.UNIT_Z = Vector3:new(0, 0, 1)
Vector3.ORIGIN = Vector3:new(0, 0, 0)
return Vector3

