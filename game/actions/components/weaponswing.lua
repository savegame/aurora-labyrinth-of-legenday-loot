local WeaponSwing = class("actions.components.component")
local Vector = require("utils.classes.vector")
local ActionUtils = require("actions.utils")
local ACTION_CONSTANTS = require("actions.constants")
local MEASURES = require("draw.measures")
local EASING = require("draw.easing")
local DEFAULT_ITEM_OFFSET = Vector:new(0.29, 0.13)
local DEFAULT_SWING_ANGLE_START = math.tau * 0.375
local TRAIL_OPACITY = 0.5
local TRAIL_OPACITY_LINGERING = 0.75
local TRAIL_OPACITY_SUBTLE = 0.25
local TRAIL_FADE_SPEED = 3
local TRAIL_FADE_REPEAT = 0.005
function WeaponSwing:initialize(action)
    WeaponSwing:super(self, "initialize", action)
    self.angleStart = DEFAULT_SWING_ANGLE_START
    self.angleEnd = 0
    self.weaponSilhouette = false
    self.trailSilhouette = false
    self.icon = false
    self.itemOffset = DEFAULT_ITEM_OFFSET
    self.isDirectionHorizontal = false
    self._trailOpacity = TRAIL_OPACITY
    self.swingItem = false
    self.fadeTrail = false
    self.isOriginPosition = false
    self.followSpriteFrame = true
    self.layer = false
end

function WeaponSwing:setSilhouetteColor(color)
    self.weaponSilhouette = color
    self.trailSilhouette = color
end

function WeaponSwing:setTrailToLingering()
    self._trailOpacity = TRAIL_OPACITY_LINGERING
end

function WeaponSwing:setTrailToSubtle()
    self._trailOpacity = TRAIL_OPACITY_SUBTLE
end

function WeaponSwing:setAngles(angleStart, angleEnd)
    self.angleStart = angleStart
    self.angleEnd = angleEnd
end

function WeaponSwing:createSwingItem()
    local entity = self.action.entity
    local swingItem = self:createEffect("swing_item")
    if entity:getIfHasComponent("sprite", "frameType") == Tags.FRAME_ANIMATED then
        entity.sprite.frameType = Tags.FRAME_WEAPONLESS
    end

    swingItem.icon = self.icon or entity.melee:evaluateSwingIcon()
    if self.isOriginPosition then
        swingItem.position = entity.body:getPosition()
    else
        swingItem.position = entity.sprite
    end

    if self.isDirectionHorizontal then
        swingItem.direction = MEASURES.toHorizontalDirection(entity.sprite.direction)
    else
        swingItem.direction = entity.sprite.direction
    end

    swingItem.offset = self.itemOffset
    swingItem.angle = self.angleStart
    if self.weaponSilhouette then
        swingItem:setSilhouetteColor(self.weaponSilhouette)
    end

    swingItem.followSpriteFrame = self.followSpriteFrame
    if self.layer then
        swingItem.layer = self.layer
    end

    self.swingItem = swingItem
    return swingItem
end

function WeaponSwing:createFadeTrail(currentEvent)
    local fadeTrail = self:createEffect("fade_trail")
    fadeTrail.effect = self.swingItem
    fadeTrail.fadeSpeed = TRAIL_FADE_SPEED
    fadeTrail.initialOpacity = self._trailOpacity
    if self.trailSilhouette then
        fadeTrail.silhouetteColor = self.trailSilhouette
    end

    self.fadeTrail = fadeTrail
    if self.layer then
        fadeTrail.layer = self.layer
    end

    return fadeTrail:chainTrailEvent(currentEvent, TRAIL_FADE_REPEAT)
end

function WeaponSwing:stopFadeTrail(currentTime)
    self.fadeTrail:stopTrailEvent(currentTime)
end

function WeaponSwing:chainSwingEvent(currentEvent, duration)
    return currentEvent:chainEvent(function(_, currentEvent)
        self:createFadeTrail(currentEvent)
    end):chainProgress(duration, function(progress)
        self.swingItem.angle = self.angleStart + (self.angleEnd - self.angleStart) * progress
    end, EASING.IN_OUT_QUAD):chainEvent(function(currentTime)
        self:stopFadeTrail(currentTime)
    end)
end

function WeaponSwing:createAtEnd()
    self:createSwingItem()
    self.swingItem.angle = self.angleEnd
end

function WeaponSwing:setAngle(angle)
    self.swingItem.angle = angle
end

function WeaponSwing:deleteSwingItem()
    self.swingItem:delete()
    local entity = self.action.entity
    if entity:getIfHasComponent("sprite", "frameType") == Tags.FRAME_WEAPONLESS then
        entity.sprite.frameType = Tags.FRAME_ANIMATED
    end

end

return WeaponSwing

