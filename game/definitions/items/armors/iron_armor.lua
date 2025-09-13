local Vector = require("utils.classes.vector")
local Common = require("common")
local CONSTANTS = require("logic.constants")
local BUFFS = require("definitions.buffs")
local ActionUtils = require("actions.utils")
local ACTIONS_FRAGMENT = require("actions.fragment")
local ACTION_CONSTANTS = require("actions.constants")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Iron Armor")
local ABILITY = require("structures.ability_def"):new("Ironskin")
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_ARMOR
ITEM.icon = Vector:new(6, 15)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 60, [Tags.STAT_ABILITY_POWER] = 4.75, [Tags.STAT_ABILITY_BUFF_DURATION] = 3, [Tags.STAT_ABILITY_QUICK] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_BUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_BUFF_DURATION] = 1 })
local FORMAT = "{C:KEYWORD}Quick {C:KEYWORD}Buff %s - Reduce damage taken by half."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_BUFF_DURATION)
end
ABILITY.icon = Vector:new(4, 6)
ABILITY.iconColor = COLORS.STANDARD_STEEL
ABILITY.directions = false
ABILITY.indicate = ActionUtils.indicateSelf
local BUFF = class(BUFFS.DEACTIVATOR)
ABILITY.buffClass = BUFF
function BUFF:initialize(duration, abilityStats, action)
    BUFF:super(self, "initialize", duration, abilityStats, action)
    self.expiresAtStart = true
end

function BUFF:decorateIncomingHit(hit)
    if hit:isDamagePositiveDirect() then
        hit:multiplyDamage(0.5)
        hit:decreaseBonusState()
    end

end

local ACTION = class("actions.action")
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("outline")
    self.outline.color = COLORS.ELITE_TOUGH
end

function ACTION:process(currentEvent)
    Common.playSFX("GLOW_MODAL")
    return self.outline:chainFullEvent(currentEvent, ACTION_CONSTANTS.MAJOR_CAST_CHARGE_DURATION):chainEvent(function()
        self.entity.sprite.strokeColor:push(COLORS.ELITE_TOUGH)
    end)
end

function ACTION:setFromLoad()
    self.entity.sprite.strokeColor:push(COLORS.ELITE_TOUGH)
end

function ACTION:deactivate()
    self.entity.sprite.strokeColor:delete(COLORS.ELITE_TOUGH)
end

local LEGENDARY = ITEM:createLegendary("The Indestructible")
LEGENDARY:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 40 })
LEGENDARY.modifyItem = function(item)
    item:markAltered(Tags.STAT_MAX_HEALTH, Tags.STAT_UPGRADED)
end
return ITEM

