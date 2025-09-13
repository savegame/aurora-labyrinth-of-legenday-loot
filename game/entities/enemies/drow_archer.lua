local Vector = require("utils.classes.vector")
local Common = require("common")
local ACTIONS_COMMON = require("actions.common")
local SKILL = require("structures.skill_def"):new()
SKILL:setCooldownToNormal()
SKILL.getCastDirection = function(entity, player)
    if not entity.ranged:isReady() then
        return false
    end

    local entityPos = entity.body:getPosition()
    local playerPos = player.body:getPosition()
    local distance = entityPos:distanceManhattan(playerPos)
    if entity.body:isAlignedTo(playerPos, true) then
        return Common.getDirectionTowards(entityPos, playerPos)
    end

    return false
end
SKILL.indicateArea = function(entity, direction, indicateGrid)
    local position = entity.body:getPosition()
    while true do
        position = position + Vector[direction]
        indicateGrid:set(position, true)
        if not entity.body:canBePassable(position) then
            return 
        end

    end

end
local SKILL_ACTION = class("actions.action")
SKILL.actionClass = SKILL_ACTION
local SHOT_SPEED = 0.05
local TRAIL_FADE_SPEED = 10
local TRAIL_FADE_REPEAT = 0.01
function SKILL_ACTION:initialize(entity, direction, abilityStats)
    SKILL_ACTION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("image")
end

function SKILL_ACTION:process(currentEvent)
    self.entity.sprite:turnToDirection(self.direction)
    self.entity.sprite.layer = Tags.LAYER_ABOVE_EFFECTS
    self.entity.ranged:setOnCooldown()
    Common.playSFX("BOW_SHOOT", 0.7)
    Common.playSFX("WHOOSH_BIG", 0.8)
    local source = self.entity.body:getPosition()
    local vDirection = Vector[self.direction]
    local distance = 0
    while true do
        distance = distance + 1
        if not self.entity.body:canBePassable(source + vDirection * distance) then
            break
        end

    end

    local shotHead = self.image:create("piercing_head")
    local shotTail, shotTrail = self.image:createWithTrail("piercing_tail")
    shotTrail.initialOpacity = 1
    shotTrail.fadeSpeed = TRAIL_FADE_SPEED
    shotTrail:chainTrailEvent(currentEvent, TRAIL_FADE_REPEAT)
    for i = 1, distance + 1 do
        local thisDistance = i
        currentEvent = currentEvent:chainProgress(SHOT_SPEED, function(progress)
            shotHead.position = source + vDirection * (thisDistance - 1 + progress)
            shotTail.position = shotHead.position
        end)
        if i <= distance then
            currentEvent = currentEvent:chainEvent(function(_, anchor)
                local hit = self.entity.hitter:createHit()
                hit:setDamage(Tags.DAMAGE_TYPE_SPELL, self.entity.stats:getEnemyAbility())
                hit:increaseBonusState()
                hit:applyToPosition(anchor, source + vDirection * thisDistance)
            end)
        end

    end

    return currentEvent:chainEvent(function(currentTime)
        self.image:stopAllTrails(currentTime)
        self.image:deleteImages()
    end)
end

return function(entity, position, direction, id, difficulty, eliteID, forcedOrbChance)
    require("entities.common_enemy")(entity, position, direction, id, difficulty, eliteID, forcedOrbChance)
    entity.sprite:setCell(11, 4)
    entity:addComponent("projectilespawner")
    entity.projectilespawner:setCell(1, 1)
    entity:addComponent("ranged")
    entity.ranged.attackClass = ACTIONS_COMMON.ARROW_SHOOT
    entity.ranged.attackCooldown = 2
    entity:addComponent("caster", SKILL)
    entity.caster.alignDistance = math.huge
    entity.caster.alignIgnoreBlocking = true
end

