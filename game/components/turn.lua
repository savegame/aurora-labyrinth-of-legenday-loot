local Turn = require("components.create_class")()
local TRIGGERS = require("actions.triggers")
local ACTIONS_BASIC = require("actions.basic")
local BUFFS = require("definitions.buffs")
local ScreenGame = require("screens.game")
local Global = require("global")
local Array = require("utils.classes.array")
local MINIMUM_TURN_DURATION = require("actions.constants").WAIT_DURATION
function Turn:initialize(entity)
    Turn:super(self, "initialize")
    self._entity = entity
end

function Turn:hasRangedAttack()
    if self._entity:hasComponent("ranged") then
        return self._entity.ranged:isReady()
    else
        return false
    end

end

function Turn:hasPreparedAction()
    if self._entity:hasComponent("caster") then
        return toBoolean(self._entity.caster.preparedAction)
    else
        return false
    end

end

local function boolToNumber(value)
    if value then
        return 1
    else
        return 0
    end

end

function Turn:isTurnBefore(b)
    local canActA = boolToNumber(self._entity.buffable:canAct())
    local canActB = boolToNumber(b.buffable:canAct())
    if canActA ~= canActB then
        return canActA > canActB
    end

    local preparedA = boolToNumber(self:hasPreparedAction())
    local preparedB = boolToNumber(b.turn:hasPreparedAction())
    if preparedA ~= preparedB then
        return preparedA < preparedB
    end

    local rangedA = boolToNumber(self:hasRangedAttack())
    local rangedB = boolToNumber(b.turn:hasRangedAttack())
    if rangedA ~= rangedB then
        return rangedA < rangedB
    end

    local playerPosition = self.system.services.player:get().body:getPosition()
    local aDistance = self._entity.body:getPosition():distanceManhattan(playerPosition)
    local bDistance = b.body:getPosition():distanceManhattan(playerPosition)
    if aDistance == bDistance then
        local isPoisonedA = boolToNumber(self._entity.buffable:isAffectedBy(BUFFS:get("POISON")))
        local isPoisonedB = boolToNumber(b.buffable:isAffectedBy(BUFFS:get("POISON")))
        if isPoisonedA ~= isPoisonedB then
            return isPoisonedA > isPoisonedB
        end

    end

    return aDistance < bDistance
end

function Turn:hasEndOfTurnTrigger()
    local result = false
    if self._entity:hasComponent("triggers") then
        result = self._entity.triggers:hasActionsForTrigger(TRIGGERS.END_OF_TURN, false)
    end

    if not result and self._entity:hasComponent("buffable") then
        result = self._entity.buffable:hasDelayTurn()
    end

    return result
end

function Turn:startOfTurn(anchor)
    self._entity.buffable:startOfTurn(anchor)
end

function Turn:endOfTurn(anchor)
    local entity = self._entity
    entity.sprite:resetLayer()
    anchor = entity.triggers:parallelChainEvent(anchor, TRIGGERS.END_OF_TURN, false)
    entity:callIfHasComponent("ranged", "endOfTurn")
    if entity.body.skipEndStep then
        entity.body.skipEndStep = false
    else
        entity.body:stepAt(anchor, entity.body:getPosition())
        if entity:hasComponent("vision") and entity.vision.needRescan then
            entity.vision:scan(entity.body:getPosition())
            entity.vision:refreshExplored()
        end

    end

    self.system:createPriorityEventOnEmpty(function(_, anchor)
        entity:callIfHasComponent("equipment", "endOfTurn", anchor)
        entity:callIfHasComponent("caster", "endOfTurn", anchor)
        entity:callIfHasComponent("tank", "undelayDeath", anchor)
    end)
    self.system:createPriorityEventOnEmpty(function(_, anchor)
        entity.buffable:endOfTurn(anchor)
    end)
end

function Turn:midTurnQuick(anchor)
    local entity = self._entity
    entity.buffable:removeExpired(anchor)
    entity.equipment:midTurnQuick(anchor)
    self.system.services.stepinteractive:check(entity.body:getPosition())
end

function Turn.System:initialize()
    Turn.System:super(self, "initialize")
    self:setDependencies("actionscheduler", "player", "agent", "body", "steppable", "stepinteractive", "projectile", "perishable", "turntimer", "buffable", "overseer", "timing", "director")
    self.turnAgents = Array:new()
    self.turnStartTime = false
    self.turnOrderCompare = (function(a, b)
        return a.turn:isTurnBefore(b)
    end)
end

function Turn.System:createEvent(...)
    return self.services.actionscheduler:createEvent(...)
end

function Turn.System:createEventOnEmpty(...)
    return self.services.actionscheduler:createEventOnEmpty(...)
end

function Turn.System:createPriorityEventOnEmpty(...)
    return self.services.actionscheduler:createPriorityEventOnEmpty(...)
end

function Turn.System:canDoTurn()
    return self.services.actionscheduler:isEmpty()
end

function Turn.System:executeActionForTurn(action)
    if action:isQuick() then
        self:executeQuickAction(action)
    else
        self:startTurnWithAction(action)
    end

end

function Turn.System:startTurnWithAction(action)
    self.turnStartTime = self.services.actionscheduler:getScheduleTime()
    self.turnAgents = self.services.agent.entities:clone()
    self.turnAgents:rejectSelf(function(entity)
        return entity.body.removedFromGrid
    end)
    self:scheduleActionAndNextTurn(action)
end

function Turn.System:executeQuickAction(action)
    local entity = action.entity
    local anchor = self:createEvent()
    action:parallelChainEvent(anchor)
    self:createEventOnEmpty(function(currentTime, anchor)
        entity.turn:midTurnQuick(anchor)
    end)
end

function Turn.System:scheduleActionAndNextTurn(action)
    local entity = action.entity
    local isParallel = self:createEventForAction(action)
    self:createEventOnEmpty(function(_, anchor)
        entity.turn:endOfTurn(anchor)
    end)
    if isParallel then
        self:checkNextTurn(self:createEvent())
    else
        self:createEventOnEmpty(function(_, anchor)
            self:checkNextTurn(anchor)
        end)
    end

end

function Turn.System:createEventForAction(action)
    local entity = action.entity
    action.isParallel = action:checkParallel()
    local anchor
    local stopNextParallel = false
    if action.isParallel then
        stopNextParallel = action:stopNextParallel()
        anchor = self:createEvent()
        action:parallelResolve(anchor)
    end

    if action.isParallel and (not entity.turn:hasEndOfTurnTrigger()) then
        action:chainEvent(anchor)
        return not stopNextParallel
    else
        self:createEventOnEmpty(function(_, anchor)
            if not action.isParallel then
                action:parallelChainEvent(anchor)
            else
                action:chainEvent(anchor)
            end

        end)
        return false
    end

end

function Turn.System:scheduleAgentQuickAction(action)
    local entity = action.entity
    if action:checkParallel() and not entity.turn:hasEndOfTurnTrigger() then
        action.isParallel = true
        local currentEvent = action:parallelChainEvent(self:createEvent())
        local newAction = entity.agent:getAction()
        if newAction:checkParallel() and not entity.turn:hasEndOfTurnTrigger() then
            newAction.isParallel = true
            currentEvent = newAction:parallelChainEvent(currentEvent)
            self:createEventOnEmpty(function(_, anchor)
                entity.turn:endOfTurn(anchor, entity)
            end)
            self:checkNextTurn(currentEvent)
            return 
        else
            newAction.isParallel = false
            self:createEventOnEmpty(function(_, anchor)
                newAction:parallelChainEvent(anchor)
            end)
        end

    else
        action.isParallel = false
        self:createEventOnEmpty(function(_, anchor)
            action:parallelChainEvent(anchor):chainEvent(function(_, anchor)
                local newAction = entity.agent:getAction()
                newAction.isParallel = false
                newAction:parallelChainEvent(anchor)
            end)
        end)
    end

    self:createEventOnEmpty(function(_, anchor)
        entity.turn:endOfTurn(anchor, entity)
    end)
    self:createEventOnEmpty(function(_, anchor)
        self:checkNextTurn(anchor)
    end)
end

function Turn.System:checkNextTurn(anchor)
    if not self.services.agent:isTimeStopped() then
        while not self.turnAgents:isEmpty() do
            local agent = self.turnAgents:minValue(self.turnOrderCompare)
            self.turnAgents:delete(agent)
            if agent.tank:isAlive() then
                agent.triggers:parallelChainEvent(anchor, TRIGGERS.START_OF_TURN, false)
                agent.turn:startOfTurn(anchor)
                local action = false
                if agent.tank:isAlive() and not agent.agent.hasActedThisTurn then
                    agent.agent.hasActedThisTurn = true
                    if agent.agent.isRattled then
                        agent.agent.isRattled = false
                    else
                        action = agent.agent:getAction()
                        if action and action:isQuick() then
                            return self:scheduleAgentQuickAction(action)
                        end

                    end

                end

                if not action then
                    action = agent.actor:createWait()
                end

                return self:scheduleActionAndNextTurn(action)
            end

        end

        local projectileAnchor = false
        for entity in (self.services.projectile.entities:clone())() do
            if not projectileAnchor then
                projectileAnchor = self:createEvent()
            end

            local projectile = entity.projectile
            if not projectile.hasHit then
                if not projectile.frozen and projectile.speed > 0 then
                    local action = entity.actor:create(ACTIONS_BASIC.MOVE_PROJECTILE, projectile.direction)
                    action:parallelChainEvent(projectileAnchor)
                end

            end

        end

    end

    self:createEventOnEmpty(function(_, anchor)
        self.services.projectile:unfreeze()
        self.services.body:stepAllNonAgents(anchor)
        self.services.perishable:endOfTurn()
        self.services.turntimer:endOfTurn(anchor)
    end)
    self:createEventOnEmpty(function(currentTime, anchor)
        if currentTime - self.turnStartTime < MINIMUM_TURN_DURATION - 0.0001 then
            local duration = MINIMUM_TURN_DURATION - (currentTime - self.turnStartTime)
            anchor:chainProgress(duration):chainEvent(function(currentTime, anchor)
                self:turnIntermission(anchor)
            end)
        else
            self:turnIntermission(anchor)
        end

    end)
    self.services.actionscheduler:updateIfNotUpdating()
end

function Turn.System:turnIntermission(anchor)
    local player = self.services.player:get()
    if player.tank:isAlive() then
        self.services.stepinteractive:check(player.body:getPosition())
    end

    if not ScreenGame:isInstance(Global:get(Tags.GLOBAL_CURRENT_SCREEN)) then
        return 
    end

    if not player.tank:isAlive() then
        return 
    end

    if not self.services.agent:isTimeStopped() then
        self.services.agent:resetForTurn()
        self.services.overseer:increaseTurn(anchor)
    end

    self:createEventOnEmpty(function(_, anchor)
        if player.tank:isAlive() then
            player.tank:regenerate()
            player.mana:regenerate()
        end

        player.turn:startOfTurn(anchor)
        player.equipment:startOfTurn(anchor)
        player.triggers:parallelChainEvent(anchor, TRIGGERS.START_OF_TURN, false)
    end)
    self:createEventOnEmpty(function(currentTime, anchor)
        local sustained = player.equipment:getSustainedSlot()
                        if not player.player:canAct() then
            if sustained then
                player.equipment:deactivateSlot(anchor, sustained)
            end

            self:executeActionForTurn(player.actor:create(ACTIONS_BASIC.WAIT_PLAYER))
        elseif sustained and player.equipment:isSustainAutocast() then
            self:executeActionForTurn(player.actor:create(ACTIONS_BASIC.WAIT_PLAYER))
        elseif player.player.skipNextTurn then
            player.player.skipNextTurn = false
            self:executeActionForTurn(player.actor:create(ACTIONS_BASIC.WAIT_PLAYER))
        else
            local actualTime = self.services.timing.timePassed
            self.services.director:updateWidgets(actualTime - currentTime)
        end

    end)
end

return Turn

