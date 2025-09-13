local Action = class()
local Hash = require("utils.classes.hash")
local Common = require("common")
local Global = require("global")
function Action:initialize(entity, direction, abilityStats)
    self.entity = entity
        if direction then
        self.direction = direction
    elseif entity:hasComponent("sprite") then
        self.direction = entity.sprite.direction
    else
        self.direction = false
    end

    self.isParallel = false
    self.abilityStats = abilityStats or false
    self._effects = false
    self._logicRNG = false
end

function Action:setDependencies(effects, logicRNG)
    self._effects = effects
    self._logicRNG = logicRNG
end

function Action:getEffects()
    return self._effects
end

function Action:getLogicRNG()
    return self._logicRNG
end

function Action:addComponent(component,...)
    local componentClass = require("actions.components." .. component)
    local instance = componentClass:new(self, ...)
    self[component] = instance
    return self[component]
end

function Action:addComponentAs(component, namespace,...)
    local componentClass = require("actions.components." .. component)
    local instance = componentClass:new(self, ...)
    self[namespace] = instance
    return self[namespace]
end

function Action:hasComponent(component)
    return toBoolean(rawget(self, component))
end

function Action:chainEvent(anchor)
    local done = anchor:createWaitGroup(1)
    anchor:chainEvent(function(_, anchor)
        anchor = self:process(anchor)
        Utils.assert(anchor, "Forgot to return a currentEvent.")
        anchor:chainWaitGroupDone(done)
    end)
    return done
end

function Action:parallelChainEvent(anchor)
    self:parallelResolve(anchor)
    return self:chainEvent(anchor)
end

function Action:toData(convertToData)
    return false
end

function Action:setFromLoad(data, convertFromData)
end

function Action:isQuick()
    return self.abilityStats and self.abilityStats:get(Tags.STAT_ABILITY_QUICK, 0) > 0
end

function Action:getSlot()
    return self.abilityStats:get(Tags.STAT_SLOT)
end

function Action:setToQuick()
    if not self.abilityStats then
        self.abilityStats = Hash:new()
    end

    self.abilityStats:set(Tags.STAT_ABILITY_QUICK, 1)
end

function Action:parallelResolve(anchor)
end

function Action:checkParallel()
    return false
end

function Action:stopNextParallel()
    return false
end

function Action:prepare()
end

function Action:process(currentEvent)
    return currentEvent
end

function Action:createEffect(effectName,...)
    return self._effects:create(effectName, ...)
end

function Action:cloneEffect(effect)
    return self._effects:clone(effect)
end

function Action:createParallelEvent()
    return self._effects:createParallelEvent()
end

function Action:shakeScreen(currentEvent, shakeIntensity, shakeDecay)
    return self._effects:shakeScreen(currentEvent, shakeIntensity, shakeDecay)
end

function Action:isVisible(position)
            if self.entity:hasComponent("agent") then
        return self.entity.agent:isVisible(position)
    elseif self.entity:hasComponent("vision") then
        return self.entity.vision:isVisible(position)
    elseif self.entity:hasComponent("projectilespawner") then
        return self.entity.projectilespawner:isVisible(position)
    else
        Utils.assert(false, "non-player/agent query")
    end

end

return Action

