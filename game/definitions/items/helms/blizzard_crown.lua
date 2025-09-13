local Array = require("utils.classes.array")
local Vector = require("utils.classes.vector")
local Common = require("common")
local ActionUtils = require("actions.utils")
local TRIGGERS = require("actions.triggers")
local ACTIONS_FRAGMENT = require("actions.fragment")
local ACTION_CONSTANTS = require("actions.constants")
local BUFFS = require("definitions.buffs")
local COLORS = require("draw.colors")
local TERMS = require("text.terms")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Blizzard Crown")
local ABILITY = require("structures.ability_def"):new("Blizzard")
ABILITY:addTag(Tags.ABILITY_TAG_DEBUFF_COLD)
ABILITY:addTag(Tags.ABILITY_TAG_BOOSTABLE_PERIODIC_DAMAGE)
ABILITY:addTag(Tags.ABILITY_TAG_SUSTAIN_CAN_KILL)
ABILITY:addTag(Tags.ABILITY_TAG_BUFF_HALF_CONSIDERED)
ITEM:setToMediumComplexity()
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_HELM
ITEM.icon = Vector:new(12, 17)
ITEM:setToStatsBase({ [Tags.STAT_MAX_MANA] = 40, [Tags.STAT_ABILITY_POWER] = 6.6, [Tags.STAT_ABILITY_BUFF_DURATION] = 4, [Tags.STAT_ABILITY_SUSTAIN_MODE] = Tags.SUSTAIN_MODE_FULL, [Tags.STAT_ABILITY_DEBUFF_DURATION] = 2, [Tags.STAT_ABILITY_DAMAGE_BASE] = 11.3, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.03), [Tags.STAT_ABILITY_RANGE] = 4, [Tags.STAT_ABILITY_AREA_ROUND] = Tags.ABILITY_AREA_3X3 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_BUFF_DURATION] = 1 })
local FORMAT = "{C:KEYWORD}Sustain %s - Deal %s damage to all targets " .. "in a %s %s away. Apply {C:KEYWORD}Cold to all targets for %s."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_BUFF_DURATION, Tags.STAT_ABILITY_DAMAGE_MIN, Tags.STAT_ABILITY_AREA_ROUND, Tags.STAT_ABILITY_RANGE, Tags.STAT_ABILITY_DEBUFF_DURATION)
end
ABILITY.icon = Vector:new(8, 8)
ABILITY.iconColor = COLORS.STANDARD_ICE
ABILITY.getInvalidReason = function(entity, direction, abilityStats)
    local source = entity.body:getPosition()
    local range = abilityStats:get(Tags.STAT_ABILITY_RANGE) - 1
    for i = 1, range do
        if not entity.body:canBePassable(source + Vector[direction] * i) then
            return TERMS.INVALID_DIRECTION_BLOCKED
        end

    end

    return false
end
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    if not ABILITY.getInvalidReason(entity, direction, abilityStats) then
        local range = abilityStats:get(Tags.STAT_ABILITY_RANGE)
        local area = abilityStats:get(Tags.STAT_ABILITY_AREA_ROUND)
        local target = entity.body:getPosition() + Vector[direction] * range
        if abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 then
            ActionUtils.indicateArea(entity, target, Tags.ABILITY_AREA_ROUND_5X5, castingGuide, true, true)
        end

        ActionUtils.indicateArea(entity, target, area, castingGuide)
    end

end
local TRIGGER = class(TRIGGERS.END_OF_TURN)
local ON_HIT = class(ACTIONS_FRAGMENT.EXPLOSIVE_HIT)
function ON_HIT:initialize(entity, direction, abilityStats)
    ON_HIT:super(self, "initialize", entity, direction, abilityStats)
    self.explosion:setHueToIce()
end

function ON_HIT:parallelResolve(anchor)
    ON_HIT:super(self, "parallelResolve", anchor)
    local duration = self.abilityStats:get(Tags.STAT_ABILITY_DEBUFF_DURATION)
    self.hit:setDamageFromAbilityStats(Tags.DAMAGE_TYPE_SPELL, self.abilityStats)
    self.hit:addBuff(BUFFS:get("COLD"):new(duration))
    self.explosion:setArea(Tags.ABILITY_AREA_SINGLE)
    self.sound = false
    self.hit.sound = "EXPLOSION_SMALL"
end

function ON_HIT:process(currentEvent)
    self.entity.entityspawner:spawn("temporary_vision", self.targetPosition, 2)
    return ON_HIT:super(self, "process", currentEvent)
end

function TRIGGER:initialize(entity, direction, abilityStats)
    TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("projectilerain")
    self.projectilerain.projectile = Vector:new(1, 1)
    self.projectilerain.onHitClass = ON_HIT
    self.largerArea = false
end

function TRIGGER:parallelResolve(anchor)
    self.projectilerain.area = self.abilityStats:get(Tags.STAT_ABILITY_AREA_ROUND)
    if self.largerArea then
        self.projectilerain.area = Tags.ABILITY_AREA_ROUND_5X5
        self.projectilerain.dropGap = 0.075
    else
        self.projectilerain.dropGap = 0.1
    end

    local range = self.abilityStats:get(Tags.STAT_ABILITY_RANGE)
    self.projectilerain.source = self.entity.body:getPosition() + Vector[self.direction] * range
end

function TRIGGER:process(currentEvent)
    if self.projectilerain.area > Tags.ABILITY_AREA_3X3 then
        Common.playSFX("BLIZZARD", 0.65)
    else
        Common.playSFX("BLIZZARD", 1)
    end

    return self.projectilerain:chainRainEvent(currentEvent)
end

local BUFF = class(BUFFS.DEACTIVATOR)
ABILITY.buffClass = BUFF
function BUFF:initialize(duration, abilityStats)
    BUFF:super(self, "initialize", duration, abilityStats)
    self.outlinePulseColor = ABILITY.iconColor
    self.triggerClasses:push(TRIGGER)
    self.expiresImmediately = true
    self.sustainedOnce = false
end

function BUFF:toData()
    return { sustainedOnce = self.sustainedOnce }
end

function BUFF:fromData(data)
    self.sustainedOnce = data.sustainedOnce
end

function BUFF:onTurnEnd(anchor, entity)
    BUFF:super(self, "onTurnEnd", anchor, entity)
    self.sustainedOnce = true
end

function BUFF:decorateTriggerAction(action)
    BUFF:super(self, "decorateTriggerAction", action)
    if self.abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 and self.sustainedOnce then
        action.largerArea = true
    end

end

function BUFF:onTurnStart(anchor, entity)
    if self.action:shouldDeactivate() then
        entity.equipment:deactivateSlot(anchor, self.abilityStats:get(Tags.STAT_SLOT))
    end

end

local ACTION = class(ACTIONS_FRAGMENT.CAST)
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self.color = ABILITY.iconColor
    self:speedMultiply(ACTION_CONSTANTS.SLOW_CAST_MULTIPLIER)
    self.keepSwingItem = true
    self.weaponswing.angleEnd = math.tau * 0.125
end

function ACTION:deactivate()
    self.weaponswing:deleteSwingItem()
end

function ACTION:setFromLoad()
    self.weaponswing:createAtEnd()
end

function ACTION:shouldDeactivate()
    return ABILITY.getInvalidReason(self.entity, self.direction, self.abilityStats)
end

function ACTION:process(currentEvent)
    local range = self.abilityStats:get(Tags.STAT_ABILITY_RANGE)
    local area = self.abilityStats:get(Tags.STAT_ABILITY_AREA_ROUND)
    local source = self.entity.body:getPosition() + Vector[self.direction] * range
    local positions = ActionUtils.getAreaPositions(self.entity, source, area)
    return ACTION:super(self, "process", currentEvent)
end

local LEGENDARY = ITEM:createLegendary("Northern Sovereign")
LEGENDARY.abilityExtraLine = "Grows to a {C:KEYWORD}Large {C:KEYWORD}Area after {C:KEYWORD}Sustaining once."
LEGENDARY.modifyItem = function(item)
end
return ITEM

