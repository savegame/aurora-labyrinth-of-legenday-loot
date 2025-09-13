local LogicMethods = require("logic.methods")
local Common = require("common")
return function(entity, position, currentFloor, isGolden)
    entity:addComponent("serializable", currentFloor, isGolden)
    entity:addComponent("body", position, currentFloor)
    entity.body.cantBeMoved = true
    entity:addComponent("sprite")
    entity.sprite.frameType = Tags.FRAME_STATIC
    if isGolden then
        entity.sprite:setCell(4, 9)
    else
        entity.sprite:setCell(3, 9)
    end

    entity.sprite.alwaysVisible = true
    entity:addComponent("indicator", "ITEM")
    entity:addComponent("charactereffects")
    entity:addComponent("offset")
    entity:addComponent("frontinteractive")
    entity.frontinteractive.onInteract = function(entity, director)
        director:publish(Tags.UI_CLEAR, false)
        Common.playSFX("CONFIRM")
        director:publish(Tags.UI_SHOW_ANVIL, entity, toBoolean(isGolden))
    end
    entity.frontinteractive.isActive = function(entity, director)
        local player = director:getPlayer()
        local slots = player.equipment:getSlotsWithAbilities()
        for slot in slots() do
            if player.equipment:hasEquipped(slot) then
                return true
            end

        end

        if isGolden and player.equipment:hasEquipped(Tags.SLOT_RING) then
            return true
        end

        return false
    end
    entity:addComponent("stats")
    local multiplier = 2.5
    if isGolden then
        multiplier = 5
    end

    entity.stats:set(Tags.STAT_MAX_HEALTH, LogicMethods.getDestructibleHealth(currentFloor, multiplier))
    entity.stats:multiply(Tags.STAT_MAX_HEALTH, DebugOptions.NONPLAYER_HEALTH_MULTIPLIER)
    entity:addComponent("tank")
    entity:addComponent("actor")
end

