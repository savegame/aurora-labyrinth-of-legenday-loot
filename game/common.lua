local Common = {  }
local Global = require("global")
local Vector = require("utils.classes.vector")
local Array = require("utils.classes.array")
local ConvertNumber = require("utils.algorithms.convert_number")
local EASING = require("draw.easing")
local DrawMethods = require("draw.methods")
local MEASURES = require("draw.measures")
local CONSTANTS = require("logic.constants")
local TERMS = require("text.terms")
local MINOR_RNG = Utils.createRandomGenerator()
function Common.getMinorRNG()
    return MINOR_RNG
end

function Common.getKeyName(code)
    if PortSettings.IS_MOBILE then
                                                        if code == Tags.KEYCODE_UP then
            return "{I:UP}"
        elseif code == Tags.KEYCODE_DOWN then
            return "{I:DOWN}"
        elseif code == Tags.KEYCODE_LEFT then
            return "{I:LEFT}"
        elseif code == Tags.KEYCODE_RIGHT then
            return "{I:RIGHT}"
        elseif code == Tags.KEYCODE_WAIT then
            return "{I:WAIT}"
        elseif code == Tags.KEYCODE_EQUIPMENT then
            return "{I:EQUIPMENT}"
        elseif code == Tags.KEYCODE_KEYWORDS then
            return "{I:KEYWORDS}"
        end

    end

    return Global:get(Tags.GLOBAL_PROFILE):getKeyName(code)
end

function Common.playSFX(sfx, pitchMultiplier, volumeMultiplier)
    return Global:get(Tags.GLOBAL_AUDIO):playSFX(sfx, pitchMultiplier, volumeMultiplier)
end

function Common.playStinger(bgm)
    return Global:get(Tags.GLOBAL_AUDIO):playBGM(bgm)
end

function Common.getSpriteFrame(timePassed)
    local DURATION = MEASURES.FRAME_ANIMATION
    return floor((timePassed % DURATION) / (DURATION / 2))
end

function Common.getPulseOpacity(timePassed, minOpacity, maxOpacity)
    return DrawMethods.getPulseOpacity(timePassed, MEASURES.FRAME_ANIMATION, minOpacity, maxOpacity)
end

function Common.isElite(entity)
    if not entity then
        return false
    end

    return entity:hasComponent("elite") or entity:hasComponent("finalboss")
end

function Common.getPositionComponent(entity)
                    if entity:hasComponent("body") then
        return entity.body
    elseif entity:hasComponent("steppable") then
        return entity.steppable
    elseif entity:hasComponent("stepinteractive") then
        return entity.stepinteractive
    elseif entity:hasComponent("position") then
        return entity.position
    elseif entity:hasComponent("projectile") then
        return entity.projectile
    else
        return false
    end

end

function Common.getDiagonalDirections(direction)
                if direction == RIGHT then
        return Array:new(UP_RIGHT, DOWN_RIGHT)
    elseif direction == DOWN then
        return Array:new(DOWN_RIGHT, DOWN_LEFT)
    elseif direction == LEFT then
        return Array:new(DOWN_LEFT, UP_LEFT)
    elseif direction == UP then
        return Array:new(UP_LEFT, UP_RIGHT)
    else
        Utils.assert(false, "No diagonal directions for: %d", direction)
    end

end

local DIRECTIONS_PREFERRED = Array:new(RIGHT, LEFT, DOWN, UP)
local DIAGONAL_PREFERRED = Array:new(RIGHT, LEFT, DOWN, UP, DOWN_RIGHT, DOWN_LEFT, UP_RIGHT, UP_LEFT)
function Common.getDirectionTowards(position, target, rng, includeDiagonals)
    local directions = DIRECTIONS_PREFERRED
    if includeDiagonals then
        directions = DIAGONAL_PREFERRED
    end

    if rng then
        directions = directions:shuffle(rng)
    end

    return directions:minValue(function(d1, d2)
        return (position + Vector[d1]):distanceEuclidean(target) < (position + Vector[d2]):distanceEuclidean(target)
    end)
end

function Common.getDirectionTowardsMultiple(position, target)
    local directions = DIRECTIONS_PREFERRED
    local distance = position:distanceEuclidean(target)
    directions = directions:reject(function(direction)
        return (position + Vector[direction]):distanceEuclidean(target) >= distance
    end)
    directions:stableSortSelf(function(d1, d2)
        return (position + Vector[d1]):distanceEuclidean(target) < (position + Vector[d2]):distanceEuclidean(target)
    end)
    return directions
end

function Common.getDirectionTowardsEntity(sourceEntity, targetEntity, rng, includeDiagonals)
    local sourcePosition = Common.getPositionComponent(sourceEntity):getPosition()
    local targetPosition = Common.getPositionComponent(targetEntity):getPosition()
    return Common.getDirectionTowards(sourcePosition, targetPosition, rng, includeDiagonals)
end

Common.HORIZONTAL = Array:new(LEFT, RIGHT)
Common.VERTICAL = Array:new(UP, DOWN)
function Common.getOrthogonalDirections(direction)
    if Common.HORIZONTAL:contains(direction) then
        return Common.VERTICAL
    else
        return Common.HORIZONTAL
    end

end

function Common.convertLevelToRange(range, level)
    local ratio = level / CONSTANTS.ITEM_UPGRADE_LEVELS
    return range.min + (range.max - range.min) * ratio
end

function Common.getIOQuadInverseDurations(moments)
    Utils.assert(moments[1] ~= 0, "getIOQ inverse moments[1] should not be 0")
    local times = Array:new(0)
    times:concat(moments)
    times = times:map(EASING.IN_OUT_QUAD_INVERSE)
    local result = Array:new()
    for i = 1, moments:size() do
        result:push(times[i + 1] - times[i])
    end

    return result
end

function Common.getInverseDurations(moments, inverseFn)
    Utils.assert(moments[1] ~= 0, "getInverseDurations moments[1] should not be 0")
    local times = Array:new(0)
    times:concat(moments)
    times = times:map(inverseFn)
    local result = Array:new()
    for i = 1, moments:size() do
        result:push(times[i + 1] - times[i])
    end

    return result
end

local VARIANCE_LOW = CONSTANTS.DAMAGE_VARIANCE_LOW
local VARIANCE_HIGH = CONSTANTS.DAMAGE_VARIANCE_HIGH
function Common.getVarianceForRatio(ratio)
    return (VARIANCE_HIGH - VARIANCE_LOW) * ratio + VARIANCE_LOW
end

function Common.getDifficultyText(difficulty)
                    if difficulty == Tags.DIFFICULTY_EASY then
        return "{C:EASY}" .. TERMS.UI.OPTIONS_DIFFICULTY[1]
    elseif difficulty == Tags.DIFFICULTY_NORMAL then
        return "{C:NORMAL}" .. TERMS.UI.OPTIONS_DIFFICULTY[2]
    elseif difficulty == Tags.DIFFICULTY_HARD then
        return "{C:HARD}" .. TERMS.UI.OPTIONS_DIFFICULTY[3]
    elseif difficulty == Tags.DIFFICULTY_VERY_HARD then
        return "{C:VERY_HARD}" .. TERMS.UI.OPTIONS_DIFFICULTY[4]
    elseif difficulty >= Tags.DIFFICULTY_IMPOSSIBLE then
        return "{C:IMPOSSIBLE}" .. TERMS.UI.OPTIONS_DIFFICULTY[5]
    end

end

return Common

