local Array = require("utils.classes.array")
local Rect = require("utils.classes.rect")
local Vector = require("utils.classes.vector")
local function getSingleDoor(rng, room, direction)
    local door = room:getSideDoor(rng, direction, 1)
    local rect = Rect:new(door.x, door.y, 2, 2):move(reverseDirection(direction), 1):growDirection(direction, -1)
    return Array:collect(rect:gridIteratorV()):randomValue(rng), door
end

return function(command)
    local level, rooms, rng = command.level, command.rooms, command.rng
    local startDirection, exitDirection = LEFT, RIGHT
    if rng:random() < 0.5 then
        startDirection, exitDirection = RIGHT, LEFT
    end

    rooms = rooms:shuffle(rng)
    local startRoom = rooms:findOne(function(room)
        return not room.sideDoors:hasKey(startDirection)
    end)
    local startCenter = startRoom:discreteCenter()
    startRoom.isStart = true
    rooms = rooms:stableSort(function(a, b)
        return a:discreteCenter():distance(startCenter) < b:discreteCenter():distance(startCenter)
    end)
    local startPosition = getSingleDoor(rng, startRoom, startDirection)
    local exitPosition, exitRoom
    while not rooms:isEmpty() do
        exitRoom = rooms:pop()
        local sideDoor
        exitPosition, sideDoor = getSingleDoor(rng, exitRoom, exitDirection)
        local blockingCount = DIRECTIONS_AA:countIf(function(direction)
            return level.tiles:get(exitPosition + Vector[direction]).isBlocking
        end)
        if blockingCount == 3 then
            break
        else
            exitRoom:removeSideDoor(exitDirection, sideDoor)
        end

    end

    level.startPosition = startPosition - Vector[startDirection] * 2
    level.startDirection = reverseDirection(startDirection)
    level.tiles:set(exitPosition, command.tileRoom)
    level:setObject(exitPosition, "stairs_down", exitDirection, command.stairs)
    command:yield()
end

