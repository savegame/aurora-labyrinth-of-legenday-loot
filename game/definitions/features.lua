local Array = require("utils.classes.array")
local Range = require("utils.classes.range")
local Vector = require("utils.classes.vector")
local RollTable = require("utils.classes.roll_table")
local FeatureDef = require("structures.feature_def")
local LogicMethods = require("logic.methods")
local FEATURES = RollTable:new()
local SPIKE_HORIZONTAL = FeatureDef:new(Range:new(1, 25), 5, math.huge, 1, 1)
FEATURES:addResult(1, SPIKE_HORIZONTAL)
SPIKE_HORIZONTAL.fillCallback = function(rng, currentFloor, level, rect, room)
    local holeStart = rect.x + rng:random(1, rect.width - 4)
    for position in rect:gridIteratorV() do
        if not within(position.x, holeStart, holeStart + 2) then
            level:setObject(position, "spikes", currentFloor)
        end

    end

end
SPIKE_HORIZONTAL.roomRectMode = Tags.ROOM_RECT_EDGE_DOOR_DIVIDING
local SPIKE_VERTICAL = FeatureDef:new(Range:new(1, 25), 1, 1, 5, math.huge)
FEATURES:addResult(1, SPIKE_VERTICAL)
SPIKE_VERTICAL.fillCallback = function(rng, currentFloor, level, rect, room)
    local holeStart = rect.y + rng:random(1, rect.height - 4)
    for position in rect:gridIteratorV() do
        if not within(position.y, holeStart, holeStart + 2) then
            level:setObject(position, "spikes", currentFloor)
        end

    end

end
SPIKE_VERTICAL.roomRectMode = Tags.ROOM_RECT_EDGE_DOOR_DIVIDING
local SPIKE_SQUARE = FeatureDef:new(Range:new(1, 25), 2, 2, 2, 2)
FEATURES:addResult(1, SPIKE_SQUARE)
SPIKE_SQUARE.fillCallback = function(rng, currentFloor, level, rect, room)
    for position in rect:gridIteratorV() do
        level:setObject(position, "spikes", currentFloor)
    end

end
SPIKE_SQUARE.roomRectMode = Tags.ROOM_RECT_NON_SIDE
local POOL_SQUARE = FeatureDef:new(Range:new(1, 25), 2, 2, 2, 2)
FEATURES:addResult(1, POOL_SQUARE)
POOL_SQUARE.fillCallback = function(rng, currentFloor, level, rect, room)
    for position in rect:gridIteratorV() do
        level:setObject(position, "acid_pool_permanent", currentFloor)
    end

end
POOL_SQUARE.roomRectMode = Tags.ROOM_RECT_NON_SIDE
local GREEN_CAULDRON = FeatureDef:new(Range:new(1, 25), 1, 1, 1, 1)
FEATURES:addResult(1, GREEN_CAULDRON)
GREEN_CAULDRON.fillCallback = function(rng, currentFloor, level, rect, room)
    level:setObject(rect:discreteCenter(), "destructibles.green_cauldron", currentFloor)
end
GREEN_CAULDRON.roomRectMode = Tags.ROOM_RECT_NON_SIDE
local RED_CAULDRON = FeatureDef:new(Range:new(5, 25), 1, 1, 1, 1)
FEATURES:addResult(1, RED_CAULDRON)
RED_CAULDRON.fillCallback = function(rng, currentFloor, level, rect, room)
    level:setObject(rect:discreteCenter(), "destructibles.red_cauldron", currentFloor)
end
RED_CAULDRON.roomRectMode = Tags.ROOM_RECT_NON_SIDE
local POT_HOLDER = FeatureDef:new(Range:new(1, 25), 5, 5, 5, 5)
FEATURES:addResult(1, POT_HOLDER)
POT_HOLDER.fillCallback = function(rng, currentFloor, level, rect, room)
    room.itemHolder = Vector:new(rect:discreteCenter())
    for position in rect:sizeAdjusted(-1):gridIteratorV() do
        if position ~= room.itemHolder then
            level:setObject(position, "destructibles.pot", currentFloor, 1)
        end

    end

end
POT_HOLDER.isItemHolder = true
local SPIKE_HOLDER = FeatureDef:new(Range:new(1, 25), 3, 3, 3, 3)
FEATURES:addResult(1, SPIKE_HOLDER)
SPIKE_HOLDER.fillCallback = function(rng, currentFloor, level, rect, room)
    local center = rect:discreteCenter()
    local directions = DIRECTIONS:clone()
    local path1 = DIRECTIONS_AA:randomValue(rng)
    directions:delete(path1)
    for direction in directions() do
        level:setObject(center + Vector[direction], "spikes", currentFloor)
    end

    room.itemHolder = center
end
SPIKE_HOLDER.roomRectMode = Tags.ROOM_RECT_NON_SIDE
SPIKE_HOLDER.isItemHolder = true
local MANA_FOUNTAIN = FeatureDef:new(Range:new(1, 25), 1, 1, 1, 1)
FEATURES:addResult(2, MANA_FOUNTAIN)
MANA_FOUNTAIN.fillCallback = function(rng, currentFloor, level, rect, room)
    level:setObject(rect:discreteCenter(), "mana_fountain", currentFloor)
end
MANA_FOUNTAIN.roomRectMode = Tags.ROOM_RECT_NON_SIDE
MANA_FOUNTAIN.maxOne = true
local RED_BARREL = FeatureDef:new(Range:new(1, 25), 1, 1, 1, 1)
FEATURES:addResult(1, RED_BARREL)
RED_BARREL.fillCallback = function(rng, currentFloor, level, rect, room)
    level:setObject(rect:discreteCenter(), "destructibles.red_barrel", currentFloor)
end
RED_BARREL.roomRectMode = Tags.ROOM_RECT_NON_SIDE
local BLUE_BARREL = FeatureDef:new(Range:new(9, 20), 1, 1, 1, 1)
FEATURES:addResult(1, BLUE_BARREL)
BLUE_BARREL.fillCallback = function(rng, currentFloor, level, rect, room)
    level:setObject(rect:discreteCenter(), "destructibles.blue_barrel", currentFloor)
end
BLUE_BARREL.roomRectMode = Tags.ROOM_RECT_NON_SIDE
local PURPLE_BARREL = FeatureDef:new(Range:new(1, 25), 1, 1, 1, 1)
FEATURES:addResult(1, PURPLE_BARREL)
PURPLE_BARREL.fillCallback = function(rng, currentFloor, level, rect, room)
    level:setObject(rect:discreteCenter(), "destructibles.purple_barrel", currentFloor)
end
PURPLE_BARREL.roomRectMode = Tags.ROOM_RECT_NON_SIDE
local FIRE_RIVER_HORIZONTAL = FeatureDef:new(Range:new(13, 25), 5, math.huge, 1, 1)
FEATURES:addResult(1, FIRE_RIVER_HORIZONTAL)
FIRE_RIVER_HORIZONTAL.fillCallback = function(rng, currentFloor, level, rect, room)
    local duration = rect.width - 3
    for position in rect:gridIteratorV() do
        level:setObject(position, "fire_summoner", currentFloor, duration + 3, duration, position.x - rect.x + 1)
    end

end
FIRE_RIVER_HORIZONTAL.roomRectMode = Tags.ROOM_RECT_EDGE_DOOR_DIVIDING
local FIRE_RIVER_VERTICAL = FeatureDef:new(Range:new(5, 25), 1, 1, 5, math.huge)
FEATURES:addResult(1, FIRE_RIVER_VERTICAL)
FIRE_RIVER_VERTICAL.fillCallback = function(rng, currentFloor, level, rect, room)
    local duration = rect.height - 3
    for position in rect:gridIteratorV() do
        level:setObject(position, "fire_summoner", currentFloor, duration + 3, duration, position.y - rect.y + 1)
    end

end
FIRE_RIVER_VERTICAL.roomRectMode = Tags.ROOM_RECT_EDGE_DOOR_DIVIDING
local FIRE_HOLDER = FeatureDef:new(Range:new(5, 25), 3, 3, 3, 3)
FEATURES:addResult(1, FIRE_HOLDER)
FIRE_HOLDER.fillCallback = function(rng, currentFloor, level, rect, room)
    local center = rect:discreteCenter()
    local offset = rng:random(1, DIRECTIONS:size())
    for i, direction in ipairs(DIRECTIONS) do
        level:setObject(center + Vector[direction], "fire_summoner", currentFloor, DIRECTIONS:size(), DIRECTIONS:size() - 4, modAdd(i, offset, DIRECTIONS:size()))
    end

    room.itemHolder = center
end
FIRE_HOLDER.roomRectMode = Tags.ROOM_RECT_NON_SIDE
FIRE_HOLDER.isItemHolder = true
local ROCKS_HORIZONTAL = FeatureDef:new(Range:new(21, 25), 5, math.huge, 1, 1)
FEATURES:addResult(1, ROCKS_HORIZONTAL)
ROCKS_HORIZONTAL.fillCallback = function(rng, currentFloor, level, rect, room)
    local hole1 = rect.x + rng:random(1, rect.width - 2)
    local hole2 = rect.x + rng:random(1, rect.width - 3)
    if hole2 >= hole1 then
        hole2 = hole2 + 1
    end

    local health = LogicMethods.getDestructibleHealth(currentFloor)
    for position in rect:gridIteratorV() do
        if position.x ~= hole1 and position.x ~= hole2 then
            if rng:random() < 0.85 then
                level:setObject(position, "rock", health, true, rng:random(1, 4))
            end

        end

    end

end
ROCKS_HORIZONTAL.roomRectMode = Tags.ROOM_RECT_EDGE_DOOR_DIVIDING
local ROCKS_VERTICAL = FeatureDef:new(Range:new(21, 25), 1, 1, 5, math.huge)
FEATURES:addResult(1, ROCKS_VERTICAL)
ROCKS_VERTICAL.fillCallback = function(rng, currentFloor, level, rect, room)
    local hole1 = rect.y + rng:random(1, rect.height - 2)
    local hole2 = rect.y + rng:random(1, rect.height - 3)
    if hole2 >= hole1 then
        hole2 = hole2 + 1
    end

    local health = LogicMethods.getDestructibleHealth(currentFloor)
    for position in rect:gridIteratorV() do
        if position.y ~= hole1 and position.y ~= hole2 then
            if rng:random() < 0.85 then
                level:setObject(position, "rock", health, true, rng:random(1, 4))
            end

        end

    end

end
ROCKS_VERTICAL.roomRectMode = Tags.ROOM_RECT_EDGE_DOOR_DIVIDING
return FEATURES

