local Vector = require("utils.classes.vector")
local Common = require("common")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local ActionUtils = require("actions.utils")
local TRIGGERS = require("actions.triggers")
local ITEM = require("structures.item_def"):new("Flux Ring")
ITEM.slot = Tags.SLOT_RING
ITEM.icon = Vector:new(21, 20)
ITEM:setToStatsBase({ [Tags.STAT_ABILITY_DAMAGE_BASE] = 7.6, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.56), [Tags.STAT_ABILITY_AREA_ROUND] = Tags.ABILITY_AREA_CROSS })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_DAMAGE_BASE] = 1 })
local FORMAT = "Whenever you cast an ability directly, deal %s "
local FORMAT_LEGENDARY = "{B:STAT_LINE}plus the ability's base cooldown {B:NORMAL}as "
local FORMAT_END = "damage to a random adjacent enemy."
ITEM.getPassiveDescription = function(item)
    local description = textStatFormat(FORMAT, item, Tags.STAT_ABILITY_DAMAGE_MIN)
    if item.stats:get(Tags.STAT_LEGENDARY, 0) > 0 then
        description = description .. FORMAT_LEGENDARY
    end

    return description .. FORMAT_END
end
local TRIGGER = class(TRIGGERS.POST_CAST)
function TRIGGER:initialize(entity, direction, abilityStats)
    TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("lightningspawner")
    self.lightningspawner.lightningCount = 2
    self.lightningspawner.color = COLORS.STANDARD_PSYCHIC
end

function TRIGGER:process(currentEvent)
    local body = self.entity.body
    local source = body:getPosition()
    for direction in (DIRECTIONS_AA:shuffle(self:getLogicRNG()))() do
        local target = source + Vector[direction]
        local entityAt = body:getEntityAt(target)
        if ActionUtils.isAliveAgent(entityAt) then
            Common.playSFX("LIGHTNING", 1.5, 0.5)
            return self.lightningspawner:spawn(currentEvent, target, source):chainEvent(function(_, anchor)
                local hit = self.entity.hitter:createHit()
                hit:setDamageFromAbilityStats(Tags.DAMAGE_TYPE_SPELL, self.abilityStats)
                if self.abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 then
                    local bonusDamage = self.entity.equipment:getBaseSlotStat(self.triggeringSlot, Tags.STAT_ABILITY_COOLDOWN)
                    hit.minDamage = hit.minDamage + bonusDamage
                    hit.maxDamage = hit.maxDamage + bonusDamage
                end

                hit:applyToEntity(anchor, entityAt, target)
            end)
        end

    end

    return currentEvent
end

ITEM.triggers:push(TRIGGER)
local LEGENDARY = ITEM:createLegendary("Elysium Jewel")
LEGENDARY.strokeColor = COLORS.STANDARD_PSYCHIC
return ITEM

