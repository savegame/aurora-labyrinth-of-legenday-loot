local ACTIONS_COMMON = require("actions.common")
local LogicMethods = require("logic.methods")
local Common = require("common")
local BASE_DAMAGE = 15
local DURATION = 5
local VARIANCE = Common.getVarianceForRatio(0.65)
local DEATH = class(ACTIONS_COMMON.CAULDRON_DEATH)
function DEATH:initialize(entity, direction, abilityStats)
    DEATH:super(self, "initialize", entity, direction, abilityStats)
    self.acidspit:setToFire()
end

function DEATH:affectPosition(anchor, target)
    local hit = self.entity.hitter:createHit(self.position)
    Common.playSFX("BURN_DAMAGE")
    hit:setSpawnFireFromSecondary(self.entity.stats)
    hit:setDamage(Tags.DAMAGE_TYPE_SPELL, hit.spawnFire.minDamage, hit.spawnFire.maxDamage)
    hit:applyToPosition(anchor, target)
end

return function(entity, position, currentFloor)
    require("entities.common_destructible")(entity, position, currentFloor)
    entity.sprite:setCell(9, 10)
    entity.stats:set(Tags.STAT_MAX_HEALTH, 1)
    local minDamage, maxDamage = LogicMethods.getFloorDependentValues(currentFloor, BASE_DAMAGE, VARIANCE)
    entity.stats:set(Tags.STAT_SECONDARY_DAMAGE_MIN, round(minDamage))
    entity.stats:set(Tags.STAT_SECONDARY_DAMAGE_MAX, round(maxDamage))
    entity.stats:set(Tags.STAT_ABILITY_BURN_DURATION, DURATION)
    entity.tank.deathActionClass = DEATH
    entity.tank:restoreToFull()
    entity:addComponent("acidspit")
    entity:addComponent("hitter")
    entity:addComponent("label", "Fire Cauldron")
end

