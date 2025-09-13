local Agent = require("components.create_class")()
local SparseGrid = require("utils.classes.sparse_grid")
local Vector = require("utils.classes.vector")
local Array = require("utils.classes.array")
local PathFinder = require("utils.algorithms.path_finder")
local ACTIONS_BASIC = require("actions.basic")
local Common = require("common")
local CONSTANTS = require("logic.constants")
local MAX_PATH = 30
function Agent:initialize(entity)
    Agent:super(self, "initialize")
    Debugger.assertComponent(entity, "body")
    Debugger.assertComponent(entity, "buffable")
    Debugger.assertComponent(entity, "tank")
    entity.tank.drawBar = true
    self._entity = entity
    self._body = entity.body
    self.hasSeenPlayer = false
    self.hasActedThisTurn = false
    self.isRattled = false
    self.priorityAction = false
    self.avoidsReserved = true
    entity:callIfHasComponent("serializable", "addComponent", "agent")
end

function Agent:toData()
    return { hasSeenPlayer = self.hasSeenPlayer, isRattled = self.isRattled }
end

function Agent:fromData(data)
    self.isRattled = data.isRattled
    self.hasSeenPlayer = data.hasSeenPlayer
end

function Agent:hasRangedAttack()
    return self._entity:hasComponent("ranged") and self._entity.ranged:willAttackSoon()
end

function Agent:hasMeleeAttack()
    return self._entity:hasComponent("melee") and self._entity.melee.enabled
end

function Agent:getAlignDistance(player)
    local alignDistance = 1
    if self:hasRangedAttack() then
        alignDistance = max(alignDistance, self._entity.ranged.range)
    end

    if self._entity:hasComponent("caster") then
        local caster = self._entity.caster
        if caster.alignWhenNotReady or caster:readyAtEOT() then
            alignDistance = max(alignDistance, self._entity.caster.alignDistance)
        end

    end

    if alignDistance > 1 then
        return alignDistance
    else
        return false
    end

end

function Agent:getActionWithPath(path, position, playerPosition)
    if path and path:size() > 1 then
        local target = path[2]
        local direction = Common.getDirectionTowards(position, target)
        local entityAt = self._body:getEntityAt(target)
        if entityAt then
            if entityAt:hasComponent("tank") and not entityAt:hasComponent("agent") then
                                if self:hasMeleeAttack() then
                    return self._entity.melee:createAction(direction)
                elseif self:hasRangedAttack() and self._entity.ranged:isReady() then
                    self._entity.ranged:setOnCooldown()
                    return self._entity.ranged:createAction(direction)
                end

            else
                return self._entity.actor:createWait()
            end

        else
            return self._entity.actor:createMove(direction)
        end

    end

    return false
end

function Agent:getActionAligned(position, playerPosition, alignDistance)
    local entity = self._entity
    local playerDistance = playerPosition:distanceManhattan(position)
    if playerDistance <= alignDistance then
        local alignBackOff = false
        if self:hasRangedAttack() and entity.ranged.alignBackOff then
            alignBackOff = true
        end

        if entity:callIfHasComponent("caster", "canCast") and playerDistance <= entity.caster.alignDistance then
            alignBackOff = alignBackOff or entity.caster.alignBackOff
        end

        local isAligned = self.system:arePositionsAligned(position, playerPosition)
        local isAlignedOriginal = isAligned
        if self:hasRangedAttack() and entity.ranged.fireOffCenter then
            for direction in DIRECTIONS_AA() do
                if isAligned then
                    break
                end

                local source = position + Vector[direction]
                                if Vector[direction].y ~= 0 then
                    if source.y == playerPosition.y then
                        isAligned = self.system:arePositionsAligned(source, playerPosition)
                    end

                elseif Vector[direction].x ~= 0 then
                    if source.x == playerPosition.x then
                        isAligned = self.system:arePositionsAligned(source, playerPosition)
                    end

                end

            end

        end

        if isAligned then
            local direction = Common.getDirectionTowards(position, playerPosition)
                        if self:hasRangedAttack() and entity.ranged:isReady() and not (self:hasMeleeAttack() and playerDistance == 1) then
                entity.ranged:setOnCooldown()
                return entity.ranged:createAction(direction)
            elseif alignBackOff and isAlignedOriginal then
                if alignDistance == playerDistance and alignDistance > 1 then
                    return entity.actor:createWait()
                else
                    if (entity.body:isPassable(position - Vector[direction]) and (self.system:getStepCost(entity, position - Vector[direction]) < CONSTANTS.AVOID_COST_MEDIUM) and entity.buffable:canMove()) then
                        if playerDistance > 1 then
                            return entity.actor:createMove(reverseDirection(direction))
                        end

                        if not self:hasMeleeAttack() or (entity:hasComponent("caster") and entity.caster:readyAtEOT()) then
                            if playerDistance > 1 or not self:getPlayer().stats:has(Tags.STAT_LOCK) then
                                return entity.actor:createMove(reverseDirection(direction))
                            end

                        end

                    end

                    if entity:hasComponent("ranged") and entity.ranged.fireOffCenter then
                        if playerDistance > 1 or not self:getPlayer().stats:has(Tags.STAT_LOCK) then
                            return self:getRandomMoveAction()
                        end

                    end

                    if playerDistance == 1 and self:hasMeleeAttack() then
                        return entity.melee:createAction(direction)
                    end

                    if self.system:getStepCost(entity, position) < CONSTANTS.AVOID_COST_MEDIUM then
                        return entity.actor:createWait()
                    else
                        return self:getRandomMoveAction()
                    end

                end

            end

        end

    end

    local path
    if max(abs(playerPosition.x - position.x), abs(playerPosition.y - position.y)) <= alignDistance then
        local ignoreBlocking = false
        if entity:hasComponent("caster") and entity.caster:readyAtEOT() then
            ignoreBlocking = entity.caster.alignIgnoreBlocking
        end

        path = self.system:findPath(self._entity, position, playerPosition, true, ignoreBlocking)
    else
        path = self.system:findPath(self._entity, position, playerPosition)
    end

    return self:getActionWithPath(path, position)
end

function Agent:getActionNonAligned(position, targetPosition)
    local path = self.system:findPath(self._entity, position, targetPosition)
    return self:getActionWithPath(path, position)
end

function Agent:getRandomMoveAction()
    for direction in DIRECTIONS_AA:shuffle(self.system.services.logicrng)() do
        local target = self._body:getPosition() + Vector[direction]
        if (self._body:isPassableDirection(direction) and self.system:getStepCost(self._entity, target) <= CONSTANTS.AVOID_COST_MEDIUM) then
            return self._entity.actor:createMove(direction)
        end

    end

    return false
end

function Agent:isVisible(position)
    return self.system:isVisible(position)
end

function Agent:getPlayer()
    return self.system:getPlayer()
end

function Agent:getAction()
    local entity = self._entity
    if entity.buffable:canAct() then
        local action = entity.agent:getActionRaw()
        if action and (entity.buffable:canMove() or not action:hasComponent("move")) then
            return action
        end

    end

    return false
end

function Agent:getActionRaw()
    local player = self:getPlayer()
    local position = self._body:getPosition()
    local targetPosition = false
    local playerPosition = player.body:getPosition()
    local isVisible = false
    if self.hasSeenPlayer or player.vision:isVisible(position) or self._entity.tank:getRatio() < 1 then
        self.hasSeenPlayer = true
        targetPosition = playerPosition
        isVisible = true
    end

    if self._entity:hasComponent("caster") then
        local caster = self._entity.caster
        if caster.preparedAction then
            if caster.shouldCancel(self._entity, caster.preparedAction.direction, playerPosition) then
                caster:cancelPreparedAction(true)
            else
                return caster:castPreparedAction()
            end

        end

    end

    if self.priorityAction then
        local action = self.priorityAction
        self.priorityAction = false
        return action
    end

    if targetPosition then
        local alignDistance = false
        if isVisible then
            alignDistance = self:getAlignDistance(player)
        end

        local action = false
        if alignDistance then
            action = self:getActionAligned(position, playerPosition, alignDistance)
        else
            action = self:getActionNonAligned(position, targetPosition)
        end

        if action then
            return action
        end

    end

    if self.hasSeenPlayer then
        return self:getRandomMoveAction()
    end

    return false
end

local PlayerPathFinder = class(PathFinder.BaseGrid)
function PlayerPathFinder:initialize(services)
    PlayerPathFinder:super(self, "initialize")
    self.services = services
    self.rangedReserved = false
    self.projectileReserved = false
    self.casterReserved = false
    self.markAligned = SparseGrid:new(false)
end

function PlayerPathFinder:_getNeighborsIgnoreReserved(a, params)
    return PlayerPathFinder:super(self, "getNeighbors", a, params):reject(function(neighbor)
        if neighbor == params.destination then
            return false
        end

        return not self.services.body:canBePassable(neighbor)
    end):shuffle(self.services.logicrng)
end

function PlayerPathFinder:getNeighbors(a, params)
    local neighbors = self:_getNeighborsIgnoreReserved(a, params)
    if a == params.source and not self.casterReserved:get(a) then
        local result = neighbors:reject(function(neighbor)
            if neighbor == params.destination then
                return false
            end

            if not self.services.body:canBePassable(neighbor) then
                return true
            end

            if params.entity.agent.avoidsReserved then
                return self.casterReserved:get(neighbor)
            else
                return false
            end

        end)
        if not result:isEmpty() then
            return result:shuffle(self.services.logicrng)
        end

    end

    return neighbors
end

function PlayerPathFinder:getEdgeLength(a, b, params)
    if b == params.destination then
        return 1
    else
        local isAligned = (params.isAligned and (b.x == params.destination.x or b.y == params.destination.y))
        local stepCost = 1
                        if not self.services.body:isPassable(b) then
            if self.services.body:canBePassable(b) then
                local entityAt = self.services.body:getAt(b)
                                if isAligned and params.alignIgnoreBlocking and a ~= params.source then
                    stepCost = 1
                elseif entityAt:hasComponent("agent") then
                    stepCost = CONSTANTS.AVOID_COST_MEDIUM_HIGH
                else
                    stepCost = CONSTANTS.AVOID_COST_HIGH
                end

                stepCost = min(stepCost, entityAt.body:evaluateStepCost())
            end

        elseif self.projectileReserved:get(b) and params.source:distanceManhattan(b) <= 1 then
            if params.entity.agent.avoidsReserved then
                stepCost = CONSTANTS.AVOID_COST_MEDIUM
            else
                stepCost = CONSTANTS.AVOID_COST_MEDIUM_LOW
            end

        elseif self.rangedReserved:get(b) then
            stepCost = CONSTANTS.AVOID_COST_LOW
        end

        if a == params.source and self.casterReserved:get(b) then
            stepCost = CONSTANTS.AVOID_COST_MEDIUM_LOW
            if self.casterReserved:get(params.source) and params.entity.agent.avoidsReserved then
                stepCost = CONSTANTS.AVOID_COST_MEDIUM
            end

        end

        if not isAligned or a == params.source then
            stepCost = max(stepCost, self.services.steppable:getStepCost(params.entity, b))
        end

        if isAligned then
            stepCost = stepCost * 0.99
        end

        if self.services.body:isPositionAdjacentToAgent(params.entity, b) then
            stepCost = stepCost * 1.0001
        end

        return stepCost
    end

end

function PlayerPathFinder:getHeuristic(a, b, params)
    if params.isAligned then
        return a:distanceManhattan(b) * 0.99
    else
        return a:distanceManhattan(b)
    end

end

function Agent.System:initialize()
    Agent.System:super(self, "initialize")
    self.storageClass = Array
    self:setDependencies("logicrng", "body", "steppable", "ranged", "projectile", "caster", "player", "vision")
    self.pathFinder = PlayerPathFinder:new(self.services)
    self.pathFinder.lengthLimit = MAX_PATH
    self.timeStopped = 0
    self.castingPrevented = false
end

function Agent.System:addTimeStop(value)
    self.timeStopped = self.timeStopped + value
end

function Agent.System:isTimeStopped()
    return self.timeStopped > 0
end

function Agent.System:findPath(entity, source, destination, isAligned, alignIgnoreBlocking)
    self:setReserved(self.pathFinder)
    return self.pathFinder:findPath(source, destination, { entity = entity, isAligned = isAligned, alignIgnoreBlocking = alignIgnoreBlocking })
end

function Agent.System:resetForTurn()
    for entity in self.entities() do
        entity.agent.hasActedThisTurn = false
    end

end

function Agent.System:setReserved(pathFinder)
    pathFinder.rangedReserved = self.services.ranged:getReservedGrid()
    pathFinder.projectileReserved = self.services.projectile:getReservedGrid()
    pathFinder.casterReserved = self.services.caster:getReservedGrid()
end

function Agent.System:isVisible(position)
    return self.services.vision:isVisible(position)
end

function Agent.System:getPlayer()
    return self.services.player:get()
end

function Agent.System:getStepCost(stepper, position)
    return self.services.steppable:getStepCost(stepper, position)
end

function Agent.System:arePositionsAligned(position1, position2)
    return self.services.body:arePositionsAligned(position1, position2)
end

return Agent

