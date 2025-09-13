local Room = class()
local GenerationUtils = require("generation.utils")
local Common = require("common")
local Vector = require("utils.classes.vector")
local Rect = require("utils.classes.rect")
local Hash = require("utils.classes.hash")
local Array = require("utils.classes.array")
local SparseGrid = require("utils.classes.sparse_grid")
Tags.add("ROOM_RECT_EDGE_ALLOWED", 1)
Tags.add("ROOM_RECT_EDGE_ONLY", 2)
Tags.add("ROOM_RECT_EDGE_FORBIDDEN", 3)
Tags.add("ROOM_RECT_EDGE_DOOR_DIVIDING", 4)
Tags.add("ROOM_RECT_NON_SIDE", 5)
function Room:initialize(rects)
    self.rects = rects
    self.sideDoors = Hash:new()
    local alignedX, alignedY = false, false
    for rect in self.rects() do
        if rect.x == 1 then
            alignedX = true
        end

        if rect.y == 1 then
            alignedY = true
        end

    end

    Utils.assert(alignedX and alignedY, "At least 1 rect should have x == 1 and" .. " 1 rect should have y == 1")
    self.occupied = SparseGrid:new(true)
    self.occupiedNonDoor = false
    self.potentialOccupy = Array:new()
    self.potentialHorizontals = {  }
    self.potentialHorizontals.all = Array:new()
    self.potentialHorizontals.nonEdge = Array:new()
    self.potentialHorizontals.doorDividing = Array:new()
    self.potentialVerticals = {  }
    self.potentialVerticals.all = Array:new()
    self.potentialVerticals.nonEdge = Array:new()
    self.potentialVerticals.doorDividing = Array:new()
    self._positionsNonDoor = false
    self._position = Vector.UNIT_XY
    self.itemHolder = false
    self.isStart = false
end

function Room:setPosition(position)
    for rect in self.rects() do
        rect:setPosition(rect:getPosition() - self._position + position)
    end

    self._position = position
end

function Room:getPosition()
    return self._position
end

function Room:adjustedRects(adjustment)
    if adjustment == 0 then
        return self.rects
    end

    return self.rects:map(function(rect)
        return rect:sizeAdjusted(adjustment)
    end)
end

function Room:getMaxDimensions()
    local maxWidth = self.rects:map(function(rect)
        return rect:right() - self._position.x
    end):maxValue()
    local maxHeight = self.rects:map(function(rect)
        return rect:bottom() - self._position.y
    end):maxValue()
    return maxWidth, maxHeight
end

function Room:discreteCenter()
    return Rect:new(self._position.x, self._position.y, self:getMaxDimensions()):discreteCenter()
end

local function getInsideDoorRect(direction, doorPosition)
    local occupiedPos = doorPosition - Vector[direction] * 4
    local rect = Rect:new(occupiedPos.x, occupiedPos.y, 2, 2)
    rect:growDirectionSelf(reverseDirection(direction), -1)
    return rect
end

function Room:getAllPositionsNonDoor()
    if not self._positionsNonDoor then
        self._positionsNonDoor = Array:new()
        local taken = SparseGrid:new(false)
        for direction, doorPosition in self.sideDoors() do
            taken:fillRect(true, getInsideDoorRect(direction, doorPosition))
        end

        for rect in self.rects() do
            for position in rect:gridIteratorV() do
                if not taken:get(position) then
                    taken:set(position, true)
                    self._positionsNonDoor:push(position)
                end

            end

        end

    end

    return self._positionsNonDoor:clone()
end

function Room:fillOccupied(rng)
    for rect in self.rects() do
        for position in rect:gridIteratorV() do
            if self.occupied:get(position) then
                self.occupied:set(position, false)
            end

        end

    end

    self.occupiedNonDoor = self.occupied:clone()
end

function Room:createPotentialOccupy(rng, level)
    for position, _ in self.occupied() do
        self.potentialOccupy:push(position)
    end

    self.potentialOccupy:shuffleSelf(rng)
    local maxWidth, maxHeight = self:getMaxDimensions()
    for ix = self._position.x, self._position.x + maxWidth - 1 do
        local currentRect = false
        for iy = self._position.y, self._position.y + maxHeight - 1 do
                        if not self.occupiedNonDoor:get(Vector:new(ix, iy)) then
                if not currentRect then
                    currentRect = Rect:new(ix, iy, 1, 1)
                else
                    currentRect.height = currentRect.height + 1
                end

            elseif currentRect then
                break
            end

        end

        Utils.assert(currentRect, "Detected holes in the room")
        if self.occupied:isAllValue(false, currentRect) then
            self.potentialVerticals.all:push(currentRect)
            local grown = currentRect:growDirection(LEFT, 2):growDirection(RIGHT, 2)
            if self.occupiedNonDoor:isAllValue(false, grown) then
                self.potentialVerticals.nonEdge:push(currentRect)
                local hasLeft, hasRight = false, false
                for direction, sideDoor in self.sideDoors() do
                    local doorRect = getInsideDoorRect(direction, sideDoor)
                                        if doorRect.x + doorRect.width - 1 < currentRect.x then
                        hasLeft = true
                    elseif doorRect.x > currentRect.x + currentRect.width - 1 then
                        hasRight = true
                    end

                end

                if hasLeft and hasRight then
                    self.potentialVerticals.doorDividing:push(currentRect)
                end

            end

        end

    end

    for iy = self._position.y, self._position.y + maxHeight - 1 do
        local currentRect = false
        for ix = self._position.x, self._position.x + maxWidth - 1 do
                        if not self.occupiedNonDoor:get(Vector:new(ix, iy)) then
                if not currentRect then
                    currentRect = Rect:new(ix, iy, 1, 1)
                else
                    currentRect.width = currentRect.width + 1
                end

            elseif currentRect then
                break
            end

        end

        Utils.assert(currentRect, "Detected holes in the room")
        if self.occupied:isAllValue(false, currentRect) then
            self.potentialHorizontals.all:push(currentRect)
            local grown = currentRect:growDirection(UP, 2):growDirection(DOWN, 2)
            if self.occupiedNonDoor:isAllValue(false, grown) then
                self.potentialHorizontals.nonEdge:push(currentRect)
                local hasBelow, hasAbove = false, false
                for direction, sideDoor in self.sideDoors() do
                    local doorRect = getInsideDoorRect(direction, sideDoor)
                                        if doorRect.y + doorRect.height - 1 < currentRect.y then
                        hasAbove = true
                    elseif doorRect.y > currentRect.y + currentRect.height - 1 then
                        hasBelow = true
                    end

                end

                if hasBelow and hasAbove then
                    self.potentialHorizontals.doorDividing:push(currentRect)
                end

            end

        end

    end

end

function Room:getSideDoor(rng, direction, wallSize)
    if not self.sideDoors:hasKey(direction) then
        local possibleDoors = Array:new()
        for rect in self.rects() do
            local positions = Array:collect(rect:iterateSide(direction))
            positions:pop()
            if Common.HORIZONTAL:contains(direction) then
                positions = positions:map(function(position)
                    return position + Vector:new(0, 0.5)
                end)
            else
                positions = positions:map(function(position)
                    return position + Vector:new(0.5, 0)
                end)
            end

            positions = positions:map(function(position)
                return position + Vector[direction] * (wallSize + 1.5)
            end)
            for otherRect in self.rects() do
                if rect ~= otherRect then
                    positions = positions:reject(function(position)
                        local posRect = Rect:new(position.x, position.y, 1, 1):sizeAdjusted(wallSize + 0.5)
                        return otherRect:collidesWith(posRect)
                    end)
                end

            end

            possibleDoors:concat(positions)
        end

        local door = possibleDoors:randomValue(rng) - Vector:new(0.5, 0.5)
        self.sideDoors:set(direction, door)
        self.occupied:fillRect(true, getInsideDoorRect(direction, door))
    end

    return self.sideDoors:get(direction)
end

function Room:removeSideDoor(direction, sideDoor)
    self.sideDoors:deleteKey(direction)
    self.occupied:fillRect(false, getInsideDoorRect(direction, sideDoor))
end

function Room:getUnoccupiedRect(rng, width, height, roomRectMode)
    for starting in self.potentialOccupy() do
        local rect = Rect:new(starting.x, starting.y, width, height)
        local checkExpand = 0
        if roomRectMode == Tags.ROOM_RECT_NON_SIDE then
            checkExpand = 1
        end

        if self.occupied:isAllValue(false, rect:sizeAdjusted(checkExpand)) then
            self.occupied:fillRect(true, rect)
            return rect
        end

    end

    return false
end

function Room:getUnoccupiedLineRect(rng, lineSource, minLength, thickness, edgeMode, lengthParam, thicknessParam)
    local startingLines = lineSource.all
    local additionalSource = lineSource.all
            if edgeMode == Tags.ROOM_RECT_EDGE_ONLY then
        startingLines = Array:new(lineSource.all[1], lineSource.all:last())
    elseif edgeMode == Tags.ROOM_RECT_EDGE_FORBIDDEN then
        startingLines = lineSource.nonEdge
        additionalSource = lineSource.nonEdge
    elseif edgeMode == Tags.ROOM_RECT_EDGE_DOOR_DIVIDING then
        startingLines = lineSource.doorDividing
        additionalSource = lineSource.nonEdge
    end

    for startingLine in (startingLines:shuffle(rng))() do
        if startingLine[lengthParam] >= minLength then
            local growthDirections = Array:new(UP, DOWN)
            local currentRect = startingLine:clone()
            while (not growthDirections:isEmpty() and currentRect[thicknessParam] < thickness) do
                local direction = growthDirections:randomValue(rng)
                local side = currentRect:getSideRect(direction)
                side:moveSelf(direction)
                if additionalSource:contains(side) then
                    currentRect:growDirectionSelf(direction, 1)
                else
                    growthDirections:delete(direction)
                end

            end

            if currentRect[thicknessParam] == thickness then
                if self.occupied:isAllValue(false, currentRect) then
                    self.occupied:fillRect(true, currentRect)
                    return currentRect
                end

            end

        end

    end

    return false
end

function Room:getUnoccupiedHorizontal(rng, minLength, thickness, edgeMode)
    return self:getUnoccupiedLineRect(rng, self.potentialHorizontals, minLength, thickness, edgeMode, "width", "height")
end

function Room:getUnoccupiedVertical(rng, minLength, thickness, edgeMode)
    return self:getUnoccupiedLineRect(rng, self.potentialVerticals, minLength, thickness, edgeMode, "height", "width")
end

function Room:containsPosition(position)
    for rect in self.rects() do
        if rect:contains(position) then
            return true
        end

    end

    return false
end

return Room

