local Vector = require("utils.classes.vector")
local Common = require("common")
local BUFFS = require("definitions.buffs")
local ActionUtils = require("actions.utils")
local ACTIONS_FRAGMENT = require("actions.fragment")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Rage Gauntlets")
local ABILITY = require("structures.ability_def"):new("Rage Strike")
ABILITY:addTag(Tags.ABILITY_TAG_PLUS_BASIC_ATTACK)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_GLOVES
ITEM.icon = Vector:new(21, 15)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 40, [Tags.STAT_ABILITY_POWER] = 2.55, [Tags.STAT_ABILITY_DAMAGE_BASE] = 30, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = 0, [Tags.STAT_ABILITY_BUFF_DURATION] = 1, [Tags.STAT_ABILITY_SUSTAIN_MODE] = Tags.SUSTAIN_MODE_AUTOCAST })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "{C:KEYWORD}Focus - Do an {C:KEYWORD}Attack, dealing max damage plus %s for every " .. "time you were hit while {C:KEYWORD}Focusing"
local FORMAT_NORMAL_END = "."
local FORMAT_LEGENDARY_END = ", {B:STAT_LINE}plus the total damage you took."
ABILITY.getDescription = function(item)
    if item.stats:get(Tags.STAT_LEGENDARY, 0) > 0 then
        return textStatFormat(FORMAT .. FORMAT_LEGENDARY_END, item, Tags.STAT_ABILITY_DAMAGE_MIN)
    else
        return textStatFormat(FORMAT .. FORMAT_NORMAL_END, item, Tags.STAT_ABILITY_DAMAGE_MIN)
    end

end
ABILITY.icon = Vector:new(8, 6)
ABILITY.iconColor = COLORS.STANDARD_RAGE
ABILITY.getInvalidReason = ActionUtils.getInvalidReasonFrontCantBePassable
ABILITY.indicate = ActionUtils.indicateExtendableAttack
local MAIN_ACTION = class("actions.action")
local BUFF = class(BUFFS.FOCUS)
ABILITY.buffClass = BUFF
function BUFF:initialize(duration, abilityStats, action)
    BUFF:super(self, "initialize", duration, abilityStats, action)
    self.bonusDamage = 0
    self.mainActionClass = MAIN_ACTION
end

function BUFF:decorateIncomingHit(hit)
    if hit:isDamageOrDebuff() then
        self.bonusDamage = self.bonusDamage + self.abilityStats:get(Tags.STAT_ABILITY_DAMAGE_MIN)
        if self.abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 then
            hit:forceResolve()
            self.bonusDamage = self.bonusDamage + hit.minDamage
        end

    end

end

function BUFF:decoratePostFocusAction(action)
    action.damage = action.entity.stats:get(Tags.STAT_ATTACK_DAMAGE_MAX) + self.bonusDamage
end

local ACTION = class(ACTIONS_FRAGMENT.GLOW_MODAL)
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self.color = ABILITY.iconColor
    self.sound = "ENCHANT"
end

local STRIKE_GLOW_DURATION = 0.2
local SPEED_MULTIPLIER = 0.35
function MAIN_ACTION:initialize(entity, direction, abilityStats)
    MAIN_ACTION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("outline")
    self.outline.color = ABILITY.iconColor
    self.damage = false
end

function MAIN_ACTION:process(currentEvent)
    currentEvent = self.outline:chainFadeIn(currentEvent, STRIKE_GLOW_DURATION)
    local entity = self.entity
    entity.player:multiplyAttackSpeed(SPEED_MULTIPLIER)
    local attackAction = entity.melee:createAction(self.direction)
    attackAction:parallelResolve(currentEvent)
    local baseAttack = attackAction.baseAttack
    baseAttack.forcedMinDamage = self.damage
    baseAttack.forcedMaxDamage = self.damage
    entity.player:multiplyAttackSpeed(1 / SPEED_MULTIPLIER)
    currentEvent = attackAction:chainEvent(currentEvent):chainEvent(function(_, anchor)
        self:shakeScreen(anchor, 2)
        Common.playSFX("ROCK_SHAKE")
    end)
    self.outline:chainFadeOut(currentEvent, STRIKE_GLOW_DURATION)
    return currentEvent
end

local LEGENDARY = ITEM:createLegendary("Siege Breaker")
return ITEM

