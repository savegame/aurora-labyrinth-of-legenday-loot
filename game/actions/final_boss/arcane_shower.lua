local SKILL = require("structures.skill_def"):new()
local BUFFS = require("definitions.buffs")
local Common = require("common")
local Array = require("utils.classes.array")
local Vector = require("utils.classes.vector")
local COLORS = require("draw.colors")
local ACTION_CONSTANTS = require("actions.constants")
local ACTIONS_FRAGMENT = require("actions.fragment")
local ActionUtils = require("actions.utils")
local TRIGGERS = require("actions.triggers")
local SKILL_AREA = Tags.ABILITY_AREA_3X3
SKILL.cooldown = 8
local MAX_DURATION = 3
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
    if playerPos:distanceManhattan(entityPos) <= MAX_DURATION + 2 then
        return direction
    else
        return false
    end

end
SKILL.indicateArea = function(entity, direction, indicateGrid)
    local position = entity.body:getPosition()
    local center = position + Vector[direction] * 2
    local positions = ActionUtils.getAreaPositions(entity, center, SKILL_AREA)
    for position in positions() do
        indicateGrid:set(position, true)
    end

end
local TRIGGER = class(TRIGGERS.END_OF_TURN)
local ON_HIT = class(ACTIONS_FRAGMENT.EXPLOSIVE_HIT)
function ON_HIT:initialize(entity, direction, abilityStats)
    ON_HIT:super(self, "initialize", entity, direction, abilityStats)
    self.explosion:setHueToDeath()
    self.sound = "EXPLOSION_MEDIUM"
    self.soundPitch = 1.5
end

function ON_HIT:parallelResolve(anchor)
    ON_HIT:super(self, "parallelResolve", anchor)
    self.hit:setDamage(Tags.DAMAGE_TYPE_SPELL, self.entity.stats:getEnemyAbility())
    self.hit:increaseBonusState()
end

function TRIGGER:initialize(entity, direction, abilityStats)
    TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("projectilerain")
    self.projectilerain.onHitClass = ON_HIT
    self.projectilerain.projectile = Vector:new(3, 1)
    self.projectilerain.dropGap = 0
end

function TRIGGER:process(currentEvent)
    return self.projectilerain:chainRainEvent(currentEvent)
end

local BUFF = BUFFS:define("BOSS_ARCANE_SHOWER")
function BUFF:initialize(duration, position, direction)
    BUFF:super(self, "initialize", duration)
    self.triggerClasses:push(TRIGGER)
    self.position = position
    self.direction = direction
    self.hazards = Array:new()
end

function BUFF:getDataArgs()
    return self.duration, self.position, self.direction
end

function BUFF:decorateTriggerAction(action)
    action.direction = self.direction
    action.projectilerain.source = self.position
end

function BUFF:onTurnStart(anchor, entity)
end

function BUFF:onApply(entity)
end

function BUFF:onTurnEnd(anchor, entity)
    self.position = self.position + Vector[self.direction]
        if not entity.body:canBePassable(self.position) then
        entity.buffable:delete(anchor, BUFF)
    elseif self.duration > 1 then
        local positions = ActionUtils.getAreaPositions(entity, self.position, SKILL_AREA)
        for position in positions() do
            for position in positions() do
                entity.entityspawner:spawn("hazard", position)
            end

        end

    end

end

local SKILL_ACTION = class("actions.action")
SKILL.actionClass = SKILL_ACTION
function SKILL_ACTION:initialize(entity, direction, abilityStats)
    SKILL_ACTION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("outline")
    self.outline.color = COLORS.STANDARD_DEATH
end

function SKILL_ACTION:process(currentEvent)
    self.entity.ranged:setOnCooldown()
    Common.playSFX("CAST_CHARGE", 1.0)
    return self.outline:chainFullEvent(currentEvent, ACTION_CONSTANTS.MAJOR_CAST_CHARGE_DURATION):chainEvent(function(_, anchor)
        local position = self.entity.body:getPosition() + Vector[self.direction] * 2
        self.entity.buffable:forceApply(BUFF:new(MAX_DURATION, position, self.direction))
    end)
end

return SKILL

