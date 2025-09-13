local GenerationUtils = {  }
local Array = require("utils.classes.array")
local Vector = require("utils.classes.vector")
local DIRECTIONS_PREFERRED = Array:new(RIGHT, LEFT, DOWN, UP)
function GenerationUtils.getDirectionsByDistance(position, target, rng)
    local directions = DIRECTIONS_PREFERRED
    if rng then
        directions = directions:shuffle(rng)
    end

    return directions:stableSort(function(d1, d2)
        return (position + Vector[d1]):distanceEuclidean(target) < (position + Vector[d2]):distanceEuclidean(target)
    end)
end

return GenerationUtils

