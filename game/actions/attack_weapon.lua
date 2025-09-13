local ACTIONS = {  }
local Vector = require("utils.classes.vector")
local ActionUtils = require("actions.utils")
local ACTION_CONSTANTS = require("actions.constants")
local TRIGGERS = require("actions.triggers")
local EASING = require("draw.easing")
local Common = require("common")
local SWING_BRACE_DURATION = ACTION_CONSTANTS.DEFAULT_BRACE_DURATION
local SWING_BRACE_DISTANCE = ACTION_CONSTANTS.DEFAULT_BRACE_DISTANCE
local SWING_MOVE_DISTANCE = 0.35
local SWING_MOVE_HEIGHT = 0.11
local SWING_DURATION = 0.1
local SWING_HOLD_DURATION = 0.1
local SWING_BACK_DURATION = 0.05
ACTIONS.SWING = class(TRIGGERS.ON_ATTACK)
function ACTIONS.SWING:initialize(entity, direction, abilityStats)
    ACTIONS.SWING:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("weaponswing")
    self:addComponent("tackle")
    self:addComponent("jump")
    self.tackle.braceDistance = SWING_BRACE_DISTANCE
    self.tackle.forwardDistance = SWING_MOVE_DISTANCE
    self.jump.height = SWING_MOVE_HEIGHT
    self.swingDuration = SWING_DURATION
    self.braceDuration = SWING_BRACE_DURATION
    self.backDuration = SWING_BACK_DURATION
    self.holdDuration = SWING_HOLD_DURATION
    self.keepSwingItem = false
    self.pitchMultiplier = 1
    self.swingSound = "WHOOSH"
end

function ACTIONS.SWING:speedMultiply(factor)
    self.swingDuration = self.swingDuration / factor
    self.braceDuration = self.braceDuration / factor
    self.backDuration = self.backDuration / factor
    self.holdDuration = self.holdDuration / factor
    self.pitchMultiplier = self.pitchMultiplier * factor
end

function ACTIONS.SWING:prepare()
    self.entity.sprite:turnToDirection(self.direction)
    if self.entity.sprite.layer == Tags.LAYER_CHARACTER and (self.direction == LEFT or self.direction == RIGHT) then
        self.entity.sprite.layer = Tags.LAYER_ABOVE_EFFECTS
    end

    self.tackle:createOffset()
    self.weaponswing:createSwingItem()
end

function ACTIONS.SWING:chainBraceEvent(currentEvent)
    return self.tackle:chainBraceEvent(currentEvent, self.braceDuration)
end

function ACTIONS.SWING:chainMainSwingEvent(currentEvent)
    self.weaponswing:chainSwingEvent(currentEvent, self.swingDuration)
    self.jump:chainFullEvent(currentEvent, self.swingDuration)
    return self.tackle:chainForwardEvent(currentEvent, self.swingDuration)
end

function ACTIONS.SWING:chainHoldEvent(currentEvent)
    return currentEvent:chainProgress(self.holdDuration)
end

function ACTIONS.SWING:chainBackEvent(currentEvent)
    return self.tackle:chainBackEvent(currentEvent, self.backDuration):chainEvent(function()
        if not self.keepSwingItem then
            self.weaponswing:deleteSwingItem()
        end

        self.tackle:deleteOffset()
    end)
end

function ACTIONS.SWING:process(currentEvent)
    self:prepare()
    currentEvent = self:chainBraceEvent(currentEvent):chainEvent(function()
        if self.swingSound then
            Common.playSFX(self.swingSound, self.pitchMultiplier)
        end

    end)
    currentEvent = self:chainMainSwingEvent(currentEvent)
    self:chainBackEvent(self:chainHoldEvent(currentEvent))
    return currentEvent
end

ACTIONS.SWING_AND_DAMAGE = ActionUtils.actionWithMeleeDamage(ACTIONS.SWING)
ACTIONS.STAB = class(ACTIONS.SWING)
local STAB_NORMAL_DISTANCE = SWING_MOVE_DISTANCE + 0.04
function ACTIONS.STAB:initialize(entity, direction, abilityStats)
    ACTIONS.STAB:super(self, "initialize", entity, direction, abilityStats)
    self.weaponswing.angleStart = 0
    self.tackle.forwardDistance = STAB_NORMAL_DISTANCE
end

ACTIONS.STAB_AND_DAMAGE = ActionUtils.actionWithMeleeDamage(ACTIONS.STAB)
ACTIONS.STAB_EXTENDED = class(ACTIONS.STAB)
local STAB_EXTENDED_EXTRA_DISTANCE = 0.35
local STAB_EXTENDED_ITEM_OFFSET = 0.15
function ACTIONS.STAB_EXTENDED:initialize(entity, direction, abilityStats)
    ACTIONS.STAB_EXTENDED:super(self, "initialize", entity, direction, abilityStats)
    local originalDistance = self.tackle.forwardDistance
    self.tackle.forwardDistance = self.tackle.forwardDistance + STAB_EXTENDED_EXTRA_DISTANCE
    local braceDistance = self.tackle.braceDistance
    local ratio = ((self.tackle.forwardDistance + braceDistance) / (originalDistance + braceDistance))
    ratio = (ratio + 1) / 2
    self.jump.height = self.jump.height * ratio
    self.swingDuration = self.swingDuration * ratio
    self.backDuration = self.backDuration * ratio
    self.holdDuration = self.holdDuration * ratio
end

function ACTIONS.STAB_EXTENDED:prepare()
    ACTIONS.STAB_EXTENDED:super(self, "prepare")
    self.tackle.offset.disableModY = true
end

function ACTIONS.STAB_EXTENDED:chainMainSwingEvent(event)
    event:chainProgress(self.swingDuration, function(progress)
        self.weaponswing.swingItem.originOffset = STAB_EXTENDED_ITEM_OFFSET * progress
    end, EASING.IN_OUT_QUAD)
    return ACTIONS.STAB_EXTENDED:super(self, "chainMainSwingEvent", event)
end

function ACTIONS.STAB_EXTENDED:chainBackEvent(event)
    event:chainProgress(self.backDuration, function(progress)
        self.weaponswing.swingItem.originOffset = STAB_EXTENDED_ITEM_OFFSET * (1 - progress)
    end)
    return ACTIONS.STAB_EXTENDED:super(self, "chainBackEvent", event)
end

ACTIONS.STAB_EXTENDED_AND_DAMAGE = ActionUtils.actionWithMeleeDamage(ACTIONS.STAB_EXTENDED)
function ACTIONS.STAB_EXTENDED_AND_DAMAGE:getTargetPosition(hit)
    return hit.sourcePosition + Vector[self.direction] * 2
end

return ACTIONS

