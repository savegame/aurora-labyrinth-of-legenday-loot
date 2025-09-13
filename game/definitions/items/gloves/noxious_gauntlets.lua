local Vector = require("utils.classes.vector")
local Common = require("common")
local BUFFS = require("definitions.buffs")
local ActionUtils = require("actions.utils")
local ACTIONS_FRAGMENT = require("actions.fragment")
local TRIGGERS = require("actions.triggers")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Noxious Gauntlets")
local ABILITY = require("structures.ability_def"):new("Noxious Strike")
ABILITY:addTag(Tags.ABILITY_TAG_PLUS_BASIC_ATTACK)
ABILITY:addTag(Tags.ABILITY_TAG_DIRECTIONAL_RECASTABLE)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_GLOVES
ITEM.icon = Vector:new(15, 16)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 30, [Tags.STAT_MAX_MANA] = 10, [Tags.STAT_ABILITY_POWER] = 1.96, [Tags.STAT_ABILITY_DEBUFF_DURATION] = 4, [Tags.STAT_POISON_DAMAGE_BASE] = 4.8 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_DEBUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_DEBUFF_DURATION] = 1 })
local FORMAT = "{C:KEYWORD}Attack an enemy and " .. "{C:KEYWORD}Poison it, making it lose %s health over %s."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_POISON_DAMAGE_TOTAL, Tags.STAT_ABILITY_DEBUFF_DURATION)
end
ABILITY.icon = Vector:new(1, 6)
ABILITY.iconColor = COLORS.STANDARD_POISON
ABILITY.getInvalidReason = ActionUtils.getInvalidReasonEnemyAttack
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    local target = ActionUtils.indicateExtendableAttack(entity, direction, abilityStats, castingGuide)
    if ABILITY.getInvalidReason(entity, direction, abilityStats) then
        castingGuide:indicateWeak(target)
    end

end
local ACTION = class("actions.action")
ABILITY.actionClass = ACTION
local GLOW_DURATION = 0.25
local SPEED_MULTIPLIER = 0.4
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("outline")
    self.outline.color = ABILITY.iconColor
end

function ACTION:process(currentEvent)
    self.entity.sprite:turnToDirection(self.direction)
    Common.playSFX("CAST_CHARGE")
    self.outline:chainFadeIn(currentEvent, GLOW_DURATION)
    self.entity.player:multiplyAttackSpeed(SPEED_MULTIPLIER)
    local attackAction = self.entity.melee:createAction(self.direction)
    attackAction:parallelResolve(currentEvent)
    local duration = self.abilityStats:get(Tags.STAT_ABILITY_DEBUFF_DURATION)
    local poisonDamage = self.abilityStats:get(Tags.STAT_POISON_DAMAGE_TOTAL)
    attackAction.baseAttack.buff = BUFFS:get("POISON"):new(duration, self.entity, poisonDamage)
    return attackAction:chainEvent(currentEvent):chainEvent(function(_, anchor)
        self.outline:chainFadeOut(anchor, GLOW_DURATION)
        self.entity.player:multiplyAttackSpeed(1 / SPEED_MULTIPLIER)
    end)
end

local LEGENDARY = ITEM:createLegendary("Greenfang's Claws")
local LEGENDARY_FORMAT = "{C:KEYWORD}Resist %s against enemies affected by {C:KEYWORD}Poison."
LEGENDARY:setToStatsBase({ [Tags.STAT_MODIFIER_VALUE] = 2 })
LEGENDARY:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
LEGENDARY.statLine = function(item)
    return textStatFormat(LEGENDARY_FORMAT, item, Tags.STAT_MODIFIER_VALUE)
end
LEGENDARY.decorateIncomingHit = function(entity, hit, abilityStats)
    if hit:isDamagePositiveDirect() and hit.sourceEntity then
        if hit.sourceEntity:hasComponent("buffable") then
            if hit.sourceEntity.buffable:isAffectedBy(BUFFS:get("POISON")) then
                hit:reduceDamage(abilityStats:get(Tags.STAT_MODIFIER_VALUE))
                hit:decreaseBonusState()
            end

        end

    end

end
return ITEM

