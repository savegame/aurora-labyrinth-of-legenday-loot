local Vector = require("utils.classes.vector")
local Array = require("utils.classes.array")
local COLORS = require("draw.colors")
local TRIGGERS = require("actions.triggers")
local ACTION_CONSTANTS = require("actions.constants")
local BUFFS = require("definitions.buffs")
local TERMS = require("text.terms")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.amulet_def"):new("Shaman's Amulet")
ITEM.className = "Shaman"
ITEM.classSprite = Vector:new(18, 2)
ITEM.icon = Vector:new(16, 18)
ITEM:setToStatsBase({ [Tags.STAT_ABILITY_DAMAGE_BASE] = 16, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = 0, [Tags.STAT_ABILITY_RANGE] = 3, [Tags.STAT_ABILITY_DEBUFF_DURATION] = 1 })
local FORMAT_1 = "Once per turn when you {C:KEYWORD}Stun an enemy, {C:KEYWORD}Stun another random enemy for %s."
local FORMAT_2 = "Deal {C:NUMBER}1-%s bonus damage to enemies that are {C:KEYWORD}Stunned or were {C:KEYWORD}Stunned last turn."
ITEM.getPassiveDescription = function(item)
    return Array:new(textStatFormat(FORMAT_1, item, Tags.STAT_ABILITY_DEBUFF_DURATION), textStatFormat(FORMAT_2, item, Tags.STAT_ABILITY_DAMAGE_MIN))
end
ITEM.decorateOutgoingHit = function(entity, hit, abilityStats)
    for buff in hit.buffs() do
    end

    if hit:isDamagePositiveDirect() then
        local targetEntity = hit.targetEntity
        if targetEntity and targetEntity:hasComponent("buffable") then
            if targetEntity.buffable:isAffectedBy(BUFFS:get("STUN")) or targetEntity.buffable:isAffectedBy(BUFFS:get("POST_STUN")) then
                hit.minDamage = hit.minDamage + 1
                hit.maxDamage = hit.maxDamage + abilityStats:get(Tags.STAT_ABILITY_DAMAGE_MAX)
                hit:increaseBonusState()
            end

        end

    end

end
local STOPPER_BUFF = BUFFS:define("SHAMAN_STOPPER")
function STOPPER_BUFF:initialize(duration)
    STOPPER_BUFF:super(self, "initialize", duration)
    self.expiresAtStart = true
end

local TRIGGER = class(TRIGGERS.ON_HIT)
function TRIGGER:isEnabled()
    if self.entity.buffable:isAffectedBy(STOPPER_BUFF) then
        return false
    end

    if self.hit:isTargetAgent() then
        for buff in self.hit.buffs() do
            if BUFFS:get("STUN"):isInstance(buff) then
                return true
            end

        end

    end

    return false
end

function TRIGGER:process(currentEvent)
    self.entity.agentvisitor:visit(function(agent)
        local position = agent.body:getPosition()
        if self.entity.buffable:isAffectedBy(STOPPER_BUFF) then
            return false
        end

        if self:isVisible(position) and not agent.buffable:isOrWillBeAffectedBy(BUFFS:get("STUN")) then
            self.entity.buffable:forceApply(STOPPER_BUFF:new(1))
            local hit = self.entity.hitter:createHit()
            hit:addBuff(BUFFS:get("STUN"):new(self.abilityStats:get(Tags.STAT_ABILITY_DEBUFF_DURATION)))
            hit:applyToEntity(currentEvent, agent)
            return true
        end

    end, true, false)
    return currentEvent
end

ITEM.triggers:push(TRIGGER)
local LEGENDARY = ITEM:createLegendary("Primordial Core")
LEGENDARY.statLine = TERMS.LEGENDARY_AMULET_DESCRIPTION
LEGENDARY.strokeColor = COLORS.STANDARD_LIGHTNING
return ITEM

