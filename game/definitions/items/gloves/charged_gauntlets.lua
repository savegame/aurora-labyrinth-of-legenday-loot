local Vector = require("utils.classes.vector")
local Common = require("common")
local BUFFS = require("definitions.buffs")
local ACTION_CONSTANTS = require("actions.constants")
local ACTIONS_FRAGMENT = require("actions.fragment")
local ActionUtils = require("actions.utils")
local MEASURES = require("draw.measures")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Charged Gauntlets")
local ABILITY = require("structures.ability_def"):new("Lightning Attack")
ABILITY:addTag(Tags.ABILITY_TAG_PLUS_BASIC_ATTACK)
ABILITY:addTag(Tags.ABILITY_TAG_DIRECTIONAL_RECASTABLE)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_GLOVES
ITEM.icon = Vector:new(15, 17)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 28, [Tags.STAT_MAX_MANA] = 12, [Tags.STAT_ABILITY_POWER] = 3.39, [Tags.STAT_ABILITY_DAMAGE_BASE] = 7.8, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.94), [Tags.STAT_ABILITY_DEBUFF_DURATION] = 1 })
ITEM:setGrowthMultiplier({ [Tags.STAT_ABILITY_DAMAGE_BASE] = 1.5 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_DEBUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "{C:KEYWORD}Attack an enemy, dealing %s bonus damage. " .. "The target is {C:KEYWORD}Stunned for %s."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_DAMAGE_MIN, Tags.STAT_ABILITY_DEBUFF_DURATION)
end
ABILITY.icon = Vector:new(6, 5)
ABILITY.iconColor = COLORS.STANDARD_LIGHTNING
ABILITY.getInvalidReason = ActionUtils.getInvalidReasonEnemyAttack
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    local target = ActionUtils.indicateExtendableAttack(entity, direction, abilityStats, castingGuide)
    if ABILITY.getInvalidReason(entity, direction, abilityStats) then
        castingGuide:indicateWeak(target)
    end

end
local ACTION = class(ACTIONS_FRAGMENT.ENCHANT)
ABILITY.actionClass = ACTION
local SPEED_MULTIPLIER = 0.7
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("lightningspawner")
    self.color = ABILITY.iconColor
    self.manualFadeOut = true
end

function ACTION:process(currentEvent)
    local entity = self.entity
    entity.sprite:turnToDirection(self.direction)
    entity.player:multiplyAttackSpeed(SPEED_MULTIPLIER)
    local spawnEvent = currentEvent:chainProgress(self.duration - self.lightningspawner.strikeDuration * 2)
    currentEvent = ACTION:super(self, "process", currentEvent)
    local strikeTarget = entity.body:getPosition() - Vector:new(0, 0.5)
    if MEASURES.FLIPPED_DIRECTIONS:contains(self.direction) then
        strikeTarget = strikeTarget + self.weaponswing.swingItem.offset * Vector[DOWN_LEFT]
    else
        strikeTarget = strikeTarget + self.weaponswing.swingItem.offset
    end

    spawnEvent:chainEvent(function()
        Common.playSFX("LIGHTNING")
    end)
    self.lightningspawner:spawn(spawnEvent, strikeTarget)
    currentEvent = self:fadeOut(currentEvent)
    local attackAction = entity.melee:createAction(self.direction)
    attackAction:parallelResolve(currentEvent)
    attackAction.baseAttack:setBonusFromAbilityStats(self.abilityStats)
    local duration = self.abilityStats:get(Tags.STAT_ABILITY_DEBUFF_DURATION)
    if self.abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 then
        local targetEntity = entity.body:getEntityAt(attackAction.baseAttack.attackTarget)
        if Common.isElite(targetEntity) then
            duration = duration + self.abilityStats:get(Tags.STAT_MODIFIER_VALUE)
        end

    end

    attackAction.baseAttack.buff = BUFFS:get("STUN"):new(duration)
    return attackAction:chainEvent(currentEvent):chainEvent(function()
        entity.player:multiplyAttackSpeed(1 / SPEED_MULTIPLIER)
    end)
end

local LEGENDARY = ITEM:createLegendary("Giantslayer Gauntlets")
local LEGENDARY_EXTRA_LINE = "If it is {C:KEYWORD}Elite, it is {C:KEYWORD}Stunned for %s more turn."
LEGENDARY:setToStatsBase({ [Tags.STAT_MODIFIER_VALUE] = 1 })
LEGENDARY.abilityExtraLine = function(item)
    return textStatFormat(LEGENDARY_EXTRA_LINE, item, Tags.STAT_MODIFIER_VALUE)
end
return ITEM

