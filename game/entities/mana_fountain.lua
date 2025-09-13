local LogicMethods = require("logic.methods")
local ACTIONS_BASIC = require("actions.basic")
local COOLDOWN = 60
local TIMER = 1
return function(entity, position, currentFloor)
    entity:addComponent("serializable", currentFloor)
    entity:addComponent("body", position)
    entity:addComponent("sprite")
    entity.sprite.frameType = Tags.FRAME_STATIC
    entity.sprite:setCell(1, 6)
    entity.sprite.alwaysVisible = true
    entity:addComponent("charactereffects")
    entity:addComponent("offset")
    entity:addComponent("turntimer")
    entity.turntimer:setCooldown(TIMER, COOLDOWN)
    entity:addComponent("frontinteractive")
    entity.frontinteractive.onInteract = function(entity, director)
        local action = director:getPlayer().actor:create(ACTIONS_BASIC.FOUNTAIN_RESTORE)
        entity.sprite:setCell(2, 6)
        entity.turntimer:setOnCooldown(TIMER)
        director:executePlayerAction(action)
    end
    entity.frontinteractive.isActive = function(entity, director)
        return entity.turntimer:isReady(TIMER)
    end
    entity.turntimer.onReady:set(TIMER, function(entity)
        entity.sprite:setCell(1, 6)
    end)
    entity:addComponent("stats")
    entity.stats:set(Tags.STAT_MAX_HEALTH, LogicMethods.getDestructibleHealth(currentFloor, 2))
    entity.stats:multiply(Tags.STAT_MAX_HEALTH, DebugOptions.NONPLAYER_HEALTH_MULTIPLIER)
    entity:addComponent("tank")
    entity:addComponent("actor")
    entity.body.cantBeMoved = true
end

