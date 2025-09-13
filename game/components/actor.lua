local Actor = require("components.create_class")()
local ACTIONS_BASIC = require("actions.basic")
function Actor:initialize(entity)
    Actor:super(self, "initialize")
    self._entity = entity
end

function Actor:create(actionClass, direction, abilityStats)
    local action = actionClass:new(self._entity, direction, abilityStats)
    action:setDependencies(self.system.services.effects, self.system.services.logicrng)
    return action
end

function Actor:createWait()
    return self:create(ACTIONS_BASIC.WAIT)
end

function Actor:createMove(direction)
    return self:create(ACTIONS_BASIC.MOVE, direction)
end

function Actor:getEffects()
    return self.system.services.effects
end

function Actor.System:initialize()
    Actor.System:super(self, "initialize")
    self:setDependencies("effects", "logicrng")
end

return Actor

