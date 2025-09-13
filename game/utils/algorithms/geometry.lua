local Vector = require("utils.classes.vector")
local Geometry = {  }
function Geometry.segmentIntersection(p1, p2, p3, p4)
    local dx1 = p1.x - p2.x
    local dx2 = p3.x - p4.x
    local dy1 = p1.y - p2.y
    local dy2 = p3.y - p4.y
    local c1 = p1.x * p2.y - p2.x * p1.y
    local c2 = p3.x * p4.y - p4.x * p3.y
    local denom = dx1 * dy2 - dx2 * dy1
    if denom == 0 then
        return false
    end

    local intersection = Vector:new((c1 * dx2 - c2 * dx1) / denom, (c1 * dy2 - c2 * dy1) / denom)
    if within(intersection.x, p1.x, p2.x) and within(intersection.x, p3.x, p4.x) and within(intersection.y, p1.y, p2.y) and within(intersection.y, p3.y, p4.y) then
        return intersection
    else
        return false
    end

end

return Geometry

