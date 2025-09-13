local Vector = require("utils.classes.vector")
local ActionUtils = require("actions.utils")
local ACTIONS_FRAGMENT = require("actions.fragment")
local TRIGGERS = require("actions.triggers")
local PLAYER_COMMON = require("actions.player_common")
local COLORS = require("draw.colors")
local Common = require("common")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Sacred Armor")
local ABILITY = require("structures.ability_def"):new("Shield of Light")
ABILITY:addTag(Tags.ABILITY_TAG_RESTORES_HEALTH)
ABILITY:addTag(Tags.ABILITY_TAG_NEGATES_DAMAGE)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_ARMOR
ITEM.icon = Vector:new(18, 13)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 50, [Tags.STAT_MAX_MANA] = 10, [Tags.STAT_ABILITY_POWER] = 3, [Tags.STAT_ABILITY_BUFF_DURATION] = 1, [Tags.STAT_ABILITY_DENOMINATOR] = 4, [Tags.STAT_ABILITY_VALUE] = 5, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = 0 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_DENOMINATOR] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_DENOMINATOR] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "{C:KEYWORD}Buff %s - Instead of taking damage, restore health equal to %s " .. "of the damage plus %s."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_BUFF_DURATION, Tags.STAT_ABILITY_DENOMINATOR, Tags.STAT_ABILITY_VALUE)
end
ABILITY.icon = Vector:new(2, 2)
ABILITY.iconColor = COLORS.STANDARD_HOLY
ABILITY.directions = false
ABILITY.indicate = ActionUtils.indicateSelf
local BLOCK_ICON = Vector:new(3, 15)
local ACTION = class(ACTIONS_FRAGMENT.SHOW_ICON_SELF)
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self.icon = BLOCK_ICON
    self.color = ABILITY.iconColor
end

local ABSORB_DAMAGE = class(TRIGGERS.PRE_HIT)
function ABSORB_DAMAGE:initialize(entity, direction, abilityStats)
    ABSORB_DAMAGE:super(self, "initialize", entity, direction, abilityStats)
    self.sortOrder = -5
    self.minHeal = 0
    self.maxHeal = 0
end

function ABSORB_DAMAGE:isEnabled()
    return self.hit:isDamagePositiveDirect()
end

function ABSORB_DAMAGE:parallelResolve(anchor)
    local denominator = self.abilityStats:get(Tags.STAT_ABILITY_DENOMINATOR)
    self.minHeal = self.hit.minDamage / denominator + self.abilityStats:get(Tags.STAT_ABILITY_VALUE)
    self.maxHeal = self.hit.maxDamage / denominator + self.abilityStats:get(Tags.STAT_ABILITY_VALUE)
    self.hit:multiplyDamage(0)
    self.hit.sound = false
end

function ABSORB_DAMAGE:process(currentEvent)
    local action = self.entity.actor:create(ACTION, self.direction, self.abilityStats)
    action:setToFast()
    local healHit = self.entity.hitter:createHit()
    healHit:setHealing(self.minHeal, self.maxHeal, self.abilityStats)
    healHit:applyToEntity(currentEvent, self.entity)
    return action:parallelChainEvent(currentEvent)
end

local BUFF = class("structures.item_buff")
ABILITY.buffClass = BUFF
function BUFF:initialize(duration, abilityStats, action)
    BUFF:super(self, "initialize", duration, abilityStats, action)
    self.triggerClasses:push(ABSORB_DAMAGE)
    self.outlinePulseColor = ABILITY.iconColor
    self.expiresAtStart = true
end

local LEGENDARY = ITEM:createLegendary("Seraphic Aegis")
local LEGENDARY_STAT_LINE = "{C:KEYWORD}Chance when damaged to instead restore health equal to half of the damage."
LEGENDARY:setToStatsBase({ [Tags.STAT_MODIFIER_VALUE] = 1 })
LEGENDARY.statLine = function(item)
    return textStatFormat(LEGENDARY_STAT_LINE, item, Tags.STAT_MODIFIER_VALUE)
end
local LEGENDARY_TRIGGER = class(ABSORB_DAMAGE)
function LEGENDARY_TRIGGER:initialize(entity, direction, abilityStats)
    LEGENDARY_TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self.abilityStats:set(Tags.STAT_ABILITY_DENOMINATOR, 2)
    self.abilityStats:set(Tags.STAT_ABILITY_VALUE, 0)
    self.activationType = Tags.TRIGGER_CHANCE
end

function LEGENDARY_TRIGGER:isEnabled()
    if not LEGENDARY_TRIGGER:super(self, "isEnabled") then
        return false
    end

    return not self.entity.equipment:isSlotActive(self:getSlot())
end

LEGENDARY.modifyItem = function(item)
    item.triggers:push(LEGENDARY_TRIGGER)
end
return ITEM

