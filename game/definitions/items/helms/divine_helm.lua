local Vector = require("utils.classes.vector")
local Common = require("common")
local CONSTANTS = require("logic.constants")
local ActionUtils = require("actions.utils")
local ACTIONS_FRAGMENT = require("actions.fragment")
local TRIGGERS = require("actions.triggers")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Divine Helm")
local ABILITY = require("structures.ability_def"):new("Enchant Holy")
ABILITY:addTag(Tags.ABILITY_TAG_RESTORES_HEALTH)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_HELM
ITEM.icon = Vector:new(7, 13)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 32, [Tags.STAT_MAX_MANA] = 8, [Tags.STAT_ABILITY_POWER] = 4.2, [Tags.STAT_ABILITY_BUFF_DURATION] = 3, [Tags.STAT_ABILITY_DAMAGE_BASE] = 8.2, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.37), [Tags.STAT_ABILITY_QUICK] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_BUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_BUFF_DURATION] = 1 })
local FORMAT = "{C:KEYWORD}Quick {C:KEYWORD}Buff %s - Your {C:KEYWORD}Attacks " .. "against enemies restore %s health."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_BUFF_DURATION, Tags.STAT_ABILITY_DAMAGE_MIN)
end
ABILITY.icon = Vector:new(8, 1)
ABILITY.iconColor = COLORS.STANDARD_HOLY
ABILITY.directions = false
ABILITY.indicate = ActionUtils.indicateSelf
local LEGENDARY_TRIGGER = class(TRIGGERS.ON_KILL)
local TRIGGER = class(TRIGGERS.ON_DAMAGE)
function TRIGGER:process(currentEvent)
    return currentEvent:chainEvent(function(_, anchor)
        local hit = self.entity.hitter:createHit()
        hit:setHealing(self.abilityStats:get(Tags.STAT_ABILITY_DAMAGE_MIN), self.abilityStats:get(Tags.STAT_ABILITY_DAMAGE_MAX), self.abilityStats)
        hit:applyToEntity(anchor, self.entity)
    end)
end

function TRIGGER:isEnabled()
    return (self.hit.damageType == Tags.DAMAGE_TYPE_MELEE and self.hit:isDamagePositive() and self.hit:isTargetAgent())
end

local BUFF = class("structures.item_buff")
ABILITY.buffClass = BUFF
function BUFF:initialize(duration, abilityStats, action)
    BUFF:super(self, "initialize", duration, abilityStats, action)
    self.triggerClasses:push(TRIGGER)
    if abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 then
        self.triggerClasses:push(LEGENDARY_TRIGGER)
    end

    self.outlinePulseColor = ABILITY.iconColor
    self.delayNext = false
end

function BUFF:onTurnEnd()
    if self.delayNext then
        self.delayNext = false
        self.duration = self.duration + 1
    end

end

local ACTION = class(ACTIONS_FRAGMENT.ENCHANT)
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self.color = ABILITY.iconColor
end

local LEGENDARY = ITEM:createLegendary("Faith's Reward")
LEGENDARY.abilityExtraLine = "Whenever you kill an enemy with an {C:KEYWORD}Attack, reset this " .. "ability's duration."
function LEGENDARY_TRIGGER:isEnabled()
    if not self.killed:hasComponent("agent") then
        return false
    end

    return self.killingHit and self.killingHit.damageType == Tags.DAMAGE_TYPE_MELEE
end

function LEGENDARY_TRIGGER:process(currentEvent)
    local slot = self:getSlot()
    local entity = self.entity
    local currentDuration = entity.equipment:getDuration(slot)
    entity.equipment:extendSlotBuff(slot, self.abilityStats:get(Tags.STAT_ABILITY_BUFF_DURATION) - currentDuration)
    entity.equipment.slotBuffs:get(slot).delayNext = entity.buffable.delayAllNonStart
    return currentEvent
end

return ITEM

