local Vector = require("utils.classes.vector")
local Hash = require("utils.classes.hash")
local Common = require("common")
local CONSTANTS = require("logic.constants")
local ATTACK_UNARMED = require("actions.attack_unarmed")
local ACTIONS_FRAGMENT = require("actions.fragment")
local ActionUtils = require("actions.utils")
local SKILL = require("structures.skill_def"):new()
SKILL.cooldown = math.huge
SKILL.getCastDirection = alwaysFalse
SKILL.indicateArea = function(entity, direction, indicateGrid)
    local origin = entity.body:getPosition()
    for projDirection in DIRECTIONS_AA() do
        for i = 1, CONSTANTS.ENEMY_PROJECTILE_SPEED do
            indicateGrid:set(origin + Vector[projDirection] * i, true)
        end

    end

end
local SKILL_ACTION = class("actions.action")
SKILL.actionClass = SKILL_ACTION
local EXPLOSION_DURATION = 0.6
local EXPLOSION_SHAKE_INTENSITY = 2
local ON_HIT = class(ACTIONS_FRAGMENT.EXPLOSIVE_HIT)
function ON_HIT:parallelResolve(anchor)
    ON_HIT:super(self, "parallelResolve", anchor)
    self.hit:setDamage(Tags.DAMAGE_TYPE_RANGED, self.entity.stats:getEnemyAbility())
    self.explosion:setHueToDeath()
end

function SKILL_ACTION:initialize(entity, direction, abilityStats)
    SKILL_ACTION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("explosion")
    self.explosion:setArea(Tags.ABILITY_AREA_CROSS)
    self.explosion:setHueToDeath()
    self.explosion.shakeIntensity = EXPLOSION_SHAKE_INTENSITY
end

function SKILL_ACTION:process(currentEvent)
    self.explosion.source = self.entity.body:getPosition()
    self.entity.tank.preDeath = doNothing
    self.entity.tank.currentHealth = 0
    self.entity.tank:kill(currentEvent)
    local abilityStats = Hash:new()
    abilityStats:set(Tags.STAT_ABILITY_DAMAGE_MIN, self.entity.stats:get(Tags.STAT_ABILITY_DAMAGE_MIN))
    abilityStats:set(Tags.STAT_ABILITY_DAMAGE_MAX, self.entity.stats:get(Tags.STAT_ABILITY_DAMAGE_MAX))
    abilityStats:set(Tags.STAT_ABILITY_PROJECTILE_SPEED, CONSTANTS.ENEMY_PROJECTILE_SPEED)
    currentEvent:chainEvent(function(_, anchor)
        Common.playSFX("EXPLOSION_MEDIUM")
        for direction in DIRECTIONS_AA() do
            self.entity.projectilespawner:spawn(anchor, direction, abilityStats)
        end

    end)
    return self.explosion:chainFullEvent(currentEvent, EXPLOSION_DURATION)
end

return function(entity, position, direction, id, difficulty, eliteID, forcedOrbChance)
    require("entities.common_enemy")(entity, position, direction, id, difficulty, eliteID, forcedOrbChance)
    entity.sprite:setCell(3, 8)
    entity:addComponent("melee")
    entity.melee.attackClass = ATTACK_UNARMED.TACKLE_AND_DAMAGE
    entity:addComponent("projectilespawner")
    entity.projectilespawner:setCell(3, 1)
    entity.projectilespawner.isMagical = true
    entity:addComponent("caster", SKILL)
    entity.tank.preDeath = ActionUtils.deathCasterPreDeath
end

