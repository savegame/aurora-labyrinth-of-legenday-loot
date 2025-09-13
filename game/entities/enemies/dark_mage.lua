local Vector = require("utils.classes.vector")
local Common = require("common")
local COLORS = require("draw.colors")
local ATTACK_WEAPON = require("actions.attack_weapon")
local ACTIONS_FRAGMENT = require("actions.fragment")
local ACTIONS_COMMON = require("actions.common")
local ActionUtils = require("actions.utils")
local RANGED_ATTACK = class(ACTIONS_COMMON.CASTER_SHOOT)
function RANGED_ATTACK:initialize(entity, direction, abilityStats)
    RANGED_ATTACK:super(self, "initialize", entity, direction, abilityStats)
    self.color = COLORS.STANDARD_DEATH
end

local SKILL_RANGE = 3
local SKILL = require("structures.skill_def"):new()
local SKILL_AREA = Tags.ABILITY_AREA_3X3
SKILL.cooldown = 7
SKILL.getCastDirection = function(entity, player)
    if not entity.ranged:isReady() then
        return false
    end

    local entityPos = entity.body:getPosition()
    local playerPos = player.body:getPosition()
    if abs(entityPos.x - playerPos.x) > 1 and abs(entityPos.y - playerPos.y) > 1 then
        return false
    end

    local direction = Common.getDirectionTowards(entityPos, playerPos)
    local origin = entityPos + Vector[direction] * SKILL_RANGE
    if origin:distanceManhattan(playerPos) <= 1 then
        return direction
    else
        return false
    end

end
SKILL.indicateArea = function(entity, direction, indicateGrid)
    local position = entity.body:getPosition()
    local center = entity.body:getPosition() + Vector[direction] * SKILL_RANGE
    local positions = ActionUtils.getAreaPositions(entity, center, Tags.ABILITY_AREA_3X3)
    for position in positions() do
        indicateGrid:set(position, true)
    end

end
local SKILL_ACTION = class(ACTIONS_FRAGMENT.CAST)
SKILL.actionClass = SKILL_ACTION
local ON_SKILL_HIT = class(ACTIONS_FRAGMENT.EXPLOSIVE_HIT)
function ON_SKILL_HIT:parallelResolve(anchor)
    ON_SKILL_HIT:super(self, "parallelResolve", anchor)
    self.explosion:setHueToDeath()
    self.sound = "EXPLOSION_MEDIUM"
    self.soundPitch = 1.5
    self.hit:setDamage(Tags.DAMAGE_TYPE_SPELL, self.entity.stats:getEnemyAbility())
    self.hit:increaseBonusState()
end

function SKILL_ACTION:initialize(entity, direction, abilityStats)
    SKILL_ACTION:super(self, "initialize", entity, direction, abilityStats)
    self.color = COLORS.STANDARD_DEATH
    self:addComponent("projectilerain")
    self.projectilerain.onHitClass = ON_SKILL_HIT
    self.projectilerain.projectile = Vector:new(3, 1)
    self.projectilerain.dropGap = 0
end

function SKILL_ACTION:process(currentEvent)
    self.entity.ranged:setOnCooldown()
    self.projectilerain.source = self.entity.body:getPosition() + Vector[self.direction] * SKILL_RANGE
    currentEvent = SKILL_ACTION:super(self, "process", currentEvent)
    return self.projectilerain:chainRainEvent(currentEvent)
end

return function(entity, position, direction, id, difficulty, eliteID, forcedOrbChance)
    require("entities.common_enemy")(entity, position, direction, id, difficulty, eliteID, forcedOrbChance)
    entity.sprite:setCell(11, 9)
    entity:addComponent("melee")
    entity.melee.swingIcon = Vector:new(21, 9)
    entity.melee.enabled = false
    entity:addComponent("caster", SKILL)
    entity.caster.alignDistance = SKILL_RANGE
    entity.caster.alignWhenNotReady = true
    entity:addComponent("projectilespawner")
    entity.projectilespawner:setCell(3, 1)
    entity.projectilespawner.isMagical = true
    entity:addComponent("ranged")
    entity.ranged.attackClass = RANGED_ATTACK
    entity.ranged.attackCooldown = 2
end

