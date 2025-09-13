local Vector = require("utils.classes.vector")
local CONSTANTS = require("logic.constants")
local BUFFS = require("definitions.buffs")
local ActionUtils = require("actions.utils")
local ACTIONS_FRAGMENT = require("actions.fragment")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Warlord Helm")
local ABILITY = require("structures.ability_def"):new("Might")
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_HELM
ITEM.icon = Vector:new(9, 13)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 40, [Tags.STAT_ABILITY_POWER] = 4.0, [Tags.STAT_ABILITY_BUFF_DURATION] = 3, [Tags.STAT_ABILITY_DAMAGE_BASE] = 10, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = 0, [Tags.STAT_ABILITY_QUICK] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_BUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_BUFF_DURATION] = 1 })
local FORMAT = "{C:KEYWORD}Quick {C:KEYWORD}Buff %s - Your {C:KEYWORD}Attacks " .. "deal max damage plus %s."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_BUFF_DURATION, Tags.STAT_ABILITY_DAMAGE_MIN)
end
ABILITY.icon = Vector:new(2, 9)
ABILITY.iconColor = COLORS.STANDARD_RAGE
ABILITY.directions = false
ABILITY.indicate = ActionUtils.indicateSelf
local BUFF = class(BUFFS.DEACTIVATOR)
ABILITY.buffClass = BUFF
function BUFF:initialize(duration, abilityStats)
    BUFF:super(self, "initialize", duration, abilityStats)
    self.bonusDamage = 0
end

function BUFF:toData()
    return { bonusDamage = self.bonusDamage }
end

function BUFF:fromData(data)
    self.bonusDamage = data.bonusDamage
end

function BUFF:decorateOutgoingHit(hit)
    if hit.damageType == Tags.DAMAGE_TYPE_MELEE and hit:isDamagePositive() then
        hit.maxDamage = hit.maxDamage + self.abilityStats:get(Tags.STAT_ABILITY_DAMAGE_MAX)
        hit.maxDamage = hit.maxDamage + self.bonusDamage
        hit.minDamage = hit.maxDamage
        hit:increaseBonusState()
    end

end

function BUFF:decorateIncomingHit(hit)
    if self.abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 and hit:isDamageOrDebuff() then
        self.bonusDamage = self.bonusDamage + self.abilityStats:get(Tags.STAT_MODIFIER_DAMAGE_MIN)
    end

end

local ACTION = class(ACTIONS_FRAGMENT.ENCHANT)
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self.color = COLORS.ELITE_VICIOUS
end

function ACTION:process(currentEvent)
    return ACTION:super(self, "process", currentEvent):chainEvent(function()
        self.entity.sprite.strokeColor:push(COLORS.ELITE_VICIOUS)
    end)
end

function ACTION:setFromLoad()
    self.entity.sprite.strokeColor:push(COLORS.ELITE_VICIOUS)
end

function ACTION:deactivate()
    self.entity.sprite.strokeColor:delete(COLORS.ELITE_VICIOUS)
end

local LEGENDARY = ITEM:createLegendary("Strength of the Ancients")
local LEGENDARY_EXTRA_LINE = "Whenever you get hit, increase the " .. "bonus by %s until the end of the {C:KEYWORD}Buff."
LEGENDARY:setToStatsBase({ [Tags.STAT_MODIFIER_DAMAGE_BASE] = 6, [Tags.STAT_MODIFIER_DAMAGE_VARIANCE] = 0, [Tags.STAT_ABILITY_BUFF_DURATION] = 1 })
LEGENDARY.abilityExtraLine = function(item)
    return textStatFormat(LEGENDARY_EXTRA_LINE, item, Tags.STAT_MODIFIER_DAMAGE_MIN)
end
LEGENDARY.modifyItem = function(item)
    item:markAltered(Tags.STAT_ABILITY_BUFF_DURATION, Tags.STAT_UPGRADED)
end
return ITEM

