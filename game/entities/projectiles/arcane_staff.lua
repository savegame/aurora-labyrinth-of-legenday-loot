local Array = require("utils.classes.array")
local Vector = require("utils.classes.vector")
local ACTIONS_FRAGMENT = require("actions.fragment")
local ON_HIT = class(ACTIONS_FRAGMENT.EXPLOSIVE_HIT)
local function getSpawnDirections(direction, abilityStats)
    local result = Array:new(cwDirection(direction), ccwDirection(direction))
    local count = abilityStats:get(Tags.STAT_ABILITY_COUNT)
    if count >= 3 then
        result:push(direction)
    end

    if count >= 5 then
        result:push(cwDirection(direction, 1))
        result:push(ccwDirection(direction, 1))
    end

    return result
end

function ON_HIT:initialize(entity, direction, abilityStats)
    ON_HIT:super(self, "initialize", entity, direction, abilityStats)
    self.explosion:setHueToArcane()
end

function ON_HIT:parallelResolve(anchor)
    ON_HIT:super(self, "parallelResolve", anchor)
    self.hit:setDamageFromAbilityStats(Tags.DAMAGE_TYPE_RANGED, self.abilityStats)
end

function ON_HIT:process(currentEvent)
    currentEvent = ON_HIT:super(self, "process", currentEvent)
    if self.entity.body:canBePassable(self.targetPosition) then
        for direction in (getSpawnDirections(self.direction, self.abilityStats))() do
            self.entity.projectilespawner:spawnChild(currentEvent, "normal", self.targetPosition, direction, self.abilityStats, Vector:new(1, 2), true)
        end

    end

    return currentEvent
end

return function(entity, position, sourceEntity, direction, abilityStats)
    entity:addComponent("serializable", sourceEntity, direction, abilityStats)
    require("entities.projectiles.common")(entity, position, direction, Vector:new(1, 2), true)
    entity.projectile.speed = abilityStats:get(Tags.STAT_ABILITY_PROJECTILE_SPEED)
    entity.projectile.onHitAction = sourceEntity.actor:create(ON_HIT, direction, abilityStats)
end

