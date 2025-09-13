local Vector = require("utils.classes.vector")
local Set = require("utils.classes.set")
local function collectAllFromPosition(system, position, taken)
    local entityAt = system:getAt(position)
    if entityAt and not taken:contains(entityAt) then
        taken:add(entityAt)
        for direction in DIRECTIONS_AA() do
            local target = position + Vector[direction]
            collectAllFromPosition(system, target, taken)
        end

    end

end

return function(entity, position, isRefresher)
    entity:addComponent("stepinteractive", position)
    entity.stepinteractive.onInteract = function(entity, director)
        local system = entity.stepinteractive.system
        local entitiesToDelete = Set:new()
        collectAllFromPosition(system, entity.stepinteractive:getPosition(), entitiesToDelete)
        for entity in entitiesToDelete() do
            entity:delete()
        end

        if isRefresher then
            local player = director:getPlayer()
            player.equipment:resetCooldown(Tags.SLOT_WEAPON)
            local weapon = player.equipment:get(Tags.SLOT_WEAPON)
            if weapon and weapon:getAbility() then
                director:publish(Tags.UI_TUTORIAL_ITEM_MESSAGE, weapon)
            end

        else
            director:publish(Tags.UI_TUTORIAL_PROCEED)
        end

    end
end

