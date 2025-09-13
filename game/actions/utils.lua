local ActionUtils = {  }
local Common = require("common")
local TERMS = require("text.terms")
local Array = require("utils.classes.array")
local Vector = require("utils.classes.vector")
local SparseGrid = require("utils.classes.sparse_grid")
local BUFFS = require("definitions.buffs")
function ActionUtils.actionWithMeleeDamage(actionClass)
    local newActionClass = class("actions.base_attack")
    function newActionClass:initialize(entity, direction, abilityStats)
        newActionClass:super(self, "initialize", entity, direction, abilityStats)
        self.speedMultiplier = 1
    end

    function newActionClass:speedMultiply(factor)
        self.speedMultiplier = self.speedMultiplier * factor
    end

    function newActionClass:getTargetPosition(hit)
        return hit.sourcePosition + Vector[self.direction]
    end

    function newActionClass:decorateAction(action)
    end

    function newActionClass:process(currentEvent)
        local action = self.entity.actor:create(actionClass, self.direction, self.abilityStats)
        if self.speedMultiplier ~= 1 then
            action:speedMultiply(self.speedMultiplier)
        end

        self:decorateAction(action)
        return action:parallelChainEvent(currentEvent):chainEvent(function(_, anchor)
            local hit = self:createHit()
            hit:applyToPosition(anchor, self:getTargetPosition(hit))
        end)
    end

    return newActionClass
end

local function addIfAnyAdjacent(result, body, previousOccupied, nextOccupied, position)
    if body:canBePassable(position) then
        for direction in DIRECTIONS_AA() do
            if previousOccupied:get(position + Vector[direction]) then
                result:push(position)
                nextOccupied:set(position, true)
                return 
            end

        end

    end

end

function ActionUtils.getAreaPositions(entity, origin, area, excludeOrigin)
    local result = Array:new()
    local occupied = SparseGrid:new(false)
    local body = entity.body
    if not excludeOrigin then
        if body:canBePassable(origin) then
            result:push(origin)
            occupied:set(origin, true)
        end

    end

    if area >= Tags.ABILITY_AREA_CROSS then
        for direction in DIRECTIONS_AA() do
            local target = origin + Vector[direction]
            if body:canBePassable(target) then
                result:push(target)
                occupied:set(target, true)
            end

        end

    end

    if area >= Tags.ABILITY_AREA_3X3 then
        local nextOccupied = occupied:clone()
        for direction in DIRECTIONS_DIAGONAL() do
            addIfAnyAdjacent(result, body, occupied, nextOccupied, origin + Vector[direction])
        end

        occupied = nextOccupied
    end

    if area >= Tags.ABILITY_AREA_ROUND_5X5 then
        local nextOccupied = occupied:clone()
        for direction in DIRECTIONS_AA() do
            addIfAnyAdjacent(result, body, occupied, nextOccupied, origin + Vector[direction] * 2)
            addIfAnyAdjacent(result, body, occupied, nextOccupied, origin + Vector[direction] * 2 + Vector[cwDirection(direction)])
            addIfAnyAdjacent(result, body, occupied, nextOccupied, origin + Vector[direction] * 2 + Vector[ccwDirection(direction)])
        end

        occupied = nextOccupied
    end

    if area >= Tags.ABILITY_AREA_OCTAGON_7X7 then
        local nextOccupied = occupied:clone()
        for direction in DIRECTIONS_AA() do
            addIfAnyAdjacent(result, body, occupied, nextOccupied, origin + Vector[direction] * 3)
            addIfAnyAdjacent(result, body, occupied, nextOccupied, origin + Vector[direction] * 3 + Vector[cwDirection(direction)])
            addIfAnyAdjacent(result, body, occupied, nextOccupied, origin + Vector[direction] * 3 + Vector[ccwDirection(direction)])
        end

        for direction in DIRECTIONS_DIAGONAL() do
            addIfAnyAdjacent(result, body, occupied, nextOccupied, origin + Vector[direction] * 2)
        end

        occupied = nextOccupied
    end

    return result
end

function ActionUtils.indicateExtendableAttack(entity, direction, abilityStats, castingGuide, noMoveTo)
    local front = entity.body:getPosition() + Vector[direction]
    if entity.body:isPassable(front) then
        local extendedTarget = front + Vector[direction]
        local property = entity.stats:getExtenderProperty()
                        if property == Tags.STAT_LUNGE then
            if noMoveTo then
                castingGuide:indicateWeak(front)
            else
                castingGuide:indicateMoveTo(front)
            end

            castingGuide:indicate(front + Vector[direction])
            return front + Vector[direction]
        elseif property == Tags.STAT_REACH and entity.body:canBePassable(extendedTarget) then
            castingGuide:indicateWeak(front)
            castingGuide:indicate(front + Vector[direction])
            return front + Vector[direction]
        elseif entity.stats:has(Tags.STAT_PUSH_ATTACK) and entity.body:hasEntityWithAgent(extendedTarget) then
            if not noMoveTo then
                castingGuide:indicateMoveTo(front)
            end

        end

    end

    castingGuide:indicate(front)
    return front
end

function ActionUtils.indicateArea(entity, origin, area, castingGuide, excludeOrigin, isWeak)
    for position in (ActionUtils.getAreaPositions(entity, origin, area, excludeOrigin))() do
        if isWeak then
            castingGuide:indicateWeak(position)
        else
            castingGuide:indicate(position)
        end

    end

end

function ActionUtils.indicateProjectile(entity, direction, abilityStats, castingGuide, source, projectileSpeed)
    if not source then
        source = entity.body:getPosition()
    end

    if not projectileSpeed then
        projectileSpeed = abilityStats:get(Tags.STAT_ABILITY_PROJECTILE_SPEED)
    end

    if isDiagonal(direction) then
        projectileSpeed = round(projectileSpeed / math.sqrtOf2)
    end

    local distance = 1
    local target = source + Vector[direction]
    while entity.vision:isVisible(target) and entity.body:canBePassable(target) do
        if distance <= projectileSpeed and not entity.body:isPassable(target) then
            castingGuide:indicate(target)
            return target
        else
            castingGuide:indicateWeak(target)
        end

        distance = distance + 1
        target = target + Vector[direction]
    end

    return false
end

function ActionUtils.getCleavePositions(origin, area, direction)
    local vDirection = Vector[direction]
    if area == 4 then
        local positions = Array:new()
        positions:push(origin + Vector[UP])
        positions:push(origin + vDirection)
        positions:push(origin + Vector[DOWN])
        positions:push(origin + Vector[reverseDirection(direction)])
        return positions
    end

    local offsets = Array:new()
    local vCwDirection = Vector[cwDirection(direction)]
    local vCcwDirection = Vector[ccwDirection(direction)]
    offsets:push(vDirection + vCwDirection)
    offsets:push(vDirection)
    offsets:push(vDirection + vCcwDirection)
    if area >= 5 then
        offsets:pushFirst(vCwDirection)
        offsets:push(vCcwDirection)
    end

    if area >= 7 then
        offsets:pushFirst(vCwDirection - vDirection)
        offsets:push(vCcwDirection - vDirection)
    end

    if area == 8 then
        offsets:push(-vDirection)
    end

    return offsets:map(function(offset)
        return origin + offset
    end)
end

function ActionUtils.getDashMoveTo(entity, direction, abilityStats)
    local range = abilityStats:get(Tags.STAT_ABILITY_RANGE)
    local moveTo = entity.body:getPosition()
    for i = 1, range + 1 do
        moveTo = moveTo + Vector[direction]
        if not entity.body:isPassable(moveTo) or not entity.vision:isVisible(moveTo) then
            break
        end

    end

    return moveTo - Vector[direction]
end

function ActionUtils.getUnblockedDashMoveTo(entity, direction, abilityStats)
    local source = entity.body:getPosition()
    local maxRange = 0
    for i = 1, abilityStats:get(Tags.STAT_ABILITY_RANGE) do
        local target = source + Vector[direction] * i
        if entity.body:canBePassable(target) and entity.vision:isVisible(target) then
            maxRange = i
        else
            break
        end

    end

    for i = maxRange, 1, -1 do
        local target = source + Vector[direction] * i
        if entity.body:isPassable(target) then
            return target
        end

    end

    return false
end

function ActionUtils.getRandomAttackDirection(rng, entity, isAttackValid)
    local directions = DIRECTIONS_AA
    if rng then
        directions = directions:shuffle(rng)
    end

    local body = entity.body
    isAttackValid = isAttackValid or alwaysTrue
    for direction in directions() do
        local entityAt = body:getEntityAt(body:getPosition() + Vector[direction])
        if ActionUtils.isAliveAgent(entityAt) and isAttackValid(entityAt, direction, entity) then
            return direction
        end

    end

    local extenderProperty = entity.stats:getExtenderProperty()
    for direction in directions() do
        if extenderProperty and body:isPassable(body:getPosition() + Vector[direction]) then
            local entityAt = body:getEntityAt(body:getPosition() + Vector[direction] * 2)
            if ActionUtils.isAliveAgent(entityAt) and isAttackValid(entityAt, direction, entity) then
                return direction
            end

        end

    end

    return false
end

function ActionUtils.getTriangleBreathPositions(source, direction)
    local positions = Array:new()
    local current = source + Vector[direction]
    positions:push(current)
    current = current + Vector[direction]
    positions:push(current)
    positions:push(current + Vector[cwDirection(direction)])
    positions:push(current + Vector[ccwDirection(direction)])
    return positions
end

function ActionUtils.getEntityWithinRange(entity, direction, abilityStats, condition, checkBlock)
    local range = abilityStats:get(Tags.STAT_ABILITY_RANGE, 1)
    local rangeMin = abilityStats:get(Tags.STAT_ABILITY_RANGE_MIN, 1)
    local body = entity.body
    if checkBlock then
        for i = 1, rangeMin - 1 do
            local target = body:getPosition() + Vector[direction] * i
            if not body:isPassable(target) then
                return false, true
            end

        end

    end

    for i = rangeMin, range do
        local target = body:getPosition() + Vector[direction] * i
        if not entity.vision:isVisible(target) then
            return false
        end

        local entityAt = body:getEntityAt(target)
        if entityAt and condition(entityAt) then
            return entityAt
        end

                if checkBlock and not body:isPassable(target) then
            return false, true
        elseif not body:canBePassable(target) then
            return false, i == rangeMin
        end

    end

    return false
end

function ActionUtils.isAliveAgent(entity)
    if not entity then
        return false
    end

    if entity:hasComponent("agent") then
        if entity.tank:getCurrent() > 0 then
            return not entity.tank.hasDiedOnce
        end

    end

    return false
end

local function hasAgent(entity)
    return entity:hasComponent("agent")
end

local function hasTank(entity)
    return entity:hasComponent("tank")
end

function ActionUtils.getEnemyWithinRange(entity, direction, abilityStats, checkBlock)
    return ActionUtils.getEntityWithinRange(entity, direction, abilityStats, hasAgent, checkBlock)
end

function ActionUtils.getTargetWithinRange(entity, direction, abilityStats, checkBlock)
    return ActionUtils.getEntityWithinRange(entity, direction, abilityStats, hasTank, checkBlock)
end

function ActionUtils.getInvalidReasonEnemy(entity, direction, abilityStats, checkBlock)
    local hasEnemy, isBlocked = ActionUtils.getEnemyWithinRange(entity, direction, abilityStats, checkBlock)
        if isBlocked then
        return TERMS.INVALID_DIRECTION_BLOCKED
    elseif not hasEnemy then
        return TERMS.INVALID_DIRECTION_NO_ENEMY
    else
        return false
    end

end

function ActionUtils.getInvalidReasonTarget(entity, direction, abilityStats, checkBlock)
    local hasTarget, isBlocked = ActionUtils.getTargetWithinRange(entity, direction, abilityStats, checkBlock)
        if isBlocked then
        return TERMS.INVALID_DIRECTION_BLOCKED
    elseif not hasTarget then
        return TERMS.INVALID_DIRECTION_NO_TARGET
    else
        return false
    end

end

function ActionUtils.getInvalidReasonEnemyAttack(entity, direction, abilityStats)
    local newAbilityStats = abilityStats:clone()
    newAbilityStats:set(Tags.STAT_ABILITY_RANGE_MIN, 1)
    if entity.stats:getExtenderProperty() then
        newAbilityStats:set(Tags.STAT_ABILITY_RANGE, 2)
    else
        newAbilityStats:set(Tags.STAT_ABILITY_RANGE, 1)
    end

    return ActionUtils.getInvalidReasonEnemy(entity, direction, newAbilityStats, true)
end

function ActionUtils.getInvalidReasonFrontCantBePassable(entity, direction, abilityStats)
    if not entity.body:canBePassableDirection(direction) then
        return TERMS.INVALID_DIRECTION_BLOCKED
    else
        return false
    end

end

function ActionUtils.getInvalidReasonFrontIsNotPassable(entity, direction, abilityStats)
    if not entity.body:isPassableDirection(direction) then
        return TERMS.INVALID_DIRECTION_BLOCKED
    else
        return false
    end

end

function ActionUtils.indicateSelf(entity, direction, abilityStats, castingGuide)
    castingGuide:indicate(entity.body:getPosition())
end

function ActionUtils.indicateEntityWithinRange(entity, direction, abilityStats, castingGuide, condition, checkBlock)
    local entityAt, isBlocked = ActionUtils.getEntityWithinRange(entity, direction, abilityStats, condition, checkBlock)
    local range = abilityStats:get(Tags.STAT_ABILITY_RANGE, 1)
    local rangeMin = abilityStats:get(Tags.STAT_ABILITY_RANGE_MIN, 1)
    local source = entity.body:getPosition()
    for i = rangeMin, range do
        local target = source + Vector[direction] * i
        if not entity.vision:isVisible(target) then
            break
        end

        if entityAt and target == entityAt.body:getPosition() then
            break
        end

                if checkBlock and not entity.body:isPassable(target) then
            break
        elseif not entity.body:canBePassable(target) then
            break
        end

        castingGuide:indicateWeak(target)
    end

    if entityAt then
        castingGuide:indicate(entityAt.body:getPosition())
    end

    return entityAt
end

function ActionUtils.indicateEnemyWithinRange(entity, direction, abilityStats, castingGuide, checkBlock)
    return ActionUtils.indicateEntityWithinRange(entity, direction, abilityStats, castingGuide, hasAgent, checkBlock)
end

function ActionUtils.indicateTargetWithinRange(entity, direction, abilityStats, castingGuide, checkBlock)
    return ActionUtils.indicateEntityWithinRange(entity, direction, abilityStats, castingGuide, hasTank, checkBlock)
end

function ActionUtils.deathCasterPreDeath(entity, killingHit)
    if killingHit and killingHit:hasActionDisabling() or not entity.buffable:canAct() then
        entity.tank.preDeath = doNothing
        return 
    end

    if entity.caster:canCast() then
        entity.tank:restoreToFull()
        local player = entity.agent:getPlayer()
        if player then
            entity.caster:prepareAction(Common.getDirectionTowardsEntity(entity, player))
        end

        entity.agent.hasActedThisTurn = true
        entity.agent.isRattled = killingHit.turnSkip
        entity.buffable:forceApply(BUFFS:get("ON_DEATH_IMMORTALITY"):new(math.huge))
        entity.tank.preDeath = doNothing
    end

end

return ActionUtils

