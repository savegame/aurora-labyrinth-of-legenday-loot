local Vector = require("utils.classes.vector")
local CONSTANTS = require("logic.constants")
local Common = require("common")
local ActionUtils = require("actions.utils")
local ACTIONS_FRAGMENT = require("actions.fragment")
local ACTIONS_BASIC = require("actions.basic")
local ACTION_CONSTANTS = require("actions.constants")
local BUFFS = require("definitions.buffs")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Flare Helm")
local ABILITY = require("structures.ability_def"):new("Eruption")
ABILITY:addTag(Tags.ABILITY_TAG_NON_QUICK_CANCEL)
ITEM:setToMediumComplexity()
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_HELM
ITEM.icon = Vector:new(13, 15)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 28, [Tags.STAT_MAX_MANA] = 12, [Tags.STAT_ABILITY_POWER] = 6.3, [Tags.STAT_ABILITY_BUFF_DURATION] = 3, [Tags.STAT_ABILITY_QUICK] = 1, [Tags.STAT_ABILITY_AREA_ROUND] = Tags.ABILITY_AREA_ROUND_5X5, [Tags.STAT_ABILITY_DAMAGE_BASE] = 8.3, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.82) })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_BUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_BUFF_DURATION] = 1 })
local FORMAT = "{C:KEYWORD}Quick {C:KEYWORD}Buff %s - When this buff ends, skip your turn " .. "and deal %s damage for every turn it was active {C:NUMBER}+1 to all enemies in a %s."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_BUFF_DURATION, Tags.STAT_ABILITY_DAMAGE_MIN, Tags.STAT_ABILITY_AREA_ROUND)
end
ABILITY.icon = Vector:new(12, 1)
ABILITY.iconColor = COLORS.STANDARD_FIRE
ABILITY.directions = false
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    local area = abilityStats:get(Tags.STAT_ABILITY_AREA_ROUND)
    for position in (ActionUtils.getAreaPositions(entity, entity.body:getPosition(), area, true))() do
        castingGuide:indicateWeak(position)
    end

end
local EXPLOSION_DURATION = 0.6
local EXPLOSION_SHAKE_INTENSITY = 4
local LARGE_DURATION_MULTIPLIER = 1.35
local MAIN_ACTION = class("actions.action")
function MAIN_ACTION:initialize(entity, direction, abilityStats)
    MAIN_ACTION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("explosion")
    self.explosion.excludeSelf = true
    self.turnsCharged = 0
end

function MAIN_ACTION:process(currentEvent)
    local explosionDuration = EXPLOSION_DURATION
    self.explosion.source = self.entity.body:getPosition()
    local area = self.abilityStats:get(Tags.STAT_ABILITY_AREA_ROUND)
    if area >= Tags.ABILITY_AREA_ROUND_5X5 then
        explosionDuration = explosionDuration * LARGE_DURATION_MULTIPLIER
    end

    self.explosion:setArea(area)
    local minDamage = self.turnsCharged * self.abilityStats:get(Tags.STAT_ABILITY_DAMAGE_MIN)
    local maxDamage = self.turnsCharged * self.abilityStats:get(Tags.STAT_ABILITY_DAMAGE_MAX)
    self.explosion.shakeIntensity = max(self.turnsCharged, EXPLOSION_SHAKE_INTENSITY)
    Common.playSFX("EXPLOSION_MEDIUM", self.explosion:getSizeAdjustedPitch())
    return self.explosion:chainFullEvent(currentEvent, explosionDuration, function(anchor, position)
        local hit = self.entity.hitter:createHit(self.explosion.source)
        hit:setDamage(Tags.DAMAGE_TYPE_SPELL, minDamage, maxDamage)
        hit.slotSource = self:getSlot()
        hit:applyToPosition(anchor, position)
    end)
end

local MODE_CANCEL = class(ACTIONS_BASIC.DEFAULT_MODE_CANCEL)
function MODE_CANCEL:initialize(entity, direction, abilityStats)
    MODE_CANCEL:super(self, "initialize", entity, direction, abilityStats)
    self.abilityStats:deleteKey(Tags.STAT_ABILITY_QUICK)
end

ABILITY.modeCancelClass = MODE_CANCEL
local BUFF = class("structures.item_buff")
ABILITY.buffClass = BUFF
function BUFF:initialize(duration, abilityStats)
    BUFF:super(self, "initialize", duration, abilityStats)
    self.outlinePulseColor = ABILITY.iconColor
    self.expiresAtStart = true
    self.turnsCharged = 1
end

function BUFF:toData()
    return { turnsCharged = self.turnsCharged }
end

function BUFF:fromData(data)
    self.turnsCharged = data.turnsCharged
end

function BUFF:onTurnEnd()
    self.turnsCharged = self.turnsCharged + 1
end

function BUFF:onExpire(anchor, entity)
    entity.player.skipNextTurn = true
end

function BUFF:onDelete(anchor, entity)
    local action = entity.actor:create(MAIN_ACTION, false, self.abilityStats)
    action.turnsCharged = self.turnsCharged
    action:parallelChainEvent(anchor)
end

local ACTION = class(ACTIONS_FRAGMENT.GLOW_MODAL)
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self.color = ABILITY.iconColor
    self.sound = "ENCHANT"
end

local LEGENDARY = ITEM:createLegendary("Helm of Inner Fire")
LEGENDARY.statLine = "{C:NUMBER}+1 turn to all {C:KEYWORD}Buffs and {C:KEYWORD}Sustained " .. "abilities that last more than {C:NUMBER}1 turn."
LEGENDARY:setAbilityStatBonus(Tags.STAT_ABILITY_BUFF_DURATION, function(item, baseValue, thisAbilityStats)
    if thisAbilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 then
        if baseValue > 1 then
            return 1
        end

    end

    return 0
end)
return ITEM

