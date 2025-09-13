local PathFinder = class()
local Array = require("utils.classes.array")
local Vector = require("utils.classes.vector")
local PriorityQueue = require("utils.classes.priority_queue")
local Hash = require("utils.classes.hash")
local PathNode = struct("value", "g", "h", "previous", "length")
function PathFinder:initialize()
    self.distanceLimit = math.huge
    self.lengthLimit = math.huge
end

function PathFinder:getNeighbors(a, params)
    return Array.EMPTY
end

function PathFinder:getEdgeLength(a, b, params)
    return 1
end

function PathFinder:toHash(a)
    return a
end

function PathFinder:getHeuristic(a, b, params)
    return 0
end

function PathFinder:findPath(source, destination, params)
    params = table.assign({ source = source, destination = destination }, params or {  })
    local sourceNode = PathNode:new(source, 0, self:getHeuristic(source, destination, params), false, 1)
    local queue = PriorityQueue:new(function(aNode, bNode)
        return aNode.g + aNode.h < bNode.g + bNode.h
    end)
    queue:insert(sourceNode)
    local distances = Hash:new()
    distances:set(self:toHash(source), 0)
    while not queue:isEmpty() do
        local current = queue:popMin()
        if current.g <= self.distanceLimit and current.length <= self.lengthLimit then
            if current.value == destination then
                local path = Array:new()
                while current do
                    path:push(current.value)
                    current = current.previous
                end

                return path:reversed()
            end

            for neighbor in (self:getNeighbors(current.value, params))() do
                local cost = self:getEdgeLength(current.value, neighbor, params)
                if cost < math.huge then
                    local neighborG = current.g + cost
                    local neighborHashed = self:toHash(neighbor)
                    if neighborG < distances:get(neighborHashed, math.huge) then
                        local node = PathNode:new(neighbor, neighborG, self:getHeuristic(neighbor, destination, params), current, current.length + 1)
                        distances:set(neighborHashed, neighborG)
                        queue:insert(node)
                    end

                end

            end

        end

    end

    return false
end

PathFinder.BaseGrid = class(PathFinder)
local MAX_VALUE = 2 ^ 23
local HASH_MULTIPLIER = MAX_VALUE * 2
function PathFinder.BaseGrid:initialize()
    PathFinder.BaseGrid:super(self, "initialize")
end

function PathFinder.BaseGrid:getNeighbors(a, params)
    return DIRECTIONS_AA:map(function(direction)
        return a + Vector[direction]
    end)
end

function PathFinder.BaseGrid:getEdgeLength(a, b, params)
    return 1
end

function PathFinder.BaseGrid:toHash(a)
    return (a.y + MAX_VALUE) * HASH_MULTIPLIER + a.x + MAX_VALUE
end

function PathFinder.BaseGrid:getHeuristic(a, b, params)
    return a:distanceManhattan(b)
end

return PathFinder

