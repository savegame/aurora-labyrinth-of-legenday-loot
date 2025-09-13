local Vector = require("utils.classes.vector")
local Array = require("utils.classes.array")
local COLORS = require("draw.colors")
local Common = require("common")
local TERMS = require("text.terms")
local textStatFormat = require("text.stat_format")
local ActionUtils = require("actions.utils")
local PLAYER_TRIGGERS = require("actions.player_triggers")
local ITEM = require("structures.amulet_def"):new("Berserker's Amulet")
ITEM.className = "Berserker"
ITEM.classSprite = Vector:new(12, 1)
ITEM.icon = Vector:new(19, 18)
ITEM:setToStatsBase({ [Tags.STAT_ABILITY_DAMAGE_BASE] = 8, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.88), [Tags.STAT_ABILITY_DENOMINATOR] = 2 })
local FORMAT_1 = "Whenever you get hit by an enemy with full health, " .. "{C:KEYWORD}Attack that enemy."
local FORMAT_2 = "If your current health is below half of your max health, increase damage to " .. "adjacent targets by %s."
ITEM.getPassiveDescription = function(item)
    return Array:new(FORMAT_1, textStatFormat(FORMAT_2, item, Tags.STAT_ABILITY_DAMAGE_MIN))
end
ITEM.decorateOutgoingHit = function(entity, hit, abilityStats)
    local denominator = abilityStats:get(Tags.STAT_ABILITY_DENOMINATOR)
    if entity.tank:getRatio() < 1 / denominator and hit:isDamageOrDebuff() then
        if hit:getApplyDistance() <= 1 then
            hit.minDamage = hit.minDamage + abilityStats:get(Tags.STAT_ABILITY_DAMAGE_MIN)
            hit.maxDamage = hit.maxDamage + abilityStats:get(Tags.STAT_ABILITY_DAMAGE_MAX)
            hit:increaseBonusState()
        end

    end

end
local TRIGGER = class(PLAYER_TRIGGERS.COUNTER_ATTACK)
function TRIGGER:initialize(entity, direction, abilityStats)
    TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self.sortOrder = 4
end

function TRIGGER:isEnabled()
    if not self.hit:isDamageOrDebuff() then
        return false
    end

    local source = self.hit.sourceEntity
    if not ActionUtils.isAliveAgent(source) then
        return false
    end

    if source.tank:getRatio() < 1 then
        return false
    end

    if self.hit.knockback and self.hit.knockback.isPull then
        return false
    end

    return TRIGGER:super(self, "isEnabled")
end

function TRIGGER:process(currentEvent)
    local source = self.hit.sourceEntity
    if not ActionUtils.isAliveAgent(source) then
        return currentEvent
    end

    if source.tank:getRatio() < 1 then
        return currentEvent
    end

    return TRIGGER:super(self, "process", currentEvent)
end

ITEM.triggers:push(TRIGGER)
local LEGENDARY = ITEM:createLegendary("Incarnation of Hatred")
LEGENDARY.statLine = TERMS.LEGENDARY_AMULET_DESCRIPTION
LEGENDARY.strokeColor = COLORS.STANDARD_RAGE
return ITEM

