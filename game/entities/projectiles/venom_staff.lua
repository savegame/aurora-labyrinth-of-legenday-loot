local ACTIONS_FRAGMENT = require("actions.fragment")
local BUFFS = require("definitions.buffs")
local Vector = require("utils.classes.vector")
local ON_HIT = class(ACTIONS_FRAGMENT.EXPLOSIVE_HIT)
function ON_HIT:initialize(entity, direction, abilityStats)
    ON_HIT:super(self, "initialize", entity, direction, abilityStats)
    self.explosion:setHueToPoison()
    self.sound = "POISON_DAMAGE"
end

function ON_HIT:parallelResolve(currentEvent)
    ON_HIT:super(self, "parallelResolve", currentEvent)
    local duration = self.abilityStats:get(Tags.STAT_ABILITY_DEBUFF_DURATION)
    local poisonDamage = self.abilityStats:get(Tags.STAT_POISON_DAMAGE_TOTAL)
    self.hit:addBuff(BUFFS:get("POISON"):new(duration, self.entity, poisonDamage))
end

function ON_HIT:process(currentEvent)
    currentEvent = ON_HIT:super(self, "process", currentEvent)
    if self.entity.body:hasEntityWithAgent(self.targetPosition) then
        self.entity.projectilespawner:spawnChild(currentEvent, "venom_staff", self.targetPosition, self.direction, self.abilityStats)
    end

    return currentEvent
end

return function(entity, position, sourceEntity, direction, abilityStats)
    entity:addComponent("serializable", sourceEntity, direction, abilityStats)
    require("entities.projectiles.common")(entity, position, direction, Vector:new(2, 2), true)
    entity.projectile.speed = abilityStats:get(Tags.STAT_ABILITY_PROJECTILE_SPEED)
    entity.projectile.onHitAction = sourceEntity.actor:create(ON_HIT, direction, abilityStats)
end

