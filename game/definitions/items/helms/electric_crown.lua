local Vector = require("utils.classes.vector")
local SparseGrid = require("utils.classes.sparse_grid")
local Set = require("utils.classes.set")
local Common = require("common")
local ActionUtils = require("actions.utils")
local ACTIONS_FRAGMENT = require("actions.fragment")
local ACTION_CONSTANTS = require("actions.constants")
local BUFFS = require("definitions.buffs")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Electric Crown")
local ABILITY = require("structures.ability_def"):new("Chain Lightning")
ABILITY:addTag(Tags.ABILITY_TAG_BOOSTABLE_ABILITY_DAMAGE)
ABILITY:addTag(Tags.ABILITY_TAG_SURROUNDING_DISABLE)
ABILITY:addTag(Tags.ABILITY_TAG_DIRECTIONAL_RECASTABLE)
ABILITY:addTag(Tags.ABILITY_TAG_RANGE_EXTENDABLE)
ITEM:setToMediumComplexity()
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_HELM
ITEM.icon = Vector:new(6, 7)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 6, [Tags.STAT_MAX_MANA] = 34, [Tags.STAT_ABILITY_POWER] = 6.4, [Tags.STAT_ABILITY_RANGE] = 3, [Tags.STAT_ABILITY_DEBUFF_DURATION] = 1, [Tags.STAT_ABILITY_DAMAGE_BASE] = 35.9, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.97) })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_RANGE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_RANGE] = 1 })
local FORMAT = "{C:KEYWORD}Range %s - Fire a lightning bolt that hits an enemy or object. The lightning repeatedly jumps to a random target around it. All targets take %s damage and get {C:KEYWORD}Stunned for %s."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_RANGE_MIN, Tags.STAT_ABILITY_DAMAGE_MIN, Tags.STAT_ABILITY_DEBUFF_DURATION)
end
local function indicatePotentialTargets(entity, castingGuide, source)
    for direction in DIRECTIONS() do
        local target = source + Vector[direction]
        local indication = castingGuide:getIndication(target)
        if indication == 0 and entity.vision:isVisible(target) and entity.body:hasEntityWithTank(target) then
            castingGuide:indicateWeak(target)
            indicatePotentialTargets(entity, castingGuide, target)
        end

    end

end

ABILITY.icon = Vector:new(3, 4)
ABILITY.iconColor = COLORS.STANDARD_LIGHTNING
ABILITY.getInvalidReason = ActionUtils.getInvalidReasonTarget
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    local targetEntity = ActionUtils.indicateTargetWithinRange(entity, direction, abilityStats, castingGuide)
    if targetEntity then
        local target = targetEntity.body:getPosition()
        castingGuide:indicate(target)
        indicatePotentialTargets(entity, castingGuide, target)
        castingGuide:unindicate(entity.body:getPosition())
    end

end
local ACTION = class(ACTIONS_FRAGMENT.CAST)
ABILITY.actionClass = ACTION
local STRIKE_DURATION = 0.16
local LIGHTNING_COUNT = 2
local JUMP_DELAY = 0.025
local SOUND_FADE = 0.3
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("lightningspawner")
    self.lightningspawner.lightningCount = LIGHTNING_COUNT
    self.color = ABILITY.iconColor
    self:speedMultiply(ACTION_CONSTANTS.SLOW_CAST_MULTIPLIER)
end

function ACTION:process(currentEvent)
    currentEvent = ACTION:super(self, "process", currentEvent)
    self.entity.sprite:turnToDirection(self.direction)
    local duration = self.abilityStats:get(Tags.STAT_ABILITY_DEBUFF_DURATION)
    local entity = self.entity
    local currentTarget = ActionUtils.getTargetWithinRange(self.entity, self.direction, self.abilityStats)
    local previous = self.entity.body:getPosition()
    local sound = false
    local origVolume
    currentEvent:chainEvent(function()
        sound = Common.playSFX("LIGHTNING_LOOP")
        origVolume = sound:getVolume()
    end)
    local targetsHit = Set:new()
    targetsHit:add(self.entity)
    while currentTarget do
        local thisPrevious = previous
        local thisTarget = currentTarget
        currentEvent:chainEvent(function()
            self.entity.entityspawner:spawn("temporary_vision", thisTarget.body:getPosition())
        end)
        currentEvent = self.lightningspawner:spawn(currentEvent, thisTarget.body:getPosition(), thisPrevious):chainEvent(function(_, anchor)
            local hit = entity.hitter:createHit(thisPrevious)
            hit:setDamageFromAbilityStats(Tags.DAMAGE_TYPE_SPELL, self.abilityStats)
            hit:addBuff(BUFFS:get("STUN"):new(duration))
            hit:applyToEntity(anchor, thisTarget)
        end)
        self.lightningspawner.strikeDuration = STRIKE_DURATION
        targetsHit:add(currentTarget)
        currentTarget = false
        previous = thisTarget.body:getPosition()
        local directions = DIRECTIONS:shuffle(self:getLogicRNG())
        for direction in directions() do
            currentTarget = self.entity.body:getEntityAt(previous + Vector[direction])
            if currentTarget and currentTarget:hasComponent("tank") and not targetsHit:contains(currentTarget) then
                currentEvent = currentEvent:chainProgress(JUMP_DELAY)
                break
            else
                currentTarget = false
            end

        end

    end

    currentEvent:chainProgress(SOUND_FADE, function(progress)
        sound:setVolume((1 - progress) * origVolume)
    end):chainEvent(function()
        sound:stop()
    end)
    return currentEvent
end

local LEGENDARY = ITEM:createLegendary("Thunderlord's Authority")
LEGENDARY:setToStatsBase({ [Tags.STAT_ABILITY_DEBUFF_DURATION] = 3 })
LEGENDARY.modifyItem = function(item)
    item:markAltered(Tags.STAT_ABILITY_DEBUFF_DURATION, Tags.STAT_UPGRADED)
end
return ITEM

