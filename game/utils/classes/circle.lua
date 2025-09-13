local Circle = class()
local Vector = require("utils.classes.vector")
local Rect = require("utils.classes.rect")
local Array = require("utils.classes.array")
function Circle:initialize(x, y, radius)
    if y == nil then
        self.x, self.y = 0, 0
        self.radius = x
    else
        self.x, self.y = x, y
        self.radius = radius
    end

end

function Circle:getPosition()
    return Vector:new(self.x, self.y)
end

function Circle:setPosition(x, y)
    if type(x) == "table" then
        self.x, self.y = x.x, x.y
    else
        self.x, self.y = x, y
    end

end

function Circle:contains(x, y)
    if type(x) == "table" then
        x, y = x.x, x.y
    end

    local dx, dy = self.x - x, self.y - y
    return dx * dx + dy * dy < self.radius * self.radius
end

function Circle:scaleSelf(value)
    self.radius = self.radius * value
end

function Circle:getBoundingRect()
    return Rect:new(self.x - self.radius, self.y - self.radius, self.radius * 2, self.radius * 2)
end

function Circle:lineIntersection(x1, y1, x2, y2)
    x1 = x1 - self.x
    x2 = x2 - self.x
    y1 = y1 - self.y
    y2 = y2 - self.y
    local dx = x2 - x1
    local dy = y2 - y1
    local dr = math.sqrt(dx * dx + dy * dy)
    local D = x1 * y2 - x2 * y1
    local discriminant = self.radius * self.radius * dr * dr - D * D
    if discriminant < 0 then
        return Array:new()
    else
        local sqDiscriminant = math.sqrt(discriminant)
        local result = Array:new()
        local rx = (D * dy + sign(dy) * dx * sqDiscriminant) / (dr * dr)
        local ry = (-D * dx + math.abs(dy) * sqDiscriminant) / (dr * dr)
        result:push(Vector:new(rx + self.x, ry + self.y))
        if discriminant == 0 then
            return result
        end

        rx = (D * dy - sign(dy) * dx * sqDiscriminant) / (dr * dr)
        ry = (-D * dx - math.abs(dy) * sqDiscriminant) / (dr * dr)
        result:push(Vector:new(rx + self.x, ry + self.y))
        return result
    end

end

return Circle

