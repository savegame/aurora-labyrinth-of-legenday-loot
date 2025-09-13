local Vector = require("utils.classes.vector")
local Common = require("common")
local COLORS = require("draw.colors")
local CONSTANTS = require("logic.constants")
local PLAYER_TRIGGERS = require("actions.player_triggers")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Heroic Ring")
ITEM.slot = Tags.SLOT_RING
ITEM.icon = Vector:new(12, 4)
ITEM:setToStatsBase({ [Tags.STAT_ABILITY_COUNT] = 2, [Tags.STAT_ABILITY_DAMAGE_BASE] = 7.5, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.34) })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_DAMAGE_BASE] = 1 })
local FORMAT = "If you are adjacent to %s or more enemies, your " .. "{C:KEYWORD}Attacks deal %s bonus damage."
local FORMAT_LEGENDARY = " {FORCE_NEWLINE} {B:STAT_LINE}"
ITEM.getPassiveDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_COUNT, Tags.STAT_ABILITY_DAMAGE_MIN)
end
ITEM.decorateOutgoingHit = function(entity, hit, abilityStats)
    if hit:isDamagePositive() and hit.damageType == Tags.DAMAGE_TYPE_MELEE then
        local numAgents = DIRECTIONS_AA:countIf(function(direction)
            return entity.body:hasEntityWithAgent(hit.sourcePosition + Vector[direction])
        end)
        if numAgents >= abilityStats:get(Tags.STAT_ABILITY_COUNT) then
            hit.minDamage = hit.minDamage + abilityStats:get(Tags.STAT_ABILITY_DAMAGE_MIN)
            hit.maxDamage = hit.maxDamage + abilityStats:get(Tags.STAT_ABILITY_DAMAGE_MAX)
            hit:increaseBonusState()
        end

    end

end
local LEGENDARY = ITEM:createLegendary("Chosen of the Gods")
local LEGENDARY_EXTRA_LINE = "{C:KEYWORD}Autocast %s - After {C:KEYWORD}Attacking an adjacent " .. "enemy, {C:KEYWORD}Attack another random adjacent enemy."
LEGENDARY.strokeColor = COLORS.STANDARD_HOLY
LEGENDARY:setToStatsBase({ [Tags.STAT_ABILITY_COOLDOWN] = 30 })
LEGENDARY:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
LEGENDARY.passiveExtraLine = function(item)
    return textStatFormat(LEGENDARY_EXTRA_LINE, item, Tags.STAT_ABILITY_COOLDOWN)
end
local LEGENDARY_TRIGGER = class(PLAYER_TRIGGERS.ATTACK_ANOTHER)
function LEGENDARY_TRIGGER:isAttackValid(entityAt, direction)
    return direction ~= self.direction and entityAt.body:getPosition():distanceManhattan(self.entity.body:getPosition()) <= 1
end

function LEGENDARY_TRIGGER:doAttack(currentEvent, direction)
    self.entity.equipment:setOnCooldown(self:getSlot())
    self.entity.equipment:recordCast(self:getSlot())
    return LEGENDARY_TRIGGER:super(self, "doAttack", currentEvent, direction)
end

function LEGENDARY_TRIGGER:isEnabled()
    if not LEGENDARY_TRIGGER:super(self, "isEnabled") then
        return false
    end

    if self.entity.equipment:isReady(self:getSlot()) then
        if self.attackTarget:distanceManhattan(self.entity.body:getPosition()) <= 1 then
            return self.entity.body:hasEntityWithAgent(self.attackTarget)
        end

    end

    return false
end

LEGENDARY.modifyItem = function(item)
    item.triggers:push(LEGENDARY_TRIGGER)
end
return ITEM

