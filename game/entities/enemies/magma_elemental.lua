local Common = require("common")
local ActionUtils = require("actions.utils")
local ATTACK_UNARMED = require("actions.attack_unarmed")
local SKILL = require("structures.skill_def"):new()
SKILL.cooldown = math.huge
SKILL.getCastDirection = alwaysFalse
SKILL.indicateArea = function(entity, direction, indicateGrid)
    local origin = entity.body:getPosition()
    local positions = ActionUtils.getAreaPositions(entity, origin, Tags.ABILITY_AREA_3X3)
    for position in positions() do
        if position ~= origin then
            indicateGrid:set(position, true)
        end

    end

end
local SKILL_ACTION = class("actions.action")
SKILL.actionClass = SKILL_ACTION
local SKILL_AREA = Tags.ABILITY_AREA_3X3
local EXPLOSION_DURATION = 0.6
local EXPLOSION_SHAKE_INTENSITY = 3
function SKILL_ACTION:initialize(entity, direction, abilityStats)
    SKILL_ACTION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("explosion")
    self.explosion:setArea(SKILL_AREA)
    self.explosion.excludeSelf = true
    self.explosion.shakeIntensity = EXPLOSION_SHAKE_INTENSITY
end

function SKILL_ACTION:process(currentEvent)
    self.explosion.source = self.entity.body:getPosition()
    self.entity.tank.preDeath = doNothing
    self.entity.tank.currentHealth = 0
    self.entity.tank:kill(currentEvent)
    Common.playSFX("EXPLOSION_MEDIUM")
    return self.explosion:chainFullEvent(currentEvent, EXPLOSION_DURATION, function(anchor, position)
        local hit = self.entity.hitter:createHit(self.explosion.source)
        hit:setDamage(Tags.DAMAGE_TYPE_SPELL, self.entity.stats:getEnemyAbility())
        hit:increaseBonusState()
        hit:applyToPosition(anchor, position)
    end)
end

return function(entity, position, direction, id, difficulty, eliteID, forcedOrbChance)
    require("entities.common_enemy")(entity, position, direction, id, difficulty, eliteID, forcedOrbChance)
    entity.sprite:setCell(3, 7)
    entity:addComponent("melee")
    entity.melee.attackClass = ATTACK_UNARMED.CLAW_AND_DAMAGE
    entity:addComponent("caster", SKILL)
    entity.tank.preDeath = ActionUtils.deathCasterPreDeath
end

