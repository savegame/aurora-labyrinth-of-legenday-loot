local Vector = require("utils.classes.vector")
local RandomQueue = require("utils.classes.random_queue")
local Array = require("utils.classes.array")
local SparseGrid = require("utils.classes.sparse_grid")
local Range = require("utils.classes.range")
local DEFAULT_TRIES = 30
local function toGrid(position, cellSize)
    return Vector:new(floor(position.x / cellSize) + 1, floor(position.y / cellSize) + 1)
end

return function(rng, minDistance, width, height, tries)
    tries = tries or DEFAULT_TRIES
    height = height or width
    local cellSize = minDistance / math.sqrtOf2
    local grid = SparseGrid:new(false, floor(width / cellSize) + 1, floor(height / cellSize) + 1)
    local xRange, yRange = Range:new(0, width), Range:new(0, height)
    local starting = Vector:new(xRange:randomFloat(rng), yRange:randomFloat(rng))
    grid:set(toGrid(starting, cellSize), starting)
    local possible = RandomQueue:new(rng, starting)
    while not possible:isEmpty() do
        local toExpand = possible:pop()
        for i = 1, tries do
            local angle = Utils.randomFloat(rng, 0, math.tau)
            local distance = Utils.randomFloat(rng, minDistance, minDistance * 2)
            local toTry = toExpand + Vector:createFromAngle(angle) * distance
            if xRange:contains(toTry.x) and yRange:contains(toTry.y) then
                local toTryGrid = toGrid(toTry, cellSize)
                local foundClose = false
                for offset in Utils.gridIteratorV(-2, 2, -2, 2) do
                    local closePoint = grid:get(toTryGrid + offset)
                    if closePoint and closePoint:distance(toTry) <= minDistance then
                        foundClose = true
                        break
                    end

                end

                if not foundClose then
                    grid:set(toTryGrid, toTry)
                    possible:push(toTry)
                end

            end

        end

    end

    local values = Array:new()
    for _, position in grid() do
        values:push(position)
    end

    return values
end

