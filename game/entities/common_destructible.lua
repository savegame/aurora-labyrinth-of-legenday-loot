local LogicMethods = require("logic.methods")
return function(entity, position, currentFloor, healthMultiplier)
    entity:addComponent("serializable", currentFloor, healthMultiplier)
    entity:addComponent("body", position)
    entity:addComponent("sprite")
    entity.sprite.alwaysVisible = true
    entity:addComponent("charactereffects")
    entity:addComponent("offset")
    entity:addComponent("stats")
    entity.stats:set(Tags.STAT_MAX_HEALTH, LogicMethods.getDestructibleHealth(currentFloor, healthMultiplier or 1))
    entity.stats:multiply(Tags.STAT_MAX_HEALTH, DebugOptions.NONPLAYER_HEALTH_MULTIPLIER)
    entity:addComponent("tank")
    entity:addComponent("actor")
    entity:addComponent("offset")
end

