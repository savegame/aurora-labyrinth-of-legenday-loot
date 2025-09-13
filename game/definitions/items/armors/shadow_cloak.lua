local Vector = require("utils.classes.vector")
local Common = require("common")
local CONSTANTS = require("logic.constants")
local ActionUtils = require("actions.utils")
local ACTIONS_FRAGMENT = require("actions.fragment")
local ACTION_CONSTANTS = require("actions.constants")
local TRIGGERS = require("actions.triggers")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Shadow Cloak")
local ABILITY = require("structures.ability_def"):new("Shadow Form")
ABILITY:addTag(Tags.ABILITY_TAG_BUFF_NOT_CONSIDERED)
ABILITY:addTag(Tags.ABILITY_TAG_BUFF_NO_EXTEND)
ABILITY:addTag(Tags.ABILITY_TAG_NEGATES_DAMAGE)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_ARMOR
ITEM.icon = Vector:new(11, 20)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 18, [Tags.STAT_MAX_MANA] = 42, [Tags.STAT_ABILITY_POWER] = 5, [Tags.STAT_ABILITY_BUFF_DURATION] = 10, [Tags.STAT_ABILITY_COUNT] = 3, [Tags.STAT_ABILITY_QUICK] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "{C:KEYWORD}Quick {C:KEYWORD}Buff %s - Prevent getting hit up to %s times."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_BUFF_DURATION, Tags.STAT_ABILITY_COUNT)
end
ABILITY.icon = Vector:new(12, 3)
ABILITY.iconColor = COLORS.STANDARD_DEATH
ABILITY.directions = false
ABILITY.indicate = ActionUtils.indicateSelf
local BUFF = class("structures.item_buff")
ABILITY.buffClass = BUFF
local TRIGGER = class(TRIGGERS.PRE_HIT)
function BUFF:initialize(duration, abilityStats)
    BUFF:super(self, "initialize", duration, abilityStats)
    self.expiresAtStart = true
    self.instances = abilityStats:get(Tags.STAT_ABILITY_COUNT)
    self.triggerClasses:push(TRIGGER)
end

function BUFF:toData()
    return { instances = self.instances }
end

function BUFF:fromData(data)
    self.instances = data.instances
end

function BUFF:reduceInstances(anchor, entity)
    self.instances = self.instances - 1
    if self.instances == 0 then
        entity.equipment:deactivateSlot(anchor, self.abilityStats:get(Tags.STAT_SLOT))
    end

end

function BUFF:decorateTriggerAction(action)
    BUFF:super(self, "decorateTriggerAction", action)
    action.buff = self
end

local FLASH_COLOR = require("utils.classes.color").BLACK
function TRIGGER:initialize(entity, direction, abilityStats)
    TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self.sortOrder = 11
    self.buff = false
end

function TRIGGER:isEnabled()
    return self.hit:isDamageOrDebuff()
end

function TRIGGER:parallelResolve(anchor)
    self.hit:clear()
    self.hit.sound = "HIT_BLOCKED"
    self.buff:reduceInstances(anchor, self.entity)
end

function TRIGGER:process(currentEvent)
    self.entity.charactereffects:flash(ACTION_CONSTANTS.STANDARD_FLASH_DURATION, FLASH_COLOR)
    return currentEvent
end

function BUFF:decorateOutgoingHit(hit)
    if self.abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 then
        if hit:isDamagePositiveDirect() then
            if hit:getApplyDistance() <= 1 then
                hit.minDamage = hit.minDamage + self.abilityStats:get(Tags.STAT_MODIFIER_DAMAGE_MIN)
                hit.maxDamage = hit.maxDamage + self.abilityStats:get(Tags.STAT_MODIFIER_DAMAGE_MAX)
                hit:increaseBonusState()
            end

        end

    end

end

function BUFF:getColorTint(timePassed)
    return FLASH_COLOR:withAlpha(Common.getPulseOpacity(timePassed, 0.4, 0.6))
end

local ACTION = class(ACTIONS_FRAGMENT.SHOW_ICON_SELF)
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self.icon = ITEM.icon
    self.color = ABILITY.iconColor
end

local LEGENDARY = ITEM:createLegendary("The Color of Betrayal")
local LEGENDARY_EXTRA_LINE = "Deal %s bonus damage to adjacent enemies while this " .. "{C:KEYWORD}Buff is active."
LEGENDARY.strokeColor = COLORS.STANDARD_RAGE
LEGENDARY:setToStatsBase({ [Tags.STAT_MODIFIER_DAMAGE_BASE] = 9.2, [Tags.STAT_MODIFIER_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.0) })
LEGENDARY.abilityExtraLine = function(item)
    return textStatFormat(LEGENDARY_EXTRA_LINE, item, Tags.STAT_MODIFIER_DAMAGE_MIN)
end
return ITEM

