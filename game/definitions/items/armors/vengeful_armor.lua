local Vector = require("utils.classes.vector")
local CONSTANTS = require("logic.constants")
local BUFFS = require("definitions.buffs")
local ActionUtils = require("actions.utils")
local ACTIONS_FRAGMENT = require("actions.fragment")
local TRIGGERS = require("actions.triggers")
local PLAYER_TRIGGERS = require("actions.player_triggers")
local Common = require("common")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Vengeful Armor")
local ABILITY = require("structures.ability_def"):new("Vengeful Stance")
ABILITY:addTag(Tags.ABILITY_TAG_PLUS_BASIC_ATTACK)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_ARMOR
ITEM.icon = Vector:new(21, 13)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 60, [Tags.STAT_ABILITY_POWER] = 2.475, [Tags.STAT_ABILITY_BUFF_DURATION] = 1, [Tags.STAT_ABILITY_DAMAGE_BASE] = 6.8, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.59) })
ITEM:setGrowthMultiplier({ [Tags.STAT_ABILITY_DAMAGE_BASE] = 2.5 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "{C:KEYWORD}Buff %s - Whenever you get hit by an enemy, {C:KEYWORD}Attack it. Your {C:KEYWORD}Attacks deal %s bonus damage."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_BUFF_DURATION, Tags.STAT_ABILITY_DAMAGE_MIN)
end
ABILITY.icon = Vector:new(8, 3)
ABILITY.iconColor = COLORS.STANDARD_RAGE
ABILITY.directions = false
ABILITY.indicate = ActionUtils.indicateSelf
local BUFF = class("structures.item_buff")
ABILITY.buffClass = BUFF
function BUFF:decorateOutgoingHit(hit)
    if hit.damageType == Tags.DAMAGE_TYPE_MELEE and hit:isDamagePositive() then
        hit.minDamage = hit.minDamage + self.abilityStats:get(Tags.STAT_ABILITY_DAMAGE_MIN)
        hit.maxDamage = hit.maxDamage + self.abilityStats:get(Tags.STAT_ABILITY_DAMAGE_MAX)
        hit:increaseBonusState()
    end

end

function BUFF:initialize(duration, abilityStats, action)
    BUFF:super(self, "initialize", duration, abilityStats, action)
    self.triggerClasses:push(PLAYER_TRIGGERS.COUNTER_ATTACK)
    self.expiresAtStart = true
    self.outlinePulseColor = ABILITY.iconColor
end

local ACTION = class(ACTIONS_FRAGMENT.ENCHANT)
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self.color = ABILITY.iconColor
end

local LEGENDARY = ITEM:createLegendary("Oathsworn Sentinel")
LEGENDARY.statLine = "{C:KEYWORD}Chance when hit to reset this ability's cooldown."
LEGENDARY:setToStatsBase({ [Tags.STAT_ABILITY_DAMAGE_BASE] = (ITEM.statsBase:get(Tags.STAT_ABILITY_DAMAGE_BASE) + 20) / 6, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.59) })
local LEGENDARY_TRIGGER = class(TRIGGERS.POST_HIT)
function LEGENDARY_TRIGGER:initialize(entity, direction, abilityStats)
    LEGENDARY_TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self.activationType = Tags.TRIGGER_CHANCE
end

function LEGENDARY_TRIGGER:process(currentEvent)
    local equipment = self.entity.equipment
    equipment:resetCooldown(self.abilityStats:get(Tags.STAT_SLOT))
    return currentEvent
end

LEGENDARY.modifyItem = function(item)
    item.triggers:push(LEGENDARY_TRIGGER)
    item:markAltered(Tags.STAT_ABILITY_DAMAGE_MIN, Tags.STAT_UPGRADED)
    item:markAltered(Tags.STAT_ABILITY_DAMAGE_MAX, Tags.STAT_UPGRADED)
end
return ITEM

