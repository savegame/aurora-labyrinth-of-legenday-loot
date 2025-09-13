local Vector = require("utils.classes.vector")
local Color = require("utils.classes.color")
local Common = require("common")
local CONSTANTS = require("logic.constants")
local BUFFS = require("definitions.buffs")
local PLAYER_COMMON = require("actions.player_common")
local ActionUtils = require("actions.utils")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Frigid Hat")
local ABILITY = require("structures.ability_def"):new("Freeze Ray")
ABILITY:addTag(Tags.ABILITY_TAG_DEBUFF_COLD)
ABILITY:addTag(Tags.ABILITY_TAG_BOOSTABLE_ABILITY_DAMAGE)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_HELM
ITEM.icon = Vector:new(3, 13)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 8, [Tags.STAT_MAX_MANA] = 32, [Tags.STAT_ABILITY_POWER] = 5.8, [Tags.STAT_ABILITY_DAMAGE_BASE] = 39.2, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.04), [Tags.STAT_ABILITY_DEBUFF_DURATION] = 2, [Tags.STAT_ABILITY_VALUE] = 2 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_DEBUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "Deal %s damage to all targets in a line in front of you. Apply {C:KEYWORD}Cold " .. "for %s plus %s turns per previous enemy hit."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_DAMAGE_MIN, Tags.STAT_ABILITY_DEBUFF_DURATION, Tags.STAT_ABILITY_VALUE)
end
ABILITY.icon = Vector:new(8, 11)
ABILITY.iconColor = COLORS.STANDARD_ICE
ABILITY.getInvalidReason = ActionUtils.getInvalidReasonFrontCantBePassable
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    local target = entity.body:getPosition() + Vector[direction]
    while entity.body:canBePassable(target) do
        castingGuide:indicate(target)
        target = target + Vector[direction]
    end

end
local BEAM_COLOR = Color:new(0.25, 0.75, 1)
local ACTION = class(PLAYER_COMMON.BEAM)
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self.color = ABILITY.iconColor
    self.beamColor = BEAM_COLOR
    self.currentDuration = 0
end

function ACTION:hitTarget(anchor, target)
    local hit = self.entity.hitter:createHit()
    hit:setDamageFromAbilityStats(Tags.DAMAGE_TYPE_SPELL, self.abilityStats)
    hit:addBuff(BUFFS:get("COLD"):new(self.currentDuration))
    if self.entity.body:hasEntityWithAgent(target) then
        self.currentDuration = self.currentDuration + self.abilityStats:get(Tags.STAT_ABILITY_VALUE)
    end

    hit:applyToPosition(anchor, target)
    self.entity.entityspawner:spawn("temporary_vision", target)
end

function ACTION:parallelResolve(currentEvent)
    ACTION:super(self, "parallelResolve", currentEvent)
    self.currentDuration = self.abilityStats:get(Tags.STAT_ABILITY_DEBUFF_DURATION)
end

local LEGENDARY = ITEM:createLegendary("Absolute Zero")
local LEGENDARY_STAT_LINE = "Deal %s bonus damage to {C:KEYWORD}Cold enemies."
LEGENDARY:setToStatsBase({ [Tags.STAT_MODIFIER_DAMAGE_BASE] = 10.7, [Tags.STAT_MODIFIER_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.1) })
LEGENDARY.statLine = function(item)
    return textStatFormat(LEGENDARY_STAT_LINE, item, Tags.STAT_MODIFIER_DAMAGE_MIN)
end
LEGENDARY.decorateOutgoingHit = function(entity, hit, abilityStats)
    if hit:isDamagePositiveDirect() then
        if hit.targetEntity and hit.targetEntity:hasComponent("buffable") then
            if hit.targetEntity.buffable:isAffectedBy(BUFFS:get("COLD")) then
                hit.minDamage = hit.minDamage + abilityStats:get(Tags.STAT_MODIFIER_DAMAGE_MIN)
                hit.maxDamage = hit.maxDamage + abilityStats:get(Tags.STAT_MODIFIER_DAMAGE_MAX)
                hit:increaseBonusState()
            end

        end

    end

end
return ITEM

