local Array = require("utils.classes.array")
local Vector = require("utils.classes.vector")
local Common = require("common")
local CONSTANTS = require("logic.constants")
local ACTIONS_FRAGMENT = require("actions.fragment")
local PLAYER_TRIGGERS = require("actions.player_triggers")
local ActionUtils = require("actions.utils")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Zephyr Cloak")
local ABILITY = require("structures.ability_def"):new("A Leaf in the Wind")
ABILITY:addTag(Tags.ABILITY_TAG_DISENGAGE_MELEE)
ABILITY:addTag(Tags.ABILITY_TAG_NEGATES_DAMAGE)
ABILITY:addTag(Tags.ABILITY_TAG_IMMOBILIZED_DISABLED)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_ARMOR
ITEM.icon = Vector:new(13, 12)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 20, [Tags.STAT_MAX_MANA] = 40, [Tags.STAT_ABILITY_POWER] = 3.5, [Tags.STAT_ABILITY_BUFF_DURATION] = 3, [Tags.STAT_ABILITY_QUICK] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_BUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "{C:KEYWORD}Quick {C:KEYWORD}Buff %s - Before you get hit with a " .. "{C:KEYWORD}Melee {C:KEYWORD}Attack, move {C:NUMBER}1 step to a random direction."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_BUFF_DURATION)
end
ABILITY.icon = Vector:new(5, 7)
ABILITY.iconColor = COLORS.STANDARD_WIND
ABILITY.directions = false
ABILITY.indicate = ActionUtils.indicateSelf
local ACTION = class(ACTIONS_FRAGMENT.SHOW_ICON_SELF)
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self.icon = ITEM.icon
    self.color = ABILITY.iconColor
end

local BUFF = class("structures.item_buff")
ABILITY.buffClass = BUFF
function BUFF:initialize(duration, abilityStats, action)
    BUFF:super(self, "initialize", duration, abilityStats, action)
    self.triggerClasses:push(PLAYER_TRIGGERS.EVASIVE_STEP)
    self.outlinePulseColor = ABILITY.iconColor
    self.expiresAtStart = true
end

local LEGENDARY = ITEM:createLegendary("Cloak of Serenity")
local LEGENDARY_STAT_LINE = "{C:KEYWORD}Resist %s against non-{C:KEYWORD}Melee {C:KEYWORD}Attacks."
LEGENDARY:setToStatsBase({ [Tags.STAT_MODIFIER_VALUE] = 4 })
LEGENDARY:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
LEGENDARY.statLine = function(item)
    return textStatFormat(LEGENDARY_STAT_LINE, item, Tags.STAT_MODIFIER_VALUE)
end
LEGENDARY.modifyItem = function(item)
end
LEGENDARY.decorateIncomingHit = function(entity, hit, abilityStats)
    if hit:isDamagePositiveDirect() then
        if not hit:isDamageAnyMelee() then
            local reduction = abilityStats:get(Tags.STAT_MODIFIER_VALUE)
            hit:reduceDamage(abilityStats:get(Tags.STAT_MODIFIER_VALUE))
            hit:decreaseBonusState()
        end

    end

end
return ITEM

