local Vector = require("utils.classes.vector")
local Common = require("common")
local ACTION_CONSTANTS = require("actions.constants")
local ACTIONS_FRAGMENT = require("actions.fragment")
local TRIGGERS = require("actions.triggers")
local ActionUtils = require("actions.utils")
local BUFFS = require("definitions.buffs")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Static Cloak")
local ABILITY = require("structures.ability_def"):new("Interference")
ABILITY:addTag(Tags.ABILITY_TAG_SURROUNDING_DISABLE)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_ARMOR
ITEM.icon = Vector:new(12, 12)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 14, [Tags.STAT_MAX_MANA] = 46, [Tags.STAT_ABILITY_POWER] = 2.5, [Tags.STAT_ABILITY_DEBUFF_DURATION] = 2, [Tags.STAT_ABILITY_BUFF_DURATION] = 3 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_BUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_BUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_BUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "All {C:KEYWORD}Focusing enemies are {C:KEYWORD}Stunned for %s. " .. "{FORCE_NEWLINE} {C:KEYWORD}Buff %s - Enemies cannot cast abilities. "
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_DEBUFF_DURATION, Tags.STAT_ABILITY_BUFF_DURATION)
end
ABILITY.icon = Vector:new(12, 4)
ABILITY.iconColor = COLORS.STANDARD_LIGHTNING
ABILITY.directions = false
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    castingGuide:indicate(entity.body:getPosition())
    entity.agentvisitor:visit(function(agent)
        local position = agent.body:getPosition()
        if entity.vision:isVisible(position) then
            castingGuide:indicate(position)
        end

    end)
end
local SCREEN_FLASH_OPACITY = 0.6
local SCREEN_FLASH_DURATION = 0.4
ABILITY.buffClass = class(BUFFS.DEACTIVATOR)
local ACTION = class(ACTIONS_FRAGMENT.CAST)
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self.color = ABILITY.iconColor
    self:speedMultiply(ACTION_CONSTANTS.SLOW_CAST_MULTIPLIER)
end

function ACTION:process(currentEvent)
    return ACTION:super(self, "process", currentEvent):chainEvent(function(_, anchor)
        local effects = self:getEffects()
        effects:flashScreen(SCREEN_FLASH_DURATION, ABILITY.iconColor, SCREEN_FLASH_OPACITY)
        local duration = self.abilityStats:get(Tags.STAT_ABILITY_DEBUFF_DURATION)
        Common.playSFX("AFFLICT")
        self.entity.agentvisitor:visit(function(agent)
            if agent:hasComponent("caster") and agent.caster.preparedAction then
                if agent.tank.hasDiedOnce then
                    agent.caster:cancelPreparedAction(false)
                    agent.tank:kill(anchor)
                else
                    local hit = self.entity.hitter:createHit()
                    hit:addBuff(BUFFS:get("STUN"):new(duration))
                    hit:applyToEntity(anchor, agent)
                end

            end

        end, false, false)
        self.entity.agentvisitor:getSystemAgent().castingPrevented = true
    end)
end

function ACTION:setFromLoad()
    self.entity.agentvisitor:getSystemAgent().castingPrevented = true
end

function ACTION:deactivate(anchor)
    self.entity.agentvisitor:getSystemAgent().castingPrevented = false
end

local LEGENDARY = ITEM:createLegendary("Spellbreaker's Enigma")
local LEGENDARY_STAT_LINE = "Whenever an enemy {C:KEYWORD}Focuses, " .. "deal %s damage to it."
LEGENDARY:setToStatsBase({ [Tags.STAT_MODIFIER_DAMAGE_BASE] = 11.5, [Tags.STAT_MODIFIER_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.9) })
LEGENDARY.statLine = function(item)
    return textStatFormat(LEGENDARY_STAT_LINE, item, Tags.STAT_MODIFIER_DAMAGE_MIN)
end
local LEGENDARY_TRIGGER = class(TRIGGERS.ON_ENEMY_FOCUS)
local LEGENDARY_FLASH_DURATION = 0.4
function LEGENDARY_TRIGGER:process(currentEvent)
    local targetEntity = self.focusingEnemy
    local hit = self.entity.hitter:createHit()
    hit.forceNoFlash = true
    hit:setDamageFromModifierStats(Tags.DAMAGE_TYPE_SPELL, self.abilityStats)
    hit:applyToEntity(currentEvent, targetEntity)
    targetEntity.charactereffects:flash(LEGENDARY_FLASH_DURATION, ABILITY.iconColor)
    return currentEvent
end

LEGENDARY.modifyItem = function(item)
    item.triggers:push(LEGENDARY_TRIGGER)
end
return ITEM

