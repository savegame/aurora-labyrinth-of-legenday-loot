local Vector = require("utils.classes.vector")
local CONSTANTS = require("logic.constants")
local BUFFS = require("definitions.buffs")
local ActionUtils = require("actions.utils")
local ACTIONS_FRAGMENT = require("actions.fragment")
local TRIGGERS = require("actions.triggers")
local Common = require("common")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Topaz Armor")
local ABILITY = require("structures.ability_def"):new("Lightning Retribution")
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_ARMOR
ITEM.icon = Vector:new(2, 18)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 40, [Tags.STAT_MAX_MANA] = 20, [Tags.STAT_ABILITY_POWER] = 3.9, [Tags.STAT_ABILITY_BUFF_DURATION] = 1, [Tags.STAT_ABILITY_DEBUFF_DURATION] = 2, [Tags.STAT_ABILITY_DAMAGE_BASE] = 12, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.91) })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_DEBUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "{C:KEYWORD}Buff %s - Whenever you get hit by an enemy, deal %s " .. "damage to that enemy and {C:KEYWORD}Stun it for %s."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_BUFF_DURATION, Tags.STAT_ABILITY_DAMAGE_MIN, Tags.STAT_ABILITY_DEBUFF_DURATION)
end
ABILITY.icon = Vector:new(9, 10)
ABILITY.iconColor = COLORS.STANDARD_LIGHTNING
ABILITY.directions = false
ABILITY.indicate = ActionUtils.indicateSelf
local TRIGGER = class(TRIGGERS.POST_HIT)
function TRIGGER:initialize(entity, direction, abilityStats)
    TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("lightningspawner")
end

function TRIGGER:hitEntity(anchor, targetEntity)
    local hit = self.entity.hitter:createHit()
    hit:setDamageFromAbilityStats(Tags.DAMAGE_TYPE_SPELL, self.abilityStats)
    local duration = self.abilityStats:get(Tags.STAT_ABILITY_DEBUFF_DURATION)
    hit:addBuff(BUFFS:get("STUN"):new(duration))
    hit:applyToEntity(anchor, targetEntity)
end

function TRIGGER:isEnabled()
    if not self.hit.sourceEntity:hasComponent("agent") then
        return false
    end

    return TRIGGER:super(self, "isEnabled")
end

function TRIGGER:process(currentEvent)
    local targetEntity = self.hit.sourceEntity
    local position = targetEntity.body:getPosition()
    Common.playSFX("LIGHTNING")
    currentEvent = self.lightningspawner:spawn(currentEvent, position):chainEvent(function(_, anchor)
        self:hitEntity(anchor, targetEntity)
    end)
    if self.abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 then
        local directions = DIRECTIONS:shuffle(self:getLogicRNG())
        for direction in directions() do
            local target = position + Vector[direction]
            local entityAt = self.entity.body:getEntityAt(target)
            if ActionUtils.isAliveAgent(entityAt) then
                return self.lightningspawner:spawn(currentEvent, target, position):chainEvent(function(_, anchor)
                    self:hitEntity(anchor, entityAt)
                end)
            end

        end

        for direction in directions() do
            local target = position + Vector[direction]
            local entityAt = self.entity.body:getEntityAt(target)
            if entityAt and entityAt:hasComponent("agent") then
                return self.lightningspawner:spawn(currentEvent, target, position):chainEvent(function(_, anchor)
                    self:hitEntity(anchor, entityAt)
                end)
            end

        end

    end

    return currentEvent
end

local BUFF = class("structures.item_buff")
ABILITY.buffClass = BUFF
function BUFF:initialize(duration, abilityStats, action)
    BUFF:super(self, "initialize", duration, abilityStats, action)
    self.triggerClasses:push(TRIGGER)
    self.expiresAtStart = true
    self.outlinePulseColor = ABILITY.iconColor
end

local ACTION = class(ACTIONS_FRAGMENT.SHOW_ICON_SELF)
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self.icon = ITEM.icon
    self.color = ABILITY.iconColor
end

local LEGENDARY = ITEM:createLegendary("Wyrmspark Chestguard")
LEGENDARY:setToStatsBase({ [Tags.STAT_ABILITY_RANGE_MAX] = CONSTANTS.PRESUMED_INFINITE, [Tags.STAT_ABILITY_DAMAGE_BASE] = ITEM.statsBase:get(Tags.STAT_ABILITY_DAMAGE_BASE) / 6, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.91) })
LEGENDARY.modifyItem = function(item)
    item:markAltered(Tags.STAT_ABILITY_DAMAGE_MIN, Tags.STAT_UPGRADED)
    item:markAltered(Tags.STAT_ABILITY_DAMAGE_MAX, Tags.STAT_UPGRADED)
    item:markAltered(Tags.STAT_ABILITY_RANGE_MIN, Tags.STAT_UPGRADED)
    item:markAltered(Tags.STAT_ABILITY_RANGE_MAX, Tags.STAT_UPGRADED)
end
LEGENDARY.abilityExtraLine = "Lightning arcs to a random enemy around the target, doing the same effect."
return ITEM

