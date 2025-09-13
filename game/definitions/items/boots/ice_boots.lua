local Set = require("utils.classes.set")
local Vector = require("utils.classes.vector")
local Common = require("common")
local ActionUtils = require("actions.utils")
local ACTIONS_FRAGMENT = require("actions.fragment")
local ACTION_CONSTANTS = require("actions.constants")
local BUFFS = require("definitions.buffs")
local COLORS = require("draw.colors")
local TERMS = require("text.terms")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Ice Boots")
local ABILITY = require("structures.ability_def"):new("Cold Step")
ABILITY:addTag(Tags.ABILITY_TAG_DEBUFF_COLD)
ABILITY:addTag(Tags.ABILITY_TAG_DISENGAGE_MELEE)
ABILITY:addTag(Tags.ABILITY_TAG_MOVEMENT_EXTENDABLE)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_BOOTS
ITEM.icon = Vector:new(14, 14)
ITEM:setToStatsBase({ [Tags.STAT_MAX_MANA] = 40, [Tags.STAT_ABILITY_POWER] = 2.5, [Tags.STAT_ABILITY_RANGE] = 1, [Tags.STAT_ABILITY_DEBUFF_DURATION] = 2, [Tags.STAT_ABILITY_AREA_ROUND] = Tags.ABILITY_AREA_CROSS })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_DEBUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_DEBUFF_DURATION] = 1 })
local FORMAT_SHORT = "Apply {C:KEYWORD}Cold for %s to all adjacent enemies. Move %s."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT_SHORT, item, Tags.STAT_ABILITY_DEBUFF_DURATION, Tags.STAT_ABILITY_RANGE)
end
ABILITY.icon = Vector:new(11, 2)
ABILITY.iconColor = COLORS.STANDARD_ICE
ABILITY.getInvalidReason = function(entity, direction, abilityStats)
    if not entity.buffable:canMove() then
        return false
    else
        return ActionUtils.getInvalidReasonFrontIsNotPassable(entity, direction, abilityStats)
    end

end
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    local isPassable = entity.body:isPassableDirection(direction)
    local canMove = entity.buffable:canMove()
    if isPassable and canMove then
        local moveTo = ActionUtils.getDashMoveTo(entity, direction, abilityStats)
        castingGuide:indicateMoveTo(moveTo)
    end

    for targetDirection in DIRECTIONS_AA() do
        if targetDirection ~= direction or not canMove then
            if isPassable or not canMove then
                castingGuide:indicate(entity.body:getPosition() + Vector[targetDirection])
            else
                castingGuide:indicateWeak(entity.body:getPosition() + Vector[targetDirection])
            end

        end

    end

end
ABILITY.directions = function(entity, abilityStats)
    if not entity.buffable:canMove() then
        return false
    else
        return DIRECTIONS_AA
    end

end
local EXPLOSION_DURATION = 0.5
local ACTION = class(ACTIONS_FRAGMENT.TRAIL_MOVE)
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("explosion")
    self.explosion:setHueToIce()
    self.explosion.excludeSelf = true
    self.stepDuration = ACTION_CONSTANTS.WALK_DURATION
end

function ACTION:parallelResolve(currentEvent)
    self.explosion.source = self.entity.body:getPosition()
    self.entity.sprite:turnToDirection(self.direction)
    local moveTo = ActionUtils.getDashMoveTo(self.entity, self.direction, self.abilityStats)
    self.distance = self.entity.body:getPosition():distanceManhattan(moveTo)
    if self.entity.buffable:canMove() then
        ACTION:super(self, "parallelResolve", currentEvent)
    end

end

function ACTION:process(currentEvent)
    self.entity.sprite.layer = Tags.LAYER_ABOVE_EFFECTS
    self.explosion:setArea(self.abilityStats:get(Tags.STAT_ABILITY_AREA_ROUND))
    Common.playSFX("EXPLOSION_ICE", 1.2)
    local lastEvent = self.explosion:chainFullEvent(currentEvent, EXPLOSION_DURATION, function(anchor, target)
        if target ~= self.entity.body:getPosition() then
            local hit = self.entity.hitter:createHit()
            local duration = self.abilityStats:get(Tags.STAT_ABILITY_DEBUFF_DURATION)
            hit:addBuff(BUFFS:get("COLD"):new(duration))
            hit:applyToPosition(anchor, target)
        end

    end)
    if self.entity.buffable:canMove() then
        lastEvent = ACTION:super(self, "process", currentEvent)
    end

    return lastEvent:chainEvent(function()
        self.entity.sprite:resetLayer()
    end)
end

local LEGENDARY = ITEM:createLegendary("Hoarfrost Gliders")
LEGENDARY.statLine = "Whenever you step onto a space adjacent to a " .. "{C:KEYWORD}Cold enemy, that step is {C:KEYWORD}Quick."
LEGENDARY.decorateBasicMove = function(entity, action, abilityStats)
    local source = entity.body:getPosition() + Vector[action.direction]
    for direction in DIRECTIONS_AA() do
        local entityAt = entity.body:getEntityAt(source + Vector[direction])
        if ActionUtils.isAliveAgent(entityAt) then
            if entityAt.buffable:isAffectedBy(BUFFS:get("COLD")) then
                action:setToQuick()
            end

        end

    end

end
return ITEM

