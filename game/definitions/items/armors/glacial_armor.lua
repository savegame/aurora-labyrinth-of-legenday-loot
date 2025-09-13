local Vector = require("utils.classes.vector")
local Common = require("common")
local ActionUtils = require("actions.utils")
local ACTIONS_FRAGMENT = require("actions.fragment")
local TRIGGERS = require("actions.triggers")
local BUFFS = require("definitions.buffs")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Glacial Armor")
local ABILITY = require("structures.ability_def"):new("Glacial Guard")
ABILITY:addTag(Tags.ABILITY_TAG_DEBUFF_COLD)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_ARMOR
ITEM.icon = Vector:new(16, 13)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 42, [Tags.STAT_MAX_MANA] = 18, [Tags.STAT_ABILITY_POWER] = 4.5, [Tags.STAT_ABILITY_BUFF_DURATION] = 3, [Tags.STAT_ABILITY_VALUE] = 4, [Tags.STAT_ABILITY_DEBUFF_DURATION] = 3, [Tags.STAT_ABILITY_QUICK] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1, [Tags.STAT_ABILITY_BUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1, [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1, [Tags.STAT_ABILITY_DEBUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1, [Tags.STAT_ABILITY_BUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1, [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "{C:KEYWORD}Quick {C:KEYWORD}Buff %s - {C:KEYWORD}Resist %s. Whenever you get hit, apply {C:KEYWORD}Cold to the attacker for %s."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_BUFF_DURATION, Tags.STAT_ABILITY_VALUE, Tags.STAT_ABILITY_DEBUFF_DURATION)
end
ABILITY.icon = Vector:new(8, 10)
ABILITY.iconColor = COLORS.STANDARD_ICE
ABILITY.directions = false
ABILITY.indicate = ActionUtils.indicateSelf
local TRIGGER = class(TRIGGERS.POST_HIT)
function TRIGGER:process(currentEvent)
    return currentEvent:chainEvent(function(_, anchor)
        local hit = self.entity.hitter:createHit()
        hit.sound = "ICE_DAMAGE"
        hit.targetEntity = self.hit.sourceEntity
        local duration = self.abilityStats:get(Tags.STAT_ABILITY_DEBUFF_DURATION)
        hit:addBuff(BUFFS:get("COLD"):new(duration))
        hit:applyToEntity(anchor, self.hit.sourceEntity)
    end)
end

local BUFF = class("structures.item_buff")
ABILITY.buffClass = BUFF
function BUFF:initialize(duration, abilityStats)
    BUFF:super(self, "initialize", duration, abilityStats)
    self.triggerClasses:push(TRIGGER)
    self.expiresAtStart = true
    self.outlinePulseColor = ABILITY.iconColor
end

function BUFF:decorateIncomingHit(hit)
    if hit:isDamagePositiveDirect() then
        hit:reduceDamage(self.abilityStats:get(Tags.STAT_ABILITY_VALUE))
        hit:decreaseBonusState()
    end

end

local BLOCK_ICON = Vector:new(14, 11)
local ACTION = class(ACTIONS_FRAGMENT.SHOW_ICON_SELF)
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self.icon = BLOCK_ICON
    self.color = ABILITY.iconColor
end

local LEGENDARY = ITEM:createLegendary("Winterknight Platemail")
LEGENDARY.statLine = "At the end of your turn, {C:KEYWORD}Attack a random adjacent enemy " .. "affected by {C:KEYWORD}Cold."
local LEGENDARY_TRIGGER = class(TRIGGERS.END_OF_TURN)
local function isEntityCold(entityAt, direction, entity)
    if entity.body:getPosition():distanceManhattan(entityAt.body:getPosition()) > 1 then
        return false
    end

    return entityAt.buffable:isAffectedBy(BUFFS:get("COLD"))
end

function LEGENDARY_TRIGGER:isEnabled()
    return toBoolean(ActionUtils.getRandomAttackDirection(false, self.entity, isEntityCold)) and self.entity.player:canAttack()
end

function LEGENDARY_TRIGGER:process(currentEvent)
    local direction = ActionUtils.getRandomAttackDirection(self:getLogicRNG(), self.entity, isEntityCold)
    if direction then
        local attackAction = self.entity.melee:createAction(direction)
        return attackAction:parallelChainEvent(currentEvent)
    else
        return currentEvent
    end

end

LEGENDARY.modifyItem = function(item)
    item.triggers:push(LEGENDARY_TRIGGER)
end
return ITEM

