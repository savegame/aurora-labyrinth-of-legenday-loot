local DiscretePoints = {  }
function DiscretePoints.BresenhamLine(p1, p2)
    if p1 == p2 then
        return Array:new(p1)
    end

    local result = Array:new()
    local dx, dy = p2.x - p1.x, p2.y - p1.y
    local inverted = false
    if abs(dy) > abs(dx) then
        dx, dy = dy, dx
        p1, p2 = p1:inverted(), p2:inverted()
        inverted = true
    end

    local err = 0
    local slope = abs(dy / dx)
    local y = p1.y
    for x = p1.x, round(p2.x), sign(dx) do
        local point = Vector:new(x, y)
        result:push(Vector:new(x, y))
        err = err + slope
        while err >= 0.5 do
            y = y + sign(p2.y - p1.y)
            err = err - 1
            if err >= 0.5 then
                result:push(Vector:new(x, y))
            end

        end

    end

    if inverted then
        for i, value in ipairs(result) do
            result[i] = value:inverted()
        end

    end

    return result
end

function DiscretePoints.BresenhamLineAngle(p1, angle, distance)
    return DiscretePoints.BresenhamLine(p1, Vector:new(p1.x, p1.y) + Vector:new(cos(angle) * distance, sin(angle) * distance))
end

function DiscretePoints.midpointCircle(starting, radius)
    local x, y = radius, 0
    local result = Array:new()
    local decisionOver2 = 1 - x
    while y <= x do
        result:push(Vector:new(x, y), Vector:new(-x, y))
        if x ~= y then
            result:push(Vector:new(y, x), Vector:new(-y, -x))
        end

        if x ~= radius or y ~= 0 then
            result:push(Vector:new(x, -y), Vector:new(-x, -y))
            if x ~= y then
                result:push(Vector:new(-y, x), Vector:new(y, -x))
            end

        end

        y = y + 1
        if decisionOver2 <= 0 then
            decisionOver2 = decisionOver2 + 2 * y + 1
        else
            x = x - 1
            decisionOver2 = decisionOver2 + 2 * (y - x) + 1
        end

    end

    return result:map(function(point)
        return point + starting
    end)
end

return DiscretePoints

