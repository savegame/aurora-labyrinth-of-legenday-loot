local ACTIONS = {  }
local Vector = require("utils.classes.vector")
local COLORS = require("draw.colors")
local Common = require("common")
local ACTION_CONSTANTS = require("actions.constants")
local ACTIONS_FRAGMENT = require("actions.fragment")
local TELEPORT_SPRITE_FADE = 0.28
local TELEPORT_OUTLINE_FADE = 0.25
ACTIONS.BUFF_TELEPORT_IMMUNE = class("structures.buff")
function ACTIONS.BUFF_TELEPORT_IMMUNE:initialize()
    ACTIONS.BUFF_TELEPORT_IMMUNE:super(self, "initialize", 1)
    self.expiresImmediately = true
end

function ACTIONS.BUFF_TELEPORT_IMMUNE:shouldCombine()
    return false
end

function ACTIONS.BUFF_TELEPORT_IMMUNE:decorateIncomingHit(hit)
    if not hit.sourceEntity:hasComponent("steppable") then
        hit:clear()
    end

end

ACTIONS.TELEPORT = class("actions.action")
function ACTIONS.TELEPORT:initialize(entity, direction, abilityStats)
    ACTIONS.TELEPORT:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("outline")
    self.outline:setIsFull()
    self:addComponent("charactereffects")
    self.outline.color = COLORS.STANDARD_PSYCHIC
    self:addComponent("move")
    self.move:setEasingToLinear()
    self.move.interimSkipTriggers = true
    self.move.interimSkipProjectiles = true
    self.spriteFadeDuration = TELEPORT_SPRITE_FADE
    self.outlineFadeDuration = TELEPORT_OUTLINE_FADE
    self.moveTo = false
    self.outlineCharacter = false
end

function ACTIONS.TELEPORT:speedMultiply(factor)
    self.spriteFadeDuration = self.spriteFadeDuration * factor
    self.outlineFadeDuration = self.outlineFadeDuration * factor
end

function ACTIONS.TELEPORT:postCharacterMove(currentEvent)
end

function ACTIONS.TELEPORT:postEntityMove(currentEvent)
end

function ACTIONS.TELEPORT:prepareMove(currentEvent)
    self.move.moveTo = self.moveTo
    self.move:prepare(currentEvent)
end

function ACTIONS.TELEPORT:process(currentEvent)
    self.entity.buffable:forceApply(ACTIONS.BUFF_TELEPORT_IMMUNE:new())
    self.charactereffects:chainFadeOutSprite(currentEvent, self.spriteFadeDuration)
    self.outlineCharacter = self.entity.sprite:createCharacterCopy()
    self.outlineCharacter.sprite.opacity = 0
    self.outline:setEntity(self.outlineCharacter)
    Common.playSFX("TELEPORT")
    currentEvent = self.outline:chainFadeIn(currentEvent, self.spriteFadeDuration)
    self:prepareMove(currentEvent)
    self.move:chainMoveEvent(currentEvent, self.outlineFadeDuration * 2, function(anchor, previous, target)
        if target == self.moveTo then
            self.entity.buffable:delete(anchor, ACTIONS.BUFF_TELEPORT_IMMUNE, true)
        end

    end)
    currentEvent = self.outline:chainFadeOut(currentEvent, self.outlineFadeDuration):chainEvent(function(_, anchor)
        self.outlineCharacter.position:setPosition(self.moveTo)
        self:postCharacterMove(anchor)
    end)
    currentEvent = self.outline:chainFadeIn(currentEvent, self.outlineFadeDuration):chainEvent(function(_, anchor)
        self:postEntityMove(anchor)
    end)
    self.charactereffects:chainFadeInSprite(currentEvent, self.spriteFadeDuration)
    currentEvent = self.outline:chainFadeOut(currentEvent, self.spriteFadeDuration):chainEvent(function(_, anchor)
        self.outlineCharacter:delete()
    end)
    return currentEvent
end

ACTIONS.WEAPON_CLEAVE = class("actions.action")
local CLEAVE_SWING_DURATION_3 = 0.2
local CLEAVE_SWING_DURATION_5 = 0.3
local CLEAVE_SWING_DURATION_7 = 0.4
local CLEAVE_SWING_DURATION_8 = 0.45
local CLEAVE_FORWARD_DURATION = 0.14
local CLEAVE_FORWARD_DISTANCE = 0.25
local CLEAVE_ORIGIN_OFFSET = 0.45
local CLEAVE_SWING_WAIT = 0.1
function ACTIONS.WEAPON_CLEAVE:initialize(entity, direction, abilityStats)
    ACTIONS.WEAPON_CLEAVE:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("weaponswing")
    self.weaponswing:setTrailToLingering()
    self.weaponswing.isOriginPosition = true
    self.weaponswing.itemOffset = Vector.ORIGIN
    self:addComponent("cleaveorder")
    self:addComponent("tackle")
    self.tackle.forwardDistance = CLEAVE_FORWARD_DISTANCE
    self.forwardDuration = CLEAVE_FORWARD_DURATION
end

function ACTIONS.WEAPON_CLEAVE:affectPosition(anchor, position)
    local hit = self.entity.hitter:createHit()
    hit:setDamageFromAbilityStats(Tags.DAMAGE_TYPE_SPELL, self.abilityStats)
    hit:applyToPosition(anchor, position)
end

function ACTIONS.WEAPON_CLEAVE:getSwingDuration(area)
            if area <= 3 then
        return CLEAVE_SWING_DURATION_3
    elseif area == 5 then
        return CLEAVE_SWING_DURATION_5
    elseif area == 7 then
        return CLEAVE_SWING_DURATION_7
    else
        return CLEAVE_SWING_DURATION_8
    end

end

function ACTIONS.WEAPON_CLEAVE:process(currentEvent)
    self.entity.sprite:turnToDirection(self.direction)
    self.tackle:createOffset()
    self.cleaveorder.area = self.abilityStats:get(Tags.STAT_ABILITY_AREA_CLEAVE)
    local swingDuration = self:getSwingDuration(self.cleaveorder.area)
    self.weaponswing:setAngles(self.cleaveorder:getAngles())
    self.tackle:chainForwardEvent(currentEvent, self.forwardDuration)
    currentEvent = currentEvent:chainProgress(self.forwardDuration / 2):chainEvent(function()
        Common.playSFX("CLEAVE", CLEAVE_SWING_DURATION_7 / swingDuration)
        self.weaponswing:createSwingItem()
        self.weaponswing.swingItem.originOffset = CLEAVE_ORIGIN_OFFSET
    end)
    self.cleaveorder:chainHitEvent(currentEvent, swingDuration, function(anchor, position)
        self:affectPosition(anchor, position)
    end)
    currentEvent = self.weaponswing:chainSwingEvent(currentEvent, swingDuration):chainProgress(CLEAVE_SWING_WAIT)
    return self.tackle:chainBackEvent(currentEvent, self.forwardDuration):chainEvent(function()
        self.weaponswing:deleteSwingItem()
        self.tackle:deleteOffset()
    end)
end

ACTIONS.BEAM = class(ACTIONS_FRAGMENT.CAST)
local BEAM_TRAVEL_DURATION = 0.03
local BEAM_GLOW_PULSE_DURATION = 0.35
local BEAM_GLOW_PULSE_MIN = 0.5
local BEAM_GLOW_PULSE_MAX = 1
local BEAM_GLOW_FADE_OUT = 0.5
function ACTIONS.BEAM:initialize(entity, direction, abilityStats)
    ACTIONS.BEAM:super(self, "initialize", entity, direction, abilityStats)
    self.tackle.forwardDistance = self.tackle.forwardDistance / 2
    self:speedMultiply(ACTION_CONSTANTS.SLOW_CAST_MULTIPLIER)
    self.beamColor = false
end

function ACTIONS.BEAM:hitTarget(anchor, target)
end

function ACTIONS.BEAM:chainBackEvent(currentEvent)
end

function ACTIONS.BEAM:process(currentEvent)
    if self.direction == UP then
        self.entity.sprite.layer = Tags.LAYER_ABOVE_EFFECTS
    end

    currentEvent = ACTIONS.BEAM:super(self, "process", currentEvent):chainEvent(function()
        Common.playSFX("BEAM")
    end)
    local entity = self.entity
    local source = entity.body:getPosition()
    local vDirection = Vector[self.direction]
    local endPosition = source + vDirection
    while entity.body:canBePassable(endPosition) do
        endPosition = endPosition + vDirection
    end

    local effect = self:createEffect("lightning", source, endPosition, true)
    effect.color = self.beamColor
    effect.glowOpacity = (BEAM_GLOW_PULSE_MIN + BEAM_GLOW_PULSE_MAX) / 2
    effect.thickness = 4
    local glowEvent = currentEvent:chainEvent(function(_, anchor)
        anchor:chainProgress(BEAM_GLOW_PULSE_DURATION, function(progress)
            effect.glowOpacity = (math.sin(math.tau * progress) / 2 + 0.5) * (BEAM_GLOW_PULSE_MAX - BEAM_GLOW_PULSE_MIN) + BEAM_GLOW_PULSE_MIN
        end)
    end, BEAM_GLOW_PULSE_DURATION)
    currentEvent:chainProgress(BEAM_TRAVEL_DURATION * source:distanceManhattan(endPosition), function(progress)
        effect.lineProgress = progress
    end)
    for i = 1, source:distanceManhattan(endPosition) do
        local target = source + vDirection * i
        currentEvent = currentEvent:chainProgress(BEAM_TRAVEL_DURATION):chainEvent(function(_, anchor)
            self:hitTarget(anchor, target)
        end)
    end

    currentEvent = currentEvent:chainEvent(function(_, anchor)
        glowEvent:stop()
    end)
    currentEvent = currentEvent:chainProgress(BEAM_GLOW_PULSE_DURATION)
    currentEvent:chainProgress(BEAM_GLOW_FADE_OUT, function(progress)
        effect.opacity = 1 - progress
    end):chainEvent(function()
        effect:delete()
    end)
    ACTIONS.BEAM:super(self, "chainBackEvent", currentEvent)
    return currentEvent
end

return ACTIONS

