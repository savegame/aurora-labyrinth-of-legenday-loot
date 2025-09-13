local Vector = require("utils.classes.vector")
local Common = require("common")
local BUFFS = require("definitions.buffs")
local ATTACK_WEAPON = require("actions.attack_weapon")
local ACTIONS_FRAGMENT = require("actions.fragment")
local COLORS = require("draw.colors")
local SKILL = require("structures.skill_def"):new()
local MIN_RANGE = 2
local MAX_RANGE = 4
local DURATION_STUN = 1
SKILL.cooldown = 5
SKILL.getCastDirection = function(entity, player)
    local entityPos = entity.body:getPosition()
    local playerPos = player.body:getPosition()
    if entityPos.x ~= playerPos.x and entityPos.y ~= playerPos.y then
        return false
    end

    local distance = entityPos:distanceManhattan(playerPos)
    if distance >= MIN_RANGE and distance <= MAX_RANGE then
        local direction = Common.getDirectionTowards(entityPos, playerPos)
        for i = 1, distance do
            if not entity.body:canBePassable(entityPos + Vector[direction] * i) then
                return false
            end

        end

        return direction
    else
        return false
    end

end
SKILL.indicateArea = function(entity, direction, indicateGrid)
    local position = entity.body:getPosition()
    for i = MIN_RANGE, MAX_RANGE do
        indicateGrid:set(position + Vector[direction] * i, true)
    end

end
local SKILL_ACTION = class(ACTIONS_FRAGMENT.CAST)
SKILL.actionClass = SKILL_ACTION
function SKILL_ACTION:initialize(entity, direction, abilityStats)
    SKILL_ACTION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("lightningspawner")
    self.color = COLORS.STANDARD_LIGHTNING
end

local STRIKE_INTERVAL = 0.08
function SKILL_ACTION:process(currentEvent)
    currentEvent = SKILL_ACTION:super(self, "process", currentEvent):chainEvent(function()
        Common.playSFX("LIGHTNING")
    end)
    local lastEvent = currentEvent
    local source = self.entity.body:getPosition()
    for i = 1, MAX_RANGE do
        local target = source + Vector[self.direction] * i
        if not self.entity.body:canBePassable(target) then
            break
        end

        if i >= MIN_RANGE then
            lastEvent = self.lightningspawner:spawn(currentEvent, target):chainEvent(function(_, anchor)
                local hit = self.entity.hitter:createHit()
                hit:setDamage(Tags.DAMAGE_TYPE_SPELL, self.entity.stats:getEnemyAbility())
                hit:increaseBonusState()
                hit:addBuff(BUFFS:get("STUN"):new(DURATION_STUN))
                hit:applyToPosition(anchor, target)
            end)
            currentEvent = currentEvent:chainProgress(STRIKE_INTERVAL)
        end

    end

    return lastEvent
end

return function(entity, position, direction, id, difficulty, eliteID, forcedOrbChance)
    require("entities.common_enemy")(entity, position, direction, id, difficulty, eliteID, forcedOrbChance)
    entity.sprite:setCell(20, 5)
    entity:addComponent("melee")
    entity.melee.swingIcon = Vector:new(21, 9)
    entity.melee.attackClass = ATTACK_WEAPON.SWING_AND_DAMAGE
    entity:addComponent("caster", SKILL)
    entity.caster.alignDistance = 4
    entity.caster.alignWhenNotReady = true
    entity.caster.alignIgnoreBlocking = true
end

