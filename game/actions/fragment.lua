local ACTIONS = {  }
local Vector = require("utils.classes.vector")
local Action = require("actions.action")
local ACTION_CONSTANTS = require("actions.constants")
local TRIGGERS = require("actions.triggers")
local ACTION_SWING = require("actions.attack_weapon").SWING
local Common = require("common")
local THROW_DURATION = 0.07
local THROW_DISTANCE = 0.25
local THROW_HOLD_DURATION = 0.1
local THROW_BACK_DURATION = 0.13
ACTIONS.THROW = class(Action)
function ACTIONS.THROW:initialize(entity, direction, abilityStats)
    ACTIONS.THROW:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("tackle")
    self.tackle.forwardDistance = THROW_DISTANCE
    self.sound = "THROW"
end

function ACTIONS.THROW:parallelResolve(anchor)
    self.tackle:createOffset()
end

function ACTIONS.THROW:process(currentEvent)
    self.entity.sprite:turnToDirection(self.direction)
    currentEvent:chainEvent(function()
        if self.sound then
            Common.playSFX(self.sound)
        end

    end)
    currentEvent = self.tackle:chainForwardEvent(currentEvent, THROW_DURATION)
    local afterHold = currentEvent:chainProgress(THROW_HOLD_DURATION)
    self.tackle:chainBackEvent(afterHold, THROW_BACK_DURATION):chainEvent(function()
        self.tackle:deleteOffset()
    end)
    return currentEvent
end

local FLASH_TIME_FAST = 0.21
local FLASH_TIME_SLOW = 0.32
ACTIONS.SHOW_ICON_SELF = class(Action)
function ACTIONS.SHOW_ICON_SELF:initialize(entity, direction, abilityStats)
    ACTIONS.SHOW_ICON_SELF:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("iconflash")
    self.flashTime = FLASH_TIME_SLOW
    self.icon = false
    self.color = false
end

function ACTIONS.SHOW_ICON_SELF:setToFast()
    self.flashTime = FLASH_TIME_FAST
end

function ACTIONS.SHOW_ICON_SELF:prepare()
    Utils.assert(self.icon and self.color, "SHOW_ICON_SELF requires icon and color")
    self.iconflash.icon = self.icon
    self.iconflash.color = self.color
end

function ACTIONS.SHOW_ICON_SELF:process(currentEvent)
    self:prepare()
    Common.playSFX("GLOW_MODAL")
    currentEvent = self.iconflash:chainFlashEvent(currentEvent, self.flashTime)
    self.iconflash:chainFadeEvent(currentEvent, self.flashTime)
    return currentEvent
end

ACTIONS.CAST = class(ACTION_SWING)
local CAST_CHARGE_DURATION = 0.15
local CAST_BRACE_DISTANCE = 0.12
local CAST_SWING_DURATION = 0.135
local CAST_POINT_IN_SWING = 0.4
function ACTIONS.CAST:initialize(entity, direction, abilityStats)
    ACTIONS.CAST:super(self, "initialize", entity, direction, abilityStats)
    self.weaponswing:setTrailToSubtle()
    self.jump.height = 0
    self:addComponent("outline")
    self.color = false
    self.tackle.braceDistance = CAST_BRACE_DISTANCE
    self.swingDuration = CAST_SWING_DURATION
    self.braceDuration = CAST_CHARGE_DURATION
    self.holdDuration = CAST_CHARGE_DURATION
    self.swingCastPoint = CAST_POINT_IN_SWING
    self.castPointEvent = false
    self.swingSound = "WHOOSH_MAGIC"
    self.chargeSound = "CAST_CHARGE"
end

function ACTIONS.CAST:chainBraceEvent(currentEvent)
    Common.playSFX(self.chargeSound)
    self.outline:chainFadeIn(currentEvent, self.braceDuration)
    return ACTIONS.CAST:super(self, "chainBraceEvent", currentEvent)
end

function ACTIONS.CAST:chainHoldEvent(currentEvent)
    self.outline:chainFadeOut(currentEvent, self.holdDuration)
    return ACTIONS.CAST:super(self, "chainHoldEvent", currentEvent)
end

function ACTIONS.CAST:chainMainSwingEvent(currentEvent)
    self.castPointEvent = currentEvent:chainProgress(self.swingDuration * self.swingCastPoint)
    return ACTIONS.CAST:super(self, "chainMainSwingEvent", currentEvent)
end

function ACTIONS.CAST:process(currentEvent)
    self.outline.color = self.color
    ACTIONS.CAST:super(self, "process", currentEvent)
    return self.castPointEvent
end

ACTIONS.CAST_PROJECTILE = class(ACTIONS.CAST)
function ACTIONS.CAST_PROJECTILE:initialize(entity, direction, abilityStats)
    ACTIONS.CAST_PROJECTILE:super(self, "initialize", entity, direction, abilityStats)
    self.projectilePrefab = false
end

function ACTIONS.CAST_PROJECTILE:process(currentEvent)
    return ACTIONS.CAST_PROJECTILE:super(self, "process", currentEvent):chainEvent(function(_, anchor)
        self.entity.projectilespawner:spawnSpecial(anchor, self.projectilePrefab, self.direction, self.abilityStats)
    end)
end

ACTIONS.GLOW_MODAL = class(Action)
function ACTIONS.GLOW_MODAL:initialize(entity, direction, abilityStats)
    ACTIONS.GLOW_MODAL:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("outline")
    self.outline.hasModal = true
    self.duration = ACTION_CONSTANTS.MAJOR_CAST_CHARGE_DURATION
    self.color = false
    self.sound = "GLOW_MODAL"
end

function ACTIONS.GLOW_MODAL:process(currentEvent)
    self.outline.color = self.color
    if self.sound then
        Common.playSFX(self.sound)
    end

    return self.outline:chainFullEvent(currentEvent, self.duration)
end

local ENCHANT_ANGLE = math.tau * 0.25
local ENCHANT_ITEM_OFFSET = Vector:new(0.36, 0.21)
local ENCHANT_DURATION = 0.35
ACTIONS.ENCHANT = class("actions.action")
function ACTIONS.ENCHANT:initialize(entity, direction, abilityStats)
    ACTIONS.ENCHANT:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("outline")
    self.color = false
    self:addComponent("weaponswing")
    self.weaponswing.angleStart = ENCHANT_ANGLE
    self.weaponswing.angleEnd = ENCHANT_ANGLE
    self.weaponswing.isDirectionHorizontal = true
    self.weaponswing.itemOffset = ENCHANT_ITEM_OFFSET
    self.outline.hasModal = true
    self.manualFadeOut = false
    self.duration = ENCHANT_DURATION
    self.sound = "ENCHANT"
end

function ACTIONS.ENCHANT:speedMultiply(factor)
    self.duration = self.duration * factor
end

function ACTIONS.ENCHANT:fadeOut(currentEvent)
    return self.outline:chainFadeOut(currentEvent, self.duration):chainEvent(function()
        self.weaponswing:deleteSwingItem()
    end)
end

function ACTIONS.ENCHANT:process(currentEvent)
    self.weaponswing:createSwingItem()
    self.outline.color = self.color
    Common.playSFX(self.sound)
    currentEvent = self.outline:chainFadeIn(currentEvent, self.duration)
    if not self.manualFadeOut then
        self:fadeOut(currentEvent)
    end

    return currentEvent
end

local DEFAULT_STEP_DURATION = ACTION_CONSTANTS.WALK_DURATION * 0.9
ACTIONS.TRAIL_MOVE = class(Action)
function ACTIONS.TRAIL_MOVE:initialize(entity, direction, abilityStats)
    ACTIONS.TRAIL_MOVE:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("move")
    self:addComponent("charactertrail")
    self:addComponent("jump")
    self.stepDuration = DEFAULT_STEP_DURATION
    self.distance = 1
    self.onStep = false
    self.preStep = false
    self.soundPitch = 1
    self.disableSound = false
end

function ACTIONS.TRAIL_MOVE:setJumpHeight(jumpHeight)
    self:addComponent("jump")
    self.jump.height = jumpHeight
end

function ACTIONS.TRAIL_MOVE:parallelResolve(currentEvent)
    self.entity.sprite:turnToDirection(self.direction)
    self.move.distance = self.distance
    self.move:prepare(currentEvent)
end

function ACTIONS.TRAIL_MOVE:process(currentEvent)
    self.charactertrail:start(currentEvent)
    if not self.disableSound then
        currentEvent:chainEvent(function()
            Common.playSFX(self.move:getDashSound(), self.soundPitch)
        end)
    end

    if self:hasComponent("jump") then
        self.jump:chainFullEvent(currentEvent, self.distance * self.stepDuration)
    end

    return self.move:chainMoveEvent(currentEvent, self.distance * self.stepDuration, self.onStep, self.preStep):chainEvent(function()
        self.charactertrail:stop()
    end)
end

ACTIONS.EXPLOSIVE_HIT = class("actions.hit")
local HIT_DURATION = 0.55
function ACTIONS.EXPLOSIVE_HIT:initialize(entity, direction, abilityStats)
    ACTIONS.EXPLOSIVE_HIT:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("explosion")
    self.explosion:setArea(Tags.ABILITY_AREA_SINGLE)
    self.explodeDuration = HIT_DURATION
    self.sound = "EXPLOSION_SMALL"
    self.soundPitch = 1
end

function ACTIONS.EXPLOSIVE_HIT:parallelResolve(anchor)
    ACTIONS.EXPLOSIVE_HIT:super(self, "parallelResolve", anchor)
    if self.abilityStats and self.abilityStats:hasKey(Tags.STAT_ABILITY_AREA_ROUND) then
        self.explosion:setArea(self.abilityStats:get(Tags.STAT_ABILITY_AREA_ROUND))
    end

    if self.hit then
        self.hit.sound = false
    end

end

function ACTIONS.EXPLOSIVE_HIT:process(currentEvent)
    currentEvent = ACTIONS.EXPLOSIVE_HIT:super(self, "process", currentEvent)
    if self:isVisible(self.targetPosition) then
        if self.sound then
            Common.playSFX(self.sound, self.soundPitch)
        end

        local parallelEvent = self:createParallelEvent()
        self.explosion.source = self.targetPosition
        self.explosion:chainFullEvent(parallelEvent, self.explodeDuration)
    end

    return currentEvent
end

return ACTIONS

