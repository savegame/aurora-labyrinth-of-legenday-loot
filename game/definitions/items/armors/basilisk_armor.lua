local Vector = require("utils.classes.vector")
local BUFFS = require("definitions.buffs")
local Common = require("common")
local CONSTANTS = require("logic.constants")
local ACTION_CONSTANTS = require("actions.constants")
local ActionUtils = require("actions.utils")
local textStatFormat = require("text.stat_format")
local COLORS = require("draw.colors")
local ITEM = require("structures.item_def"):new("Basilisk Armor")
local ABILITY = require("structures.ability_def"):new("Petrifying Gaze")
ABILITY:addTag(Tags.ABILITY_TAG_DEBUFF_EXTENDABLE)
ABILITY:addTag(Tags.ABILITY_TAG_DIRECTIONAL_RECASTABLE)
ABILITY:addTag(Tags.ABILITY_TAG_RANGE_EXTENDABLE)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_ARMOR
ITEM.icon = Vector:new(16, 20)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 46, [Tags.STAT_MAX_MANA] = 14, [Tags.STAT_ABILITY_POWER] = 3.5, [Tags.STAT_ABILITY_DEBUFF_DURATION] = 4, [Tags.STAT_ABILITY_DENOMINATOR] = 5, [Tags.STAT_ABILITY_RANGE] = 2 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_COST] = -5 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_DEBUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_RANGE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_DEBUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_DENOMINATOR] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_DEBUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_RANGE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_DENOMINATOR] = -1 })
local FORMAT = "{C:KEYWORD}Range %s -  Turn an enemy into stone for %s. It cannot take " .. "any actions, but it only takes %s damage and health loss."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_RANGE_MIN, Tags.STAT_ABILITY_DEBUFF_DURATION, Tags.STAT_ABILITY_DENOMINATOR)
end
ABILITY.icon = Vector:new(10, 7)
ABILITY.iconColor = COLORS.STANDARD_EARTH
ABILITY.getInvalidReason = ActionUtils.getInvalidReasonEnemy
ABILITY.indicate = ActionUtils.indicateEnemyWithinRange
local DEBUFF = BUFFS:define("PETRIFY")
function DEBUFF:initialize(duration, denominator)
    DEBUFF:super(self, "initialize", duration)
    self.disablesAction = true
    self.flashOnApply = true
    self.denominator = denominator
end

function DEBUFF:getDataArgs()
    return self.duration, self.denominator
end

function DEBUFF:onApply(entity)
    entity.sprite.timeStopped = true
end

function DEBUFF:decorateIncomingHit(hit)
    if hit:isDamagePositive() then
        hit:multiplyDamage(1 / self.denominator)
        hit:decreaseBonusState()
    end

end

function DEBUFF:onDelete(anchor, entity)
    entity.sprite.timeStopped = false
    entity.charactereffects.negativeOverlay = 1
    Common.playSFX("AFFLICT", 0.8)
end

function DEBUFF:decorateTriggerAction(action)
    action.denominator = self.denominator
end

local ACTION = class("actions.action")
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("outline")
    self.outline.color = ABILITY.iconColor
end

function ACTION:process(currentEvent)
    self.entity.sprite:turnToDirection(self.direction)
    Common.playSFX("CAST_CHARGE")
    currentEvent = self.outline:chainFullEvent(currentEvent, ACTION_CONSTANTS.MAJOR_CAST_CHARGE_DURATION):chainEvent(function(_, anchor)
        local targetEntity = ActionUtils.getEnemyWithinRange(self.entity, self.direction, self.abilityStats)
        local hit = self.entity.hitter:createHit()
        hit.sound = "AFFLICT"
        local duration = self.abilityStats:get(Tags.STAT_ABILITY_DEBUFF_DURATION)
        local denominator = self.abilityStats:get(Tags.STAT_ABILITY_DENOMINATOR)
        hit:addBuff(DEBUFF:new(duration, denominator))
        hit:applyToEntity(anchor, targetEntity)
    end)
    return currentEvent
end

local LEGENDARY = ITEM:createLegendary("Stoneskin")
local LEGENDARY_STAT_LINE = "{C:KEYWORD}Resist %s"
LEGENDARY:setToStatsBase({ [Tags.STAT_MODIFIER_VALUE] = 2 })
LEGENDARY:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
LEGENDARY.statLine = function(item)
    return textStatFormat(LEGENDARY_STAT_LINE, item, Tags.STAT_MODIFIER_VALUE)
end
LEGENDARY.modifyItem = function(item)
    item:markAltered(Tags.STAT_MODIFIER_VALUE, Tags.STAT_UPGRADED)
end
LEGENDARY.decorateIncomingHit = function(entity, hit, abilityStats)
    if hit:isDamagePositiveDirect() then
        hit:reduceDamage(abilityStats:get(Tags.STAT_MODIFIER_VALUE))
    end

end
return ITEM

