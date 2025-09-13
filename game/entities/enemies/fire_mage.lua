local Vector = require("utils.classes.vector")
local Common = require("common")
local COLORS = require("draw.colors")
local ATTACK_WEAPON = require("actions.attack_weapon")
local ACTIONS_FRAGMENT = require("actions.fragment")
local ACTIONS_COMMON = require("actions.common")
local RANGED_ATTACK = class(ACTIONS_COMMON.CASTER_SHOOT)
function RANGED_ATTACK:initialize(entity, direction, abilityStats)
    RANGED_ATTACK:super(self, "initialize", entity, direction, abilityStats)
    self.color = COLORS.STANDARD_FIRE
end

local SKILL_RANGE = 3
local SKILL_DURATION = 3
local SKILL = require("structures.skill_def"):new()
SKILL.cooldown = 6
SKILL.getCastDirection = function(entity, player)
    if not entity.ranged:isReady() then
        return false
    end

    local entityPos = entity.body:getPosition()
    local playerPos = player.body:getPosition()
    if entityPos.x ~= playerPos.x and entityPos.y ~= playerPos.y then
        return false
    end

    local distance = entityPos:distanceManhattan(playerPos)
    if distance >= SKILL_RANGE and distance <= SKILL_RANGE + 1 then
        return Common.getDirectionTowards(entityPos, playerPos)
    else
        return false
    end

end
SKILL.indicateArea = function(entity, direction, indicateGrid)
    local position = entity.body:getPosition()
    local center = entity.body:getPosition() + Vector[direction] * SKILL_RANGE
    indicateGrid:set(center, true)
    indicateGrid:set(center + Vector[cwDirection(direction)], true)
    indicateGrid:set(center + Vector[ccwDirection(direction)], true)
end
local SKILL_ACTION = class(ACTIONS_FRAGMENT.CAST)
SKILL.actionClass = SKILL_ACTION
local SUMMON_INTERVAL = 0.08
local SUMMON_AREA = 3
function SKILL_ACTION:initialize(entity, direction, abilityStats)
    SKILL_ACTION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("cleaveorder")
    self.color = COLORS.STANDARD_FIRE
    self.cleaveorder.area = SUMMON_AREA
    self.cleaveorder:setEasingToLinear()
    self.fireMinDamage = floor(entity.stats:get(Tags.STAT_ABILITY_DAMAGE_MIN) / 3)
    self.fireMaxDamage = ceil(entity.stats:get(Tags.STAT_ABILITY_DAMAGE_MAX) / 3)
end

function SKILL_ACTION:process(currentEvent)
    self.entity.ranged:setOnCooldown()
    currentEvent = SKILL_ACTION:super(self, "process", currentEvent):chainEvent(function()
        Common.playSFX("BURN_DAMAGE")
    end)
    local source = self.entity.body:getPosition()
    self.cleaveorder.position = source + Vector[self.direction] * (SKILL_RANGE - 1)
    return self.cleaveorder:chainHitEvent(currentEvent, SUMMON_INTERVAL * (SUMMON_AREA - 1), function(anchor, position)
        if self.entity.body:canBePassable(position) then
            local hit = self.entity.hitter:createHit()
            hit:setDamage(Tags.DAMAGE_TYPE_SPELL, self.entity.stats:getEnemyAbility())
            hit:setSpawnFire(SKILL_DURATION, self.fireMinDamage, self.fireMaxDamage)
            hit:increaseBonusState()
            hit:applyToPosition(anchor, position)
        end

    end)
end

return function(entity, position, direction, id, difficulty, eliteID, forcedOrbChance)
    require("entities.common_enemy")(entity, position, direction, id, difficulty, eliteID, forcedOrbChance)
    entity.sprite:setCell(21, 5)
    entity:addComponent("melee")
    entity.melee.swingIcon = Vector:new(21, 9)
    entity.melee.enabled = false
    entity:addComponent("caster", SKILL)
    entity.caster.alignDistance = 4
    entity.caster.alignWhenNotReady = true
    entity:addComponent("projectilespawner")
    entity.projectilespawner:setCell(2, 1)
    entity.projectilespawner.isMagical = true
    entity:addComponent("ranged")
    entity.ranged.attackClass = RANGED_ATTACK
    entity.ranged.attackCooldown = 2
end

