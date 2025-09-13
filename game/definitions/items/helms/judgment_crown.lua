local Vector = require("utils.classes.vector")
local Array = require("utils.classes.array")
local Common = require("common")
local BUFFS = require("definitions.buffs")
local ActionUtils = require("actions.utils")
local ACTION_CONSTANTS = require("actions.constants")
local ACTIONS_FRAGMENT = require("actions.fragment")
local COLORS = require("draw.colors")
local TERMS = require("text.terms")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Judgment Crown")
local ABILITY = require("structures.ability_def"):new("Meteor")
ABILITY:addTag(Tags.ABILITY_TAG_BOOSTABLE_ABILITY_DAMAGE)
ITEM:setToMediumComplexity()
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_HELM
ITEM.icon = Vector:new(4, 16)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 4, [Tags.STAT_MAX_MANA] = 36, [Tags.STAT_ABILITY_POWER] = 6.8, [Tags.STAT_ABILITY_DAMAGE_BASE] = 50.0, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.76), [Tags.STAT_SECONDARY_DAMAGE_BASE] = 12, [Tags.STAT_SECONDARY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.76), [Tags.STAT_ABILITY_RANGE] = 3, [Tags.STAT_ABILITY_AREA_ROUND] = Tags.ABILITY_AREA_3X3, [Tags.STAT_ABILITY_BUFF_DURATION] = 1, [Tags.STAT_ABILITY_SUSTAIN_MODE] = Tags.SUSTAIN_MODE_AUTOCAST, [Tags.STAT_ABILITY_BURN_DURATION] = 4 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_BURN_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "{C:KEYWORD}Focus - Deal %s damage to all targets in a %s %s away. {FORCE_NEWLINE} %s, %s health lost per turn."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_DAMAGE_MIN, Tags.STAT_ABILITY_AREA_ROUND, Tags.STAT_ABILITY_RANGE, Tags.STAT_ABILITY_BURN_DURATION, Tags.STAT_SECONDARY_DAMAGE_MIN)
end
ABILITY.icon = Vector:new(9, 1)
ABILITY.iconColor = COLORS.STANDARD_FIRE
ABILITY.getInvalidReason = function(entity, direction, abilityStats)
    local source = entity.body:getPosition()
    local range = abilityStats:get(Tags.STAT_ABILITY_RANGE)
    for i = 1, range do
        local target = source + Vector[direction] * i
        if not entity.body:canBePassable(target) or not entity.vision:isVisible(target) then
            return TERMS.INVALID_DIRECTION_BLOCKED
        end

    end

    return false
end
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    if not ABILITY.getInvalidReason(entity, direction, abilityStats) then
        local range = abilityStats:get(Tags.STAT_ABILITY_RANGE)
        local area = abilityStats:get(Tags.STAT_ABILITY_AREA_ROUND)
        ActionUtils.indicateArea(entity, entity.body:getPosition() + Vector[direction] * range, area, castingGuide)
    end

end
local MAIN_ACTION = class("actions.action")
local BUFF = class(BUFFS.FOCUS)
ABILITY.buffClass = BUFF
function BUFF:initialize(duration, abilityStats, action)
    BUFF:super(self, "initialize", duration, abilityStats, action)
    self.mainActionClass = MAIN_ACTION
end

function BUFF:onTurnStart(anchor, entity)
    if not self.action:isValid() then
        entity.equipment:deactivateSlot(anchor, self.abilityStats:get(Tags.STAT_SLOT))
    end

end

function BUFF:onDelete(anchor, entity)
    self.action:deactivate()
end

local DISTANCE = 2.5
local FALL_DURATION = 0.4
local TRAIL_FADE_REPEAT = 0.01
local EXPLOSION_DURATION = 1
local EXPLOSION_SHAKE_INTENSITY = 6
local DELAYED_FALL = BUFFS:define("JUDGMENT_DELAYED_FALL")
function MAIN_ACTION:initialize(entity, direction, abilityStats)
    MAIN_ACTION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("image")
    self:addComponent("explosion")
    self.explosion.excludeSelf = false
    self.explosion.shakeIntensity = EXPLOSION_SHAKE_INTENSITY
    self.target = false
end

function MAIN_ACTION:process(currentEvent)
    local area = self.abilityStats:get(Tags.STAT_ABILITY_AREA_ROUND)
    local target = self.target
    if not target then
        local range = self.abilityStats:get(Tags.STAT_ABILITY_RANGE)
        target = self.entity.body:getPosition() + Vector[self.direction] * range
    end

    self.explosion.source = target
    self.explosion:setArea(area)
    Common.playSFX("WHOOSH_BIG")
    local meteor, meteorTrail = self.image:createWithTrail("meteor")
    meteor.position = target - Vector:new(0, DISTANCE)
    meteor.direction = DOWN
    meteorTrail.initialOpacity = 0.5
    meteorTrail:chainTrailEvent(currentEvent, TRAIL_FADE_REPEAT)
    currentEvent = currentEvent:chainProgress(FALL_DURATION, function(progress)
        meteor.position = target - Vector:new(0, DISTANCE) * (1 - progress)
    end):chainEvent(function()
        meteor:delete()
        meteorTrail:stopTrailEvent()
        Common.playSFX("ROCK_SHAKE")
        Common.playSFX("EXPLOSION_MEDIUM", 0.75)
    end)
    if not self.target and self.abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 then
        self.entity.buffable:apply(DELAYED_FALL:new(target, self.abilityStats))
    end

    return self.explosion:chainFullEvent(currentEvent, EXPLOSION_DURATION, function(anchor, position)
        local hit = self.entity.hitter:createHit(self.entity.body:getPosition())
        hit:setDamageFromAbilityStats(Tags.DAMAGE_TYPE_SPELL, self.abilityStats)
        hit:setSpawnFireFromSecondary(self.abilityStats)
        hit:applyToPosition(anchor, position)
    end)
end

local CAST_SPEED = 0.7
local ACTION = class(ACTIONS_FRAGMENT.CAST)
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self.color = ABILITY.iconColor
    self:speedMultiply(CAST_SPEED)
    self.keepSwingItem = true
    self.weaponswing.angleEnd = math.tau * 0.125
end

function ACTION:deactivate()
    self.weaponswing:deleteSwingItem()
end

function ACTION:isValid()
    return not ABILITY.getInvalidReason(self.entity, self.direction, self.abilityStats)
end

function ACTION:process(currentEvent)
    local range = self.abilityStats:get(Tags.STAT_ABILITY_RANGE)
    local area = self.abilityStats:get(Tags.STAT_ABILITY_AREA_ROUND)
    local source = self.entity.body:getPosition() + Vector[self.direction] * range
    return ACTION:super(self, "process", currentEvent)
end

local LEGENDARY = ITEM:createLegendary("Infernal Tyrant")
LEGENDARY.abilityExtraLine = "At the end of your next turn, another {C:ABILITY_LABEL}Meteor " .. "falls at the same position."
function DELAYED_FALL:initialize(position, abilityStats)
    DELAYED_FALL:super(self, "initialize", 1)
    self.position = position
    self.abilityStats = abilityStats
    self.delayTurn = true
end

function DELAYED_FALL:getDataArgs()
    return self.position, self.abilityStats
end

function DELAYED_FALL:onExpire(anchor, entity)
    local action = entity.actor:create(MAIN_ACTION, false, self.abilityStats)
    action.target = self.position
    action:parallelChainEvent(anchor)
end

return ITEM

