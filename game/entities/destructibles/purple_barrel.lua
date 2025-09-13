local ACTIONS_COMMON = require("actions.common")
local Hash = require("utils.classes.hash")
local LogicMethods = require("logic.methods")
local CONSTANTS = require("logic.constants")
local Common = require("common")
local BASE_DAMAGE = 25
local VARIANCE = Common.getVarianceForRatio(0.2)
local DEATH = class(ACTIONS_COMMON.BARREL_DEATH)
function DEATH:initialize(entity, direction, abilityStats)
    DEATH:super(self, "initialize", entity, direction, abilityStats)
    self.explosion:setHueToDeath()
    self.explosion.shakeIntensity = self.explosion.shakeIntensity - 1
    self.explosion:setArea(Tags.ABILITY_AREA_CROSS)
end

function DEATH:createHit()
    return false
end

function DEATH:process(currentEvent)
    local abilityStats = Hash:new()
    abilityStats:set(Tags.STAT_ABILITY_DAMAGE_MIN, self.entity.stats:get(Tags.STAT_ABILITY_DAMAGE_MIN))
    abilityStats:set(Tags.STAT_ABILITY_DAMAGE_MAX, self.entity.stats:get(Tags.STAT_ABILITY_DAMAGE_MAX))
    abilityStats:set(Tags.STAT_ABILITY_PROJECTILE_SPEED, CONSTANTS.ENEMY_PROJECTILE_SPEED + 1)
    for direction in DIRECTIONS_DIAGONAL() do
        self.entity.projectilespawner:spawn(currentEvent, direction, abilityStats)
    end

    return DEATH:super(self, "process", currentEvent)
end

return function(entity, position, currentFloor)
    require("entities.common_destructible")(entity, position, currentFloor)
    entity.sprite.frameType = Tags.FRAME_STATIC
    entity.sprite:setCell(6, 9)
    entity.stats:set(Tags.STAT_MAX_HEALTH, 1)
    local minDamage, maxDamage = LogicMethods.getFloorDependentValues(currentFloor, BASE_DAMAGE, VARIANCE)
    entity.stats:set(Tags.STAT_ABILITY_DAMAGE_MIN, round(minDamage))
    entity.stats:set(Tags.STAT_ABILITY_DAMAGE_MAX, round(maxDamage))
    entity.tank.deathActionClass = DEATH
    entity.tank:restoreToFull()
    entity:addComponent("hitter")
    entity:addComponent("projectilespawner")
    entity.projectilespawner:setCell(3, 1)
    entity.projectilespawner.isMagical = true
    entity:addComponent("label", "Arcane Barrel")
end

