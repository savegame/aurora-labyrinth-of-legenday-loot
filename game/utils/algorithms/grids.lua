local Grids = {  }
local Array = require("utils.classes.array")
local Vector = require("utils.classes.vector")
local SparseGrid = require("utils.classes.sparse_grid")
local OCTANT_CONFIG = { [1] = { multiplier = { x = 1, y = 1 } }, [2] = { multiplier = { x = 1, y = 1 }, invert = true }, [3] = { multiplier = { x = -1, y = 1 }, invert = true }, [4] = { multiplier = { x = -1, y = 1 } }, [5] = { multiplier = { x = -1, y = -1 } }, [6] = { multiplier = { x = -1, y = -1 }, invert = true }, [7] = { multiplier = { x = 1, y = -1 }, invert = true }, [8] = { multiplier = { x = 1, y = -1 } } }
local function lightCastOctant(grid, config, starting, distance, topSlope, bottomSlope)
    if not distance then
        distance, topSlope, bottomSlope = 1, 0, 1
    end

    local startCheck = choose(config.invert, starting.y, starting.x)
    if distance > config.maxDistance then
        return 
    end

    local lastBlocking = ceil(topSlope * distance) - 1
    local toCheckEnd = floor(bottomSlope * distance) + 1
    for depth = lastBlocking + 1, toCheckEnd do
        local offset = Vector:new(distance, depth)
        if config.invert then
            offset = offset:inverted()
        end

        local current = starting + offset * config.multiplier
        if config.isBlocking(current) or depth == toCheckEnd then
            if lastBlocking < depth - 1 then
                local nextTopSlope = max(topSlope, (lastBlocking + 0.5) / (distance - 0.5))
                local nextBottomSlope = bottomSlope
                if config.isBlocking(current) then
                    nextBottomSlope = min(bottomSlope, (depth - 0.5) / (distance + 0.5))
                end

                if nextTopSlope < nextBottomSlope then
                    lightCastOctant(grid, config, starting, distance + 1, nextTopSlope, nextBottomSlope, config)
                end

            end

            lastBlocking = depth
        end

        if depth <= distance then
                        if depth < toCheckEnd then
                grid:set(current, true)
            elseif config.isBlocking(current) and (depth - 0.5) / distance < bottomSlope then
                if sqrt((depth - 0.5) * (depth - 0.5) + distance * distance) <= config.maxDistance then
                    grid:set(current, true)
                end

            end

        end

    end

end

function Grids.lightCast(grid, starting, maxDistance, isBlocking)
    for octant = 1, 8 do
        local config = Utils.clone(OCTANT_CONFIG[octant])
        config.isBlocking = isBlocking
        config.maxDistance = maxDistance
        lightCastOctant(grid, config, starting)
    end

end

function Grids.rectangulate(grid)
    local unused = grid:clone()
    local position = unused:getValidPosition()
    local rects = Array:new()
    while position do
        local value = unused:get(position)
        local rect = Rect:new(position.x, position.y, 1, 1)
        local validDirections = DIRECTIONS_AA:clone()
        while not validDirections:isEmpty() do
            local direction = validDirections:last()
            local newRect = rect:growDirection(direction)
            for sidePosition in newRect:iterateSide(direction) do
                if unused:get(sidePosition) ~= value then
                    validDirections:pop()
                    break
                end

            end

            if validDirections:last() == direction then
                rect = newRect
            end

        end

        rects:push(rect)
        unused:clearRect(rect)
        position = unused:getValidPosition()
    end

    return rects
end

function Grids.diamondIterator(range)
    if type(range) == "number" then
        range = Range:new(range, range)
    end

    local distance = range.min
    local i = -1
    return function()
                if distance > range.max then
            return nil
        elseif distance == 0 then
            distance = 1
            return Vector.ORIGIN
        else
            i = i + 1
            local y = i % distance
            local x = distance - y
            if floor(i / distance) % 2 == 1 then
                x, y = -y, x
            end

            if i >= distance * 2 then
                x, y = -x, -y
            end

            if i >= distance * 4 - 1 then
                distance = distance + 1
                i = -1
            end

            return Vector:new(x, y)
        end

    end
end

return Grids

