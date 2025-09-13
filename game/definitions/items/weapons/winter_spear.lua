local Vector = require("utils.classes.vector")
local Common = require("common")
local ActionUtils = require("actions.utils")
local ATTACK_WEAPON = require("actions.attack_weapon")
local ACTIONS_FRAGMENT = require("actions.fragment")
local PLAYER_COMMON = require("actions.player_common")
local BUFFS = require("definitions.buffs")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Winter Spear")
local ABILITY = require("structures.ability_def"):new("Enchant Ice")
ABILITY:addTag(Tags.ABILITY_TAG_DEBUFF_COLD)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_WEAPON
ITEM.icon = Vector:new(12, 19)
ITEM.attackClass = ATTACK_WEAPON.STAB_AND_DAMAGE
ITEM:setToStatsBase({ [Tags.STAT_ATTACK_DAMAGE_BASE] = 16.0, [Tags.STAT_ATTACK_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.85), [Tags.STAT_REACH] = 1, [Tags.STAT_VIRTUAL_RATIO] = 0.42, [Tags.STAT_ABILITY_POWER] = 4, [Tags.STAT_ABILITY_QUICK] = 1, [Tags.STAT_ABILITY_BUFF_DURATION] = 3, [Tags.STAT_ABILITY_DEBUFF_DURATION] = 2 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_BUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "{C:KEYWORD}Quick {C:KEYWORD}Buff %s - Your {C:KEYWORD}Attacks " .. "apply {C:KEYWORD}Cold for %s."
ABILITY.getDescription = function(item)
    local description = textStatFormat(FORMAT, item, Tags.STAT_ABILITY_BUFF_DURATION, Tags.STAT_ABILITY_DEBUFF_DURATION)
    return description
end
ABILITY.icon = Vector:new(3, 11)
ABILITY.iconColor = COLORS.STANDARD_ICE
ABILITY.directions = false
ABILITY.indicate = ActionUtils.indicateSelf
local BUFF = class("structures.item_buff")
ABILITY.buffClass = BUFF
function BUFF:initialize(duration, abilityStats, action)
    BUFF:super(self, "initialize", duration, abilityStats, action)
    self.outlinePulseColor = ABILITY.iconColor
end

function BUFF:decorateOutgoingHit(hit)
    if hit.damageType == Tags.DAMAGE_TYPE_MELEE then
        local duration = self.abilityStats:get(Tags.STAT_ABILITY_DEBUFF_DURATION)
        hit:addBuff(BUFFS:get("COLD"):new(duration))
        if self.abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 then
            if hit:getApplyDistance() == 2 then
                hit.minDamage = hit.minDamage + self.abilityStats:get(Tags.STAT_MODIFIER_DAMAGE_MIN)
                hit.maxDamage = hit.maxDamage + self.abilityStats:get(Tags.STAT_MODIFIER_DAMAGE_MAX)
                hit:increaseBonusState()
            end

        end

    end

end

local ACTION = class(ACTIONS_FRAGMENT.ENCHANT)
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self.color = ABILITY.iconColor
end

local LEGENDARY = ITEM:createLegendary("Frostmaiden's Lance")
local LEGENDARY_EXTRA_LINE = "Additionally, your {C:KEYWORD}Reach " .. "{C:KEYWORD}Attacks deal %s bonus damage."
LEGENDARY:setToStatsBase({ [Tags.STAT_MODIFIER_DAMAGE_BASE] = 7.5, [Tags.STAT_MODIFIER_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.7) })
LEGENDARY.abilityExtraLine = function(item)
    return textStatFormat(LEGENDARY_EXTRA_LINE, item, Tags.STAT_MODIFIER_DAMAGE_MIN)
end
LEGENDARY.modifyItem = function(item)
end
return ITEM

