local Vector = require("utils.classes.vector")
local Common = require("common")
local CONSTANTS = require("logic.constants")
local ActionUtils = require("actions.utils")
local ACTIONS_FRAGMENT = require("actions.fragment")
local MEASURES = require("draw.measures")
local COLORS = require("draw.colors")
local EASING = require("draw.easing")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Gravity Helm")
local ABILITY = require("structures.ability_def"):new("Singularity")
ABILITY:addTag(Tags.ABILITY_TAG_BOOSTABLE_ABILITY_DAMAGE)
ABILITY:addTag(Tags.ABILITY_TAG_RANGE_EXTENDABLE)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_HELM
ITEM.icon = Vector:new(7, 20)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 32, [Tags.STAT_MAX_MANA] = 8, [Tags.STAT_ABILITY_POWER] = 4.8, [Tags.STAT_ABILITY_DAMAGE_BASE] = 45.0, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.47), [Tags.STAT_ABILITY_RANGE_MIN] = 2, [Tags.STAT_ABILITY_RANGE_MAX] = 3, [Tags.STAT_ABILITY_AREA_ROUND] = Tags.ABILITY_AREA_3X3 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_RANGE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_RANGE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_RANGE] = 1 })
local FORMAT = "Pull targets %s spaces away in {C:NUMBER}8 " .. "directions, then deal %s damage to all targets around you."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_RANGE_MIN, Tags.STAT_ABILITY_DAMAGE_MIN)
end
ABILITY.icon = Vector:new(9, 11)
ABILITY.iconColor = COLORS.STANDARD_DEATH
ABILITY.directions = false
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    local source = entity.body:getPosition()
    local range = abilityStats:get(Tags.STAT_ABILITY_RANGE)
    local diagonalRange = round(range / math.sqrtOf2)
    local body = entity.body
    for direction in DIRECTIONS() do
        local thisRange = range
        if isDiagonal(direction) then
            thisRange = diagonalRange
        end

        for i = 1, thisRange do
            local target = source + Vector[direction] * i
                        if body:hasEntityWithTank(target) then
                castingGuide:indicate(target)
                break
            elseif not body:isPassable(target) then
                break
            else
                castingGuide:indicateWeak(target)
            end

        end

        castingGuide:indicate(source + Vector[direction])
    end

end
local KNOCKBACK_STEP_DURATION = 0.15
local BLACK_HOLE_RADIUS = MEASURES.TILE_SIZE * math.sqrt(0.6)
local EXPAND_DURATION = 0.6
local CONTRACT_DURATION = 0.4
local EXPLOSION_DURATION = 0.6
local EXPLOSION_SHAKE_INTENSITY = 2.0
local ACTION = class(ACTIONS_FRAGMENT.ENCHANT)
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("explosion")
    self.explosion.excludeSelf = true
    self.explosion:setHueToDeath()
    self.explosion.shakeIntensity = EXPLOSION_SHAKE_INTENSITY
    self.color = COLORS.STANDARD_DEATH_BRIGHTER
end

function ACTION:process(currentEvent)
    local sound, origVolume
    currentEvent = ACTION:super(self, "process", currentEvent):chainEvent(function()
        sound = Common.playSFX("GRAVITY")
        origVolume = sound:getVolume()
    end)
    local blackHole = self:createEffect("black_hole")
    local source = self.entity.body:getPosition()
    blackHole.position = source
    local range = self.abilityStats:get(Tags.STAT_ABILITY_RANGE)
    local diagonalRange = round(range / math.sqrtOf2)
    local body = self.entity.body
    self.explosion.source = source
    for direction in DIRECTIONS() do
        local thisRange = range
        if isDiagonal(direction) then
            thisRange = diagonalRange
        end

        for i = 1, thisRange do
            local target = source + Vector[direction] * i
                        if body:hasEntityWithTank(target) and i > 1 then
                local hit = self.entity.hitter:createHit()
                hit.sound = false
                hit:setKnockback(i - 1, reverseDirection(direction), EXPAND_DURATION / (i - 1), false, true)
                hit:applyToPosition(currentEvent, target)
                break
            elseif not body:isPassable(target) then
                break
            end

        end

    end

    currentEvent = currentEvent:chainProgress(EXPAND_DURATION, function(progress)
        blackHole.radius = BLACK_HOLE_RADIUS * progress
    end, EASING.OUT_QUAD):chainEvent(function()
        Common.playSFX("EXPLOSION_MEDIUM")
    end)
    currentEvent:chainProgress(CONTRACT_DURATION, function(progress)
        blackHole.radius = BLACK_HOLE_RADIUS * (1 - progress)
        blackHole.opacity = (1 - progress)
    end, EASING.QUAD)
    currentEvent:chainProgress(EXPLOSION_DURATION, function(progress)
        sound:setVolume(origVolume * (1 - progress))
    end):chainEvent(function()
        sound:stop()
    end)
    return self.explosion:chainFullEvent(currentEvent, EXPLOSION_DURATION, function(anchor, position)
        local hit = self.entity.hitter:createHit()
        hit:setDamageFromAbilityStats(Tags.DAMAGE_TYPE_SPELL, self.abilityStats)
        hit:applyToPosition(anchor, position)
    end)
end

local LEGENDARY = ITEM:createLegendary("Helm of the Black Horizon")
local LEGENDARY_STAT_LINE = "{C:KEYWORD}Resist %s for every enemy around you after the first."
LEGENDARY.statLine = function(item)
    return textStatFormat(LEGENDARY_STAT_LINE, item, Tags.STAT_MODIFIER_VALUE)
end
LEGENDARY:setToStatsBase({ [Tags.STAT_MODIFIER_VALUE] = 2 })
LEGENDARY.decorateIncomingHit = function(entity, hit, abilityStats)
    if hit:isDamagePositiveDirect() then
        local source = hit.targetPosition
        local count = DIRECTIONS:countIf(function(direction)
            return entity.body:hasEntityWithAgent(source + Vector[direction])
        end)
        if count > 1 then
            hit:decreaseBonusState()
            hit:reduceDamage(abilityStats:get(Tags.STAT_MODIFIER_VALUE) * (count - 1))
        end

    end

end
LEGENDARY:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
LEGENDARY.modifyItem = function(item)
end
return ITEM

