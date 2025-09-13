local Vector = require("utils.classes.vector")
local Common = require("common")
local BUFFS = require("definitions.buffs")
local ACTION_CONSTANTS = require("actions.constants")
local ATTACK_WEAPON = require("actions.attack_weapon")
local TRIGGERS = require("actions.triggers")
local MEASURES = require("draw.measures")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Whirlwind Axe")
local ABILITY = require("structures.ability_def"):new("Steel Whirlwind")
ABILITY:addTag(Tags.ABILITY_TAG_BOOSTABLE_PERIODIC_DAMAGE)
ABILITY:addTag(Tags.ABILITY_TAG_SUSTAIN_CAN_KILL)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_WEAPON
ITEM.icon = Vector:new(8, 8)
ITEM.attackClass = ATTACK_WEAPON.SWING_AND_DAMAGE
ITEM:setToStatsBase({ [Tags.STAT_ATTACK_DAMAGE_BASE] = 21, [Tags.STAT_ATTACK_DAMAGE_VARIANCE] = Common.getVarianceForRatio(1), [Tags.STAT_VIRTUAL_RATIO] = 0.0, [Tags.STAT_ABILITY_POWER] = 2.5, [Tags.STAT_ABILITY_BUFF_DURATION] = 3, [Tags.STAT_ABILITY_SUSTAIN_MODE] = Tags.SUSTAIN_MODE_FULL, [Tags.STAT_ABILITY_DAMAGE_BASE] = 21, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(1) })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_BUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_BUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "{C:KEYWORD}Sustain %s - Deal %s damage to " .. "all adjacent targets."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_BUFF_DURATION, Tags.STAT_ABILITY_DAMAGE_MIN)
end
ABILITY.icon = Vector:new(7, 8)
ABILITY.iconColor = COLORS.STANDARD_STEEL
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    local source = entity.body:getPosition()
    for direction in DIRECTIONS_AA() do
        castingGuide:indicate(source + Vector[direction])
    end

end
ABILITY.directions = false
local TRIGGER = class(TRIGGERS.END_OF_TURN)
function TRIGGER:process(currentEvent)
    local source = self.entity.body:getPosition()
    for direction in DIRECTIONS_AA() do
        local hit = self.entity.hitter:createHit()
        hit:setDamageFromAbilityStats(Tags.DAMAGE_TYPE_SPELL, self.abilityStats)
        hit:applyToPosition(currentEvent, source + Vector[direction])
    end

    return currentEvent
end

local BUFF = class(BUFFS.DEACTIVATOR)
ABILITY.buffClass = BUFF
function BUFF:initialize(duration, abilityStats, action)
    BUFF:super(self, "initialize", duration, abilityStats, action)
    self.triggerClasses:push(TRIGGER)
    self.expiresImmediately = true
end

function BUFF:decorateIncomingHit(hit)
    if self.abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 and hit:isDamageOrDebuff() then
        if hit:getApplyDistance() > 1 then
            hit:clear()
            hit.sound = "HIT_BLOCKED"
            hit.forceFlash = true
        end

    end

end

local FLIP_DIRECTION = MEASURES.FLIPPED_DIRECTIONS[1]
local ANGLE = math.tau * 0.375
local HOLD_DURATION = 0.2
local BRACE_DURATION = 0.2
local SWING_DURATION = 0.375
local SWING_MOVE_DISTANCE = 0.12
local SWING_ORIGIN_OFFSET = 0.375
local FADE_DURATION = 0.2
local EASING = require("draw.easing")
local ACTION = class("actions.action")
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("tackle")
    self.tackle.isDirectionHorizontal = true
    self.tackle.braceDistance = SWING_MOVE_DISTANCE
    self.tackle.forwardDistance = SWING_MOVE_DISTANCE
    self:addComponent("weaponswing")
    self.weaponswing.isDirectionHorizontal = true
    self.weaponswing.angleStart = ANGLE
    self.weaponswing.itemOffset = Vector.ORIGIN
    self.parallelEvent = false
    self.sound = false
    self:addComponent("outline")
    self.outline.color = ABILITY.iconColor
end

function ACTION:createSpinEvent()
    local currentEvent = self:createParallelEvent()
    self.weaponswing:createFadeTrail(currentEvent)
    self.parallelEvent = currentEvent:chainEvent(function(_, anchor)
        anchor:chainProgress(SWING_DURATION, function(progress)
            self.weaponswing:setAngle(ANGLE - math.tau * progress)
        end)
    end, SWING_DURATION)
end

function ACTION:deactivate(anchor)
    anchor:chainProgress(FADE_DURATION, function(progress)
        self.weaponswing.swingItem.opacity = 1 - progress
    end):chainEvent(function(currentTime)
        self.weaponswing:deleteSwingItem()
        self.weaponswing:stopFadeTrail(currentTime)
        self.parallelEvent:stop()
        self.sound:stop()
    end)
end

function ACTION:setFromLoad()
    self.weaponswing:createSwingItem()
    self.weaponswing.swingItem.originOffset = SWING_ORIGIN_OFFSET
    self:createSpinEvent()
    self.sound = Common.playSFX("WHIRLWIND")
end

function ACTION:process(currentEvent)
    self.weaponswing:createSwingItem()
    self.weaponswing.swingItem.originOffset = SWING_ORIGIN_OFFSET
    self.tackle:createOffset()
    Common.playSFX("WEAPON_CHARGE")
    self.outline:chainFadeIn(currentEvent, BRACE_DURATION + HOLD_DURATION)
    currentEvent = self.tackle:chainBraceEvent(currentEvent, BRACE_DURATION):chainProgress(HOLD_DURATION):chainEvent(function()
        self:createSpinEvent()
        self.sound = Common.playSFX("WHIRLWIND")
    end)
    currentEvent = self.tackle:chainForwardEvent(currentEvent, SWING_DURATION / 2)
    self.outline:chainFadeOut(currentEvent, SWING_DURATION / 2)
    currentEvent = self.tackle:chainBackEvent(currentEvent, SWING_DURATION / 2):chainEvent(function()
        self.tackle:deleteOffset()
    end)
    return currentEvent
end

local LEGENDARY = ITEM:createLegendary("Eye of the Storm")
LEGENDARY.abilityExtraLine = "While {C:KEYWORD}Sustaining, you are immune to any effect " .. "that did not come from an adjacent space."
LEGENDARY:setToStatsBase({ [Tags.STAT_ABILITY_DAMAGE_BASE] = 4.0, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = 0 })
LEGENDARY.modifyItem = function(item)
    item:markAltered(Tags.STAT_ABILITY_DAMAGE_MIN, Tags.STAT_UPGRADED)
    item:markAltered(Tags.STAT_ABILITY_DAMAGE_MAX, Tags.STAT_UPGRADED)
end
return ITEM

