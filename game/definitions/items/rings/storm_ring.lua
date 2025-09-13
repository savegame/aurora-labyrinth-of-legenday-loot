local Vector = require("utils.classes.vector")
local textStatFormat = require("text.stat_format")
local Common = require("common")
local BUFFS = require("definitions.buffs")
local COLORS = require("draw.colors")
local ACTION_CONSTANTS = require("actions.constants")
local TRIGGERS = require("actions.triggers")
local ITEM = require("structures.item_def"):new("Storm Ring")
ITEM.slot = Tags.SLOT_RING
ITEM.icon = Vector:new(16, 15)
ITEM:setToStatsBase({ [Tags.STAT_ABILITY_DAMAGE_BASE] = 10, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.99), [Tags.STAT_ABILITY_RANGE] = 3, [Tags.STAT_ABILITY_DEBUFF_DURATION] = 1, [Tags.STAT_ABILITY_COOLDOWN] = 16 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "At the start of your turn, deal %s damage to a random enemy at least " .. "%s away, and {C:KEYWORD}Stun it for %s."
ITEM.getPassiveDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_DAMAGE_MIN, Tags.STAT_ABILITY_RANGE, Tags.STAT_ABILITY_DEBUFF_DURATION)
end
local TRIGGER = class(TRIGGERS.START_OF_TURN)
function TRIGGER:initialize(entity, direction, abilityStats)
    TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("lightningspawner")
end

function TRIGGER:isEnabled()
    return self.entity.equipment:isReady(self:getSlot())
end

function TRIGGER:process(currentEvent)
    local slot = self.abilityStats:get(Tags.STAT_SLOT)
    local range = self.abilityStats:get(Tags.STAT_ABILITY_RANGE)
    local primaryFulfilled = false
    local secondaryFulfilled = true
    local secondaryRange = self.abilityStats:get(Tags.STAT_SECONDARY_RANGE, 0)
    if secondaryRange > 0 then
        secondaryFulfilled = false
    end

    self.entity.agentvisitor:visit(function(agent)
        local position = agent.body:getPosition()
        local distance = position:distanceManhattan(self.entity.body:getPosition())
        if self:isVisible(position) and distance >= range then
            currentEvent:chainEvent(function()
                Common.playSFX("LIGHTNING")
            end)
            currentEvent = self.lightningspawner:spawn(currentEvent, position):chainEvent(function(_, anchor)
                local hit = self.entity.hitter:createHit()
                hit:setDamageFromAbilityStats(Tags.DAMAGE_TYPE_SPELL, self.abilityStats)
                local duration = self.abilityStats:get(Tags.STAT_ABILITY_DEBUFF_DURATION)
                hit:addBuff(BUFFS:get("STUN"):new(duration))
                hit:applyToEntity(anchor, agent)
                self.entity.equipment:setOnCooldown(self:getSlot())
                self.entity.equipment:recordCast(self:getSlot())
            end)
                        if secondaryFulfilled then
                primaryFulfilled = true
            elseif distance >= secondaryRange then
                secondaryFulfilled = true
            else
                primaryFulfilled = true
                range = secondaryRange
            end

            return primaryFulfilled and secondaryFulfilled
        else
            return false
        end

    end, true, true)
    return currentEvent
end

ITEM.triggers:push(TRIGGER)
local LEGENDARY = ITEM:createLegendary("Fury of the Heavens")
LEGENDARY.strokeColor = COLORS.STANDARD_LIGHTNING
local LEGENDARY_EXTRA_LINE = "Strike another random target at least %s away."
LEGENDARY:setToStatsBase({ [Tags.STAT_SECONDARY_RANGE] = 5 })
LEGENDARY.passiveExtraLine = function(item)
    return textStatFormat(LEGENDARY_EXTRA_LINE, item, Tags.STAT_SECONDARY_RANGE)
end
return ITEM

