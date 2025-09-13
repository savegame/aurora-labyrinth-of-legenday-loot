local Vector = require("utils.classes.vector")
local Array = require("utils.classes.array")
local Common = require("common")
local EASING = require("draw.easing")
local CONSTANTS = require("logic.constants")
local ActionUtils = require("actions.utils")
local ACTIONS_FRAGMENT = require("actions.fragment")
local ACTION_CONSTANTS = require("actions.constants")
local COLORS = require("draw.colors")
local TERMS = require("text.terms")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Boulder Cloak")
local ABILITY = require("structures.ability_def"):new("Earth Prison")
ABILITY:addTag(Tags.ABILITY_TAG_DIRECTIONAL_RECASTABLE)
ABILITY:addTag(Tags.ABILITY_TAG_RANGE_EXTENDABLE)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_ARMOR
ITEM.icon = Vector:new(15, 12)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 10, [Tags.STAT_MAX_MANA] = 50, [Tags.STAT_ABILITY_POWER] = 2.65, [Tags.STAT_SECONDARY_DAMAGE_BASE] = 30, [Tags.STAT_SECONDARY_DAMAGE_VARIANCE] = 0, [Tags.STAT_ABILITY_RANGE_MAX] = 3, [Tags.STAT_ABILITY_DEBUFF_DURATION] = 5 })
ITEM:setGrowthMultiplier({ [Tags.STAT_SECONDARY_DAMAGE_BASE] = 2.66 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_DEBUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_DEBUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_RANGE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_DEBUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_COST] = -5 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_DEBUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_RANGE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_DEBUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "{C:KEYWORD}Range %s - Create an obstacle on each unoccupied space adjacent to an enemy. Lasts for %s and has %s health each."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_RANGE_MIN, Tags.STAT_ABILITY_DEBUFF_DURATION, Tags.STAT_SECONDARY_DAMAGE_MIN)
end
ABILITY.icon = Vector:new(10, 8)
ABILITY.iconColor = COLORS.STANDARD_EARTH
ABILITY.getInvalidReason = function(entity, direction, abilityStats)
    local entityAt = ActionUtils.getEnemyWithinRange(entity, direction, abilityStats)
    if not entityAt then
        return TERMS.INVALID_DIRECTION_NO_ENEMY
    else
        local position = entityAt.body:getPosition()
        for adjacentDir in DIRECTIONS_AA() do
            if entity.body:isPassable(position + Vector[adjacentDir]) then
                return false
            end

        end

        return "Enemy has no adjacent unoccupied space"
    end

end
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    local targetEntity = ActionUtils.getEnemyWithinRange(entity, direction, abilityStats)
    local range = abilityStats:get(Tags.STAT_ABILITY_RANGE)
    for i = 1, range do
        local target = entity.body:getPosition() + Vector[direction] * i
        if not entity.body:canBePassable(target) or not entity.vision:isVisible(target) then
            break
        end

        if targetEntity and target == targetEntity.body:getPosition() then
            break
        end

        castingGuide:indicateWeak(target)
    end

    if targetEntity then
        local position = targetEntity.body:getPosition()
        for adjacentDir in DIRECTIONS_AA() do
            local target = position + Vector[adjacentDir]
            if entity.body:isPassable(target) then
                castingGuide:indicate(target)
            end

        end

    end

end
local ACTION = class(ACTIONS_FRAGMENT.CAST)
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self.color = ABILITY.iconColor
    self:speedMultiply(ACTION_CONSTANTS.SLOW_CAST_MULTIPLIER)
    self.swingCastPoint = 1
end

local ROCK_HEIGHT = 1.5
local FALL_DURATION = 0.2
function ACTION:process(currentEvent)
    self.entity.sprite:turnToDirection(self.direction)
    local abilityStats = self.abilityStats
    currentEvent = ACTION:super(self, "process", currentEvent):chainEvent(function(_, anchor)
        local targetEntity = ActionUtils.getEnemyWithinRange(self.entity, self.direction, abilityStats)
        local targetPosition = targetEntity.body:getPosition()
        local rocks = Array:new()
        for adjacentDir in DIRECTIONS_AA() do
            local target = targetPosition + Vector[adjacentDir]
            if self.entity.body:isPassable(target) then
                local rock = self.entity.entityspawner:spawn("rock", target, abilityStats:get(Tags.STAT_SECONDARY_DAMAGE_MIN), true)
                rock.charactereffects:flash(ACTION_CONSTANTS.NEGATIVE_FADE_DURATION, ABILITY.iconColor)
                rock.sprite.layer = Tags.LAYER_FLYING
                rock.perishable.duration = abilityStats:get(Tags.STAT_ABILITY_DEBUFF_DURATION)
                local offset = rock.offset:createProfile()
                offset.jump = ROCK_HEIGHT
                rocks:push(rock)
            end

        end

        if not rocks:isEmpty() then
            anchor:chainProgress(FALL_DURATION, function(progress)
                for rock in rocks() do
                    rock.offset:getLastProfile().jump = ROCK_HEIGHT * (1 - progress)
                end

            end, EASING.QUAD):chainEvent(function(_, anchor)
                for rock in rocks() do
                    rock.offset:deleteLastProfile()
                    rock.sprite:resetLayer()
                end

                Common.playSFX("ROCK_SHAKE")
                self:shakeScreen(anchor, 2.0)
                if abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 then
                    Common.playSFX("BURN_DAMAGE")
                    local hit = self.entity.hitter:createHit()
                    hit:setSpawnFire(abilityStats:get(Tags.STAT_ABILITY_BURN_DURATION), abilityStats:get(Tags.STAT_MODIFIER_DAMAGE_MIN), abilityStats:get(Tags.STAT_MODIFIER_DAMAGE_MAX))
                    hit.slotSource = self:getSlot()
                    hit:applyToPosition(anchor, targetPosition)
                end

            end)
        end

    end)
    return currentEvent
end

local LEGENDARY = ITEM:createLegendary("Cloak of the Volcano")
local LEGENDARY_EXTRA_LINE = "{C:KEYWORD}Burn the target space. " .. "%s, %s health lost per turn."
LEGENDARY.strokeColor = COLORS.STANDARD_FIRE
LEGENDARY:setToStatsBase({ [Tags.STAT_ABILITY_BURN_DURATION] = 5, [Tags.STAT_MODIFIER_DAMAGE_BASE] = 7.8, [Tags.STAT_MODIFIER_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.60) })
LEGENDARY:addPowerSpike({ [Tags.STAT_ABILITY_BURN_DURATION] = 1 })
LEGENDARY:addPowerSpike({  })
LEGENDARY:addPowerSpike({ [Tags.STAT_ABILITY_BURN_DURATION] = 1 })
LEGENDARY:addPowerSpike({  })
LEGENDARY:addPowerSpike({ [Tags.STAT_ABILITY_BURN_DURATION] = 1 })
LEGENDARY:addPowerSpike({  })
LEGENDARY:addPowerSpike({ [Tags.STAT_ABILITY_BURN_DURATION] = 1 })
LEGENDARY:addPowerSpike({  })
LEGENDARY:addPowerSpike({ [Tags.STAT_ABILITY_BURN_DURATION] = 1 })
LEGENDARY:addPowerSpike({  })
LEGENDARY.abilityExtraLine = function(item)
    return textStatFormat(LEGENDARY_EXTRA_LINE, item, Tags.STAT_ABILITY_BURN_DURATION, Tags.STAT_MODIFIER_DAMAGE_MIN)
end
return ITEM

