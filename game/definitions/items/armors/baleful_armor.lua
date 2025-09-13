local Vector = require("utils.classes.vector")
local Common = require("common")
local CONSTANTS = require("logic.constants")
local ActionUtils = require("actions.utils")
local ACTIONS_FRAGMENT = require("actions.fragment")
local TRIGGERS = require("actions.triggers")
local BUFFS = require("definitions.buffs")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Baleful Armor")
local ABILITY = require("structures.ability_def"):new("Venomous Skin")
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_ARMOR
ITEM.icon = Vector:new(20, 13)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 52, [Tags.STAT_MAX_MANA] = 8, [Tags.STAT_ABILITY_POWER] = 4.24, [Tags.STAT_ABILITY_BUFF_DURATION] = 3, [Tags.STAT_ABILITY_DEBUFF_DURATION] = 4, [Tags.STAT_POISON_DAMAGE_BASE] = 6.2, [Tags.STAT_ABILITY_QUICK] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_BUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_DEBUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_BUFF_DURATION] = 1 })
local FORMAT = "{C:KEYWORD}Quick {C:KEYWORD}Buff %s - Whenever you get hit, {C:KEYWORD}Poison the " .. "attacker, making it lose %s health over %s."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_BUFF_DURATION, Tags.STAT_POISON_DAMAGE_TOTAL, Tags.STAT_ABILITY_DEBUFF_DURATION)
end
ABILITY.icon = Vector:new(11, 3)
ABILITY.iconColor = COLORS.STANDARD_POISON
ABILITY.directions = false
ABILITY.indicate = ActionUtils.indicateSelf
local TRIGGER = class(TRIGGERS.POST_HIT)
function TRIGGER:process(currentEvent)
    return currentEvent:chainEvent(function(_, anchor)
        local hit = self.entity.hitter:createHit()
        hit.sound = "POISON_DAMAGE"
        hit.targetEntity = self.hit.sourceEntity
        local duration = self.abilityStats:get(Tags.STAT_ABILITY_DEBUFF_DURATION)
        local poisonDamage = self.abilityStats:get(Tags.STAT_POISON_DAMAGE_TOTAL)
        hit:addBuff(BUFFS:get("POISON"):new(duration, self.entity, poisonDamage))
        hit:applyToEntity(anchor, self.hit.sourceEntity)
    end)
end

local BUFF = class("structures.item_buff")
ABILITY.buffClass = BUFF
function BUFF:initialize(duration, abilityStats, action)
    BUFF:super(self, "initialize", duration, abilityStats, action)
    self.triggerClasses:push(TRIGGER)
    self.expiresAtStart = true
    self.outlinePulseColor = ABILITY.iconColor
end

local BLOCK_ICON = Vector:new(4, 19)
local ACTION = class(ACTIONS_FRAGMENT.SHOW_ICON_SELF)
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self.icon = BLOCK_ICON
    self.color = ABILITY.iconColor
end

local LEGENDARY = ITEM:createLegendary("Scales of the Great Serpent")
local LEGENDARY_STAT_LINE = "Deal %s bonus damage to {C:KEYWORD}Poisoned enemies."
LEGENDARY:setToStatsBase({ [Tags.STAT_MODIFIER_DAMAGE_BASE] = 11.25, [Tags.STAT_MODIFIER_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.2) })
LEGENDARY.statLine = function(item)
    return textStatFormat(LEGENDARY_STAT_LINE, item, Tags.STAT_MODIFIER_DAMAGE_MIN)
end
LEGENDARY.decorateOutgoingHit = function(entity, hit, abilityStats)
    if hit:isDamagePositiveDirect() then
        if hit.targetEntity and hit.targetEntity:hasComponent("buffable") then
            if hit.targetEntity.buffable:isAffectedBy(BUFFS:get("POISON")) then
                hit.minDamage = hit.minDamage + abilityStats:get(Tags.STAT_MODIFIER_DAMAGE_MIN)
                hit.maxDamage = hit.maxDamage + abilityStats:get(Tags.STAT_MODIFIER_DAMAGE_MAX)
                hit:increaseBonusState()
            end

        end

    end

end
return ITEM

