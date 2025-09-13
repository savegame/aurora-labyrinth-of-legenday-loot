local Triggers = require("components.create_class")()
local Set = require("utils.classes.set")
local Hash = require("utils.classes.hash")
local ActionList = require("actions.list")
local Vector = require("utils.classes.vector")
local TRIGGERS = require("actions.triggers")
local Common = require("common")
function Triggers:initialize(entity)
    Triggers:super(self, "initialize")
    self._entity = entity
    self.source = false
    self._actionCache = Hash:new()
end

local function bySortOrder(a, b)
    return a.sortOrder < b.sortOrder
end

function Triggers:_getActions(baseClass, direction, kwargs)
    local fromSource = self.source:getActionsForTrigger(baseClass, direction, kwargs)
    local actions = self._entity.buffable:getTriggerActions(baseClass, direction, kwargs)
    local result = actions + fromSource
    result:stableSortSelf(function(a, b)
        return a.sortOrder < b.sortOrder
    end)
    return result
end

function Triggers:hasActionsForTrigger(baseClass, direction, kwargs)
    local actions = self._entity.buffable:getTriggerActions(baseClass, direction, kwargs)
    if not actions:isEmpty() then
        return true
    end

    return self.source:hasActionsForTrigger(baseClass, direction, kwargs)
end

local function convertToMoveArgs(moveFrom, moveTo)
    return Common.getDirectionTowards(moveFrom, moveTo), { moveFrom = moveFrom, moveTo = moveTo }
end

function Triggers:parallelChainEvent(currentEvent, baseClass, direction, kwargs)
    if not self._entity.tank:isAlive() then
        return currentEvent
    end

    local actions = self:_getActions(baseClass, direction, kwargs)
    actions:rejectSelf(function(action)
        if not action:isEnabled() then
            return true
        else
            action:parallelResolve(currentEvent)
            return false
        end

    end)
    return actions:chainEvent(currentEvent), actions:size()
end

function Triggers:parallelChainPreMove(currentEvent, moveFrom, moveTo)
    return self:parallelChainEvent(currentEvent, TRIGGERS.PRE_MOVE, convertToMoveArgs(moveFrom, moveTo))
end

function Triggers:parallelChainPostMove(currentEvent, moveFrom, moveTo)
    return self:parallelChainEvent(currentEvent, TRIGGERS.POST_MOVE, convertToMoveArgs(moveFrom, moveTo))
end

function Triggers:parallelChainAttack(currentEvent, direction, attackTarget)
    local kwargs = {  }
    if attackTarget then
        kwargs.attackTarget = attackTarget
    else
        kwargs.attackTarget = self._entity.body:getPosition() + Vector[direction]
    end

    currentEvent = self:parallelChainEvent(currentEvent, TRIGGERS.ON_ATTACK, direction, kwargs)
    return currentEvent
end

return Triggers

