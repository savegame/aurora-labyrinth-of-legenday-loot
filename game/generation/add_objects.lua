local OBJECTS = require("definitions.objects")
local FEATURES = require("definitions.features")
local Set = require("utils.classes.set")
local Vector = require("utils.classes.vector")
local LogicMethods = require("logic.methods")
local MIN_OBJECTS = 2
local MAX_FEATURES = 1
local MAX_OBJECT_TRIES = 20
local MAX_BLOCKER_TRIES = 20
local function fillRoomWithObjects(command, room)
    local rng = command.rng
    local level = command.level
    local triesSinceLastObject = 0
    local countObjects = 0
    while true do
        local object = OBJECTS:roll(rng)
        if object.floors:contains(command.currentFloor) then
            local outerRect = room:getUnoccupiedRect(rng, object:evaluateExpandedDimensions(rng))
                        if outerRect then
                local innerRect = outerRect:sizeAdjusted(-1)
                for position in innerRect:gridIteratorV() do
                    level:setObject(position, "destructibles." .. object.prefab, command.currentFloor, object:evaluateArgs(rng))
                end

                countObjects = countObjects + 1
                triesSinceLastObject = 0
                command:yieldIfDisplay()
            elseif countObjects >= MIN_OBJECTS then
                break
            else
                triesSinceLastObject = triesSinceLastObject + 1
                if triesSinceLastObject >= MAX_OBJECT_TRIES then
                    break
                end

            end

            command:yieldIfNotDisplay()
        end

    end

end

local function fillRoomWithFeatures(command, room, takenFeatures)
    local rng = command.rng
    local countFeatures = 0
    local triesSinceLastFeature = 0
    while countFeatures < MAX_FEATURES do
        local feature = FEATURES:roll(rng)
        if not room.isStart or not feature.isItemHolder then
            if feature.floors:contains(command.currentFloor) and ((not feature.maxOne) or (not takenFeatures:contains(feature))) then
                local width, height = feature:evaluateDimensions(rng)
                local innerRect = false
                                if width == math.huge then
                    innerRect = room:getUnoccupiedHorizontal(rng, feature.minWidth, height, feature.roomRectMode or Tags.ROOM_RECT_EDGE_ALLOWED)
                elseif height == math.huge then
                    innerRect = room:getUnoccupiedVertical(rng, feature.minHeight, width, feature.roomRectMode or Tags.ROOM_RECT_EDGE_ALLOWED)
                else
                    innerRect = room:getUnoccupiedRect(rng, width, height, feature.roomRectMode)
                end

                if innerRect then
                    feature.fillCallback(rng, command.currentFloor, command.level, innerRect, room)
                    countFeatures = countFeatures + 1
                    triesSinceLastFeature = 0
                    takenFeatures:add(feature)
                    command:yieldIfDisplay()
                end

                triesSinceLastFeature = triesSinceLastFeature + 1
                if triesSinceLastFeature >= MAX_OBJECT_TRIES then
                    break
                end

            end

        end

    end

end

return function(command)
    local takenFeatures = Set:new()
    for room in command.rooms() do
        fillRoomWithFeatures(command, room, takenFeatures)
        fillRoomWithObjects(command, room)
    end

    if command.rng:random() < 0.5 then
        local foundHall = false
        local isEarth = false
                if command.currentFloor >= 13 and command.currentFloor <= 16 then
            isEarth = true
        elseif command.currentFloor >= 21 and command.currentFloor <= 24 then
            isEarth = true
        end

        local tries = 0
        while not foundHall and tries < MAX_BLOCKER_TRIES do
            tries = tries + 1
            local position = command.level.hallPositions:randomValue(command.rng)
            local tiles = command.level.tiles
            local hasRoom = false
            for direction in DIRECTIONS_AA() do
                if tiles:get(position + Vector[direction]).isRoom then
                    hasRoom = true
                    break
                end

            end

            if not hasRoom then
                for direction in DIRECTIONS_AA() do
                    if tiles:get(position - Vector[direction]).isBlocking then
                        if not tiles:get(position + Vector[direction]).isBlocking then
                            if tiles:get(position + Vector[direction] * 2).isBlocking then
                                foundHall = true
                                local health = LogicMethods.getDestructibleHealth(command.currentFloor)
                                command.level:setObject(position, "rock", health, isEarth)
                                command.level:setObject(position + Vector[direction], "rock", health, isEarth)
                            end

                        end

                    end

                    if foundHall then
                        break
                    end

                end

            end

        end

    end

end

