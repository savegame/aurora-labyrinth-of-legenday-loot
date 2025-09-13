local ACTIONS_COMMON = require("actions.common")
local LogicMethods = require("logic.methods")
local BUFFS = require("definitions.buffs")
local Common = require("common")
local BASE_DAMAGE = 15
local VARIANCE = Common.getVarianceForRatio(0.1)
local COLD_DURATION = 5
local DEATH = class(ACTIONS_COMMON.BARREL_DEATH)
function DEATH:initialize(entity, direction, abilityStats)
    DEATH:super(self, "initialize", entity, direction, abilityStats)
    self.explosion:setHueToIce()
    self.explosion.shakeIntensity = 0
    self.sound = "EXPLOSION_ICE"
end

function DEATH:createHit()
    local hit = DEATH:super(self, "createHit")
    hit:addBuff(BUFFS:get("COLD"):new(COLD_DURATION))
    return hit
end

return function(entity, position, currentFloor)
    require("entities.common_destructible")(entity, position, currentFloor)
    entity.sprite.frameType = Tags.FRAME_STATIC
    entity.sprite:setCell(2, 4)
    entity.stats:set(Tags.STAT_MAX_HEALTH, 1)
    local minDamage, maxDamage = LogicMethods.getFloorDependentValues(currentFloor, BASE_DAMAGE, VARIANCE)
    entity.stats:set(Tags.STAT_ABILITY_DAMAGE_MIN, round(minDamage))
    entity.stats:set(Tags.STAT_ABILITY_DAMAGE_MAX, round(maxDamage))
    entity.tank.deathActionClass = DEATH
    entity.tank:restoreToFull()
    entity:addComponent("hitter")
    entity:addComponent("label", "Frost Barrel")
end

