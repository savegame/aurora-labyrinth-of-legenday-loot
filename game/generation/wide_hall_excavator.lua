local WideHallExcavator = class()
local Array = require("utils.classes.array")
local Vector = require("utils.classes.vector")
local Rect = require("utils.classes.rect")
local SparseGraph = require("utils.classes.sparse_graph")
local SparseGrid = require("utils.classes.sparse_grid")
local GraphAlgorithms = require("utils.algorithms.graphs")
local getDirectionsByDistance = require("generation.utils").getDirectionsByDistance
function WideHallExcavator:initialize()
    self.wallSize = 1
    self.roomCount = false
    self.roomGenerator = false
    self.rooms = false
    self.level = false
    self.command = false
    self.levelRect = false
    self.roomGraph = false
end

function WideHallExcavator:getGap()
    return self.wallSize * 2 + 2
end

function WideHallExcavator:canRoomOccupy(room)
    for rect in room.rects() do
        if not self.levelRect:containsRect(rect) then
            return false
        end

    end

    local adjustedRects = room:adjustedRects(self:getGap())
    for otherRoom in self.rooms() do
        if room ~= otherRoom then
            for adjustedRect in adjustedRects() do
                for otherRect in otherRoom.rects() do
                    if adjustedRect:collidesWith(otherRect) then
                        return false
                    end

                end

            end

        end

    end

    return true
end

function WideHallExcavator:fillRoomIfDisplay(room, tile)
    if self.command.display then
        local tiles = self.level.tiles
        for rect in room.rects() do
            tiles:fillRect(tile, rect)
        end

    end

end

local SORT_XY_RATIO = Vector:new(0.6, 1)
function WideHallExcavator:getCenterSortedRooms()
    local levelCenter = self.level.tiles:toRect():discreteCenter() * SORT_XY_RATIO
    return self.rooms:stableSort(function(a, b)
        local aDistance = (a:discreteCenter() * SORT_XY_RATIO):distance(levelCenter)
        local bDistance = (b:discreteCenter() * SORT_XY_RATIO):distance(levelCenter)
        return aDistance < bDistance
    end)
end

function WideHallExcavator:approachCenter()
    local levelCenter = self.level.tiles:toRect():discreteCenter()
    local rng = self.command.rng
    local hasRoomMoved = true
    while hasRoomMoved do
        hasRoomMoved = false
        for room in (self:getCenterSortedRooms())() do
            for i = 1, self.level.tiles.width do
                local hasMoved = false
                local roomCenter = room:discreteCenter()
                local distance = roomCenter:distanceEuclidean(levelCenter)
                local directions = getDirectionsByDistance(roomCenter, levelCenter, rng)
                directions = directions:subArray(1, 2)
                self:fillRoomIfDisplay(room, self.command.tileWall)
                for direction in directions() do
                    if (roomCenter + Vector[direction]):distanceEuclidean(levelCenter) < distance then
                        room:setPosition(room:getPosition() + Vector[direction])
                        if self:canRoomOccupy(room) then
                            hasMoved = true
                            break
                        else
                            room:setPosition(room:getPosition() - Vector[direction])
                        end

                    end

                end

                self:fillRoomIfDisplay(room, self.command.tileRoom)
                if not hasMoved then
                    break
                else
                    hasRoomMoved = true
                end

            end

            self.command:yield()
        end

    end

end

function WideHallExcavator:trimLevel()
    local _, trimmed = self.level.tiles:trimSelf()
    local padding = self.command.padding
    self.level:pad(padding, self.command.tileWall)
    local offset = Vector:new(trimmed[LEFT] - padding, trimmed[UP] - padding)
    for room in self.rooms() do
        room:setPosition(room:getPosition() - offset)
    end

end

function WideHallExcavator:createRoomGraph()
    local adjacency = SparseGraph:new()
    for room in self.rooms() do
        adjacency:addVertex(room)
    end

    local aGap = floor((self:getGap() + 1) / 2)
    local bGap = ceil((self:getGap() + 1) / 2)
    for roomA, roomB in self.rooms:pairwiseIterator() do
        local hasEdge = false
        for aRect in (roomA:adjustedRects(aGap))() do
            for bRect in (roomB:adjustedRects(bGap))() do
                if aRect:collidesWith(bRect) then
                    adjacency:addEdge(roomA, roomB, self.command.rng:random())
                    hasEdge = true
                    break
                end

            end

            if hasEdge then
                break
            end

        end

    end

    self.command:yieldIfNotDisplay()
    self.roomGraph = GraphAlgorithms.Prim(adjacency)
    for vertex in (self.roomGraph.vertices:shuffle(self.command.rng))() do
        if vertex.edges:size() <= 1 then
            for otherVertex in self.roomGraph.vertices() do
                if vertex ~= otherVertex then
                    local edge = adjacency:getEdge(vertex.value, otherVertex.value)
                    if ((not self.roomGraph:hasEdge(vertex.value, otherVertex.value)) and edge) then
                        self.roomGraph:addEdge(vertex.value, otherVertex.value, edge.length)
                        break
                    end

                end

            end

        end

    end

    self.command:yieldIfNotDisplay()
end

local DoorPathFinder = class(require("utils.algorithms.path_finder").BaseGrid)
function DoorPathFinder:initialize(level, tileWall, wallSize)
    DoorPathFinder:super(self, "initialize")
    self.validHalls = SparseGrid:new(false, level:getDimensions())
    self.takenHalls = SparseGrid:new(false, level:getDimensions())
    for position, _ in self.validHalls:denseIterator() do
        local r = Rect:new(position.x, position.y, 2, 2)
        if level.tiles:isAllValue(tileWall, r:sizeAdjusted(wallSize)) then
            self.validHalls:set(position, true)
        end

    end

end

function DoorPathFinder:getNeighbors(a, params)
    local neighbors = DoorPathFinder:super(self, "getNeighbors", a, params)
    neighbors = neighbors:reject(function(neighbor)
        return not self.validHalls:get(neighbor)
    end)
    return neighbors
end

function DoorPathFinder:getHeuristic(a, b)
    return DoorPathFinder:super(self, "getHeuristic", a, b) * 0.5
end

function DoorPathFinder:getEdgeLength(a, b, params)
        if self.takenHalls:get(b) then
        return 0.45
    elseif a.x == b.x then
        return 0.5
    else
        return 1
    end

end

function WideHallExcavator:createHallways()
    local pathFinder = DoorPathFinder:new(self.level, self.command.tileWall, self.wallSize)
    self.command:yieldIfNotDisplay()
    local rng = self.command.rng
    for edge in (self.roomGraph:edgesSingle())() do
        local roomA, roomB = edge.source, edge.target
        local centerA, centerB = roomA:discreteCenter(), roomB:discreteCenter()
        local aDir = getDirectionsByDistance(centerA, centerB, rng)[1]
        local bDir = getDirectionsByDistance(centerB, centerA, rng)[1]
        local doorA = roomA:getSideDoor(rng, aDir, self.wallSize)
        local doorB = roomB:getSideDoor(rng, bDir, self.wallSize)
        local path = pathFinder:findPath(doorA, doorB)
        if path then
            for position in path() do
                pathFinder.takenHalls:set(position, true)
                self.level.tiles:fillRect(self.command.tileHall, position.x, position.y, 2, 2)
                self.command:yield()
            end

        end

        self.command:yield()
    end

    for room in self.rooms() do
        for direction, sideDoor in room.sideDoors() do
            local r = Rect:new(sideDoor.x, sideDoor.y, 2, 2)
            r:moveSelf(reverseDirection(direction), self.wallSize)
            self.level.tiles:fillRect(self.command.tileHall, r)
            if self.command.display or room == self.rooms:last() then
                self.command:yield()
            end

        end

    end

end

function WideHallExcavator:excavate(command)
    self.rooms = Array:new()
    self.command = command
    self.level = self.command.level
    local rng = command.rng
    self.levelRect = Rect:new(1, 1, self.level:getDimensions()):sizeAdjusted(-self:getGap())
    local positions = Array:collect(self.levelRect:gridIteratorV())
    positions:shuffleSelf(rng)
    local nextRoom = self.roomGenerator:generate(rng)
    for position in positions() do
        nextRoom:setPosition(position)
        if self:canRoomOccupy(nextRoom) then
            self.rooms:push(nextRoom)
            self:fillRoomIfDisplay(nextRoom, self.command.tileRoom)
            nextRoom = self.roomGenerator:generate(rng)
            self.command:yield()
        end

    end

    self.rooms = self:getCenterSortedRooms()
    local roomCount = self.roomCount:randomInteger(rng)
    if DebugOptions.MINIMAL_ROOMS then
        roomCount = 2
    end

    if self.rooms:size() < roomCount then
        Debugger.log("Warning: Generated less rooms than room count: " .. self.rooms:size())
    end

    for i = roomCount + 1, self.rooms:size() do
        self:fillRoomIfDisplay(self.rooms[i], self.command.tileWall)
    end

    self.rooms = self.rooms:subArray(1, roomCount)
    self:approachCenter()
    if not command.display then
        local tiles = self.level.tiles
        for room in self.rooms() do
            for rect in room.rects() do
                tiles:fillRect(command.tileRoom, rect)
            end

        end

    end

    self.rooms:shuffleSelf(rng)
    self:trimLevel()
    for room in self.rooms() do
        room:fillOccupied()
    end

    self:createRoomGraph()
    self:createHallways()
    for room in self.rooms() do
        room:createPotentialOccupy(rng, self.level)
    end

    self.command:yieldIfNotDisplay()
    self.command.rooms = self.rooms
end

return WideHallExcavator

