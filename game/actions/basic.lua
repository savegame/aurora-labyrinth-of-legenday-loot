local ACTIONS = {  }
local Vector = require("utils.classes.vector")
local BUFFS = require("definitions.buffs")
local Action = require("actions.action")
local ACTIONS_FRAGMENT = require("actions.fragment")
local ACTION_CONSTANTS = require("actions.constants")
local TRIGGERS = require("actions.triggers")
local COLORS = require("draw.colors")
local Common = require("common")
local TERMS = require("text.terms")
ACTIONS.MOVE = class(Action)
function ACTIONS.MOVE:initialize(entity, direction, abilityStats)
    ACTIONS.MOVE:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("move")
    self:addComponent("charactertrail")
    self.move:setEasingToLinear()
    self.stepDuration = ACTION_CONSTANTS.WALK_DURATION
    self.entity.buffable:decorateBasicMove(self)
    if self.entity:hasComponent("equipment") then
        self.entity.equipment:decorateBasicMove(self)
    end

end

function ACTIONS.MOVE:setToQuick()
    ACTIONS.MOVE:super(self, "setToQuick")
    self.move:setEasingToIOQuad()
    self.stepDuration = ACTION_CONSTANTS.WALK_DURATION * 0.75
end

function ACTIONS.MOVE:checkParallel()
    return true
end

function ACTIONS.MOVE:stopNextParallel()
    local moveFrom = self.entity.body:getPosition()
    local result = self.entity.triggers:hasActionsForTrigger(TRIGGERS.PRE_MOVE, self.direction, { moveFrom = moveFrom, moveTo = moveFrom + Vector[self.direction] })
    return result
end

function ACTIONS.MOVE:parallelResolve(anchor)
    self.entity.sprite:turnToDirection(self.direction)
    self.move:prepare(anchor)
    local movementSlow = self.entity.stats:get(Tags.STAT_MOVEMENT_SLOW, 0)
    if movementSlow > 0 then
        self.entity.buffable:apply(BUFFS:get("IMMOBILIZE_HIDDEN"):new(movementSlow))
    end

end

function ACTIONS.MOVE:process(currentEvent)
    local entity = self.entity
    local moveFrom = entity.body:getPosition()
    local visible = entity.sprite:isPositionVisible(moveFrom)
    visible = visible or entity.sprite:isPositionVisible(moveFrom + Vector[self.direction])
        if not visible then
        self.stepDuration = 0
    elseif self:isQuick() then
        if entity:hasComponent("player") then
            Common.playSFX("DASH_SHORT")
        end

        self.charactertrail:start(currentEvent)
    end

    return self.move:chainMoveEvent(currentEvent, self.stepDuration):chainEvent(function(_, anchor)
        self.charactertrail:stop(anchor)
    end)
end

ACTIONS.MOVE_PROJECTILE = class(Action)
function ACTIONS.MOVE_PROJECTILE:initialize(entity, direction, abilityStats)
    ACTIONS.MOVE_PROJECTILE:super(self, "initialize", entity, direction, abilityStats)
    self.speed = false
end

function ACTIONS.MOVE_PROJECTILE:process(currentEvent)
    local projectile = self.entity.projectile
    local direction = self.direction
    local actualSpeed = self.speed or projectile.speed
    if isDiagonal(direction) then
        actualSpeed = round(actualSpeed / math.sqrtOf2)
    end

    local stepDuration = ACTION_CONSTANTS.WALK_DURATION / actualSpeed
    local moveFrom = projectile.position
    if projectile.targetDirection then
        local angleFrom = Vector.ORIGIN:angleTo(Vector[projectile.direction])
        local angleTo = Vector.ORIGIN:angleTo(Vector[projectile.targetDirection])
        local diff = Utils.angleDifference(angleTo, angleFrom)
        currentEvent:chainProgress(ACTION_CONSTANTS.WALK_DURATION, function(progress)
            projectile.angle = (diff * progress + angleFrom) % math.tau
        end):chainEvent(function()
            projectile.direction = projectile.targetDirection
            projectile.targetDirection = false
            projectile.angle = false
        end)
    end

    for i = 1, actualSpeed do
        local thisDistance = i
        currentEvent = currentEvent:chainProgress(stepDuration, function(progress)
            if not projectile.hasHit then
                projectile.position = moveFrom + Vector[direction] * (thisDistance - 1 + progress)
                local target = moveFrom + Vector[direction] * thisDistance
                if not projectile:isPassable(target) then
                    projectile.stencilPosition = target
                else
                    projectile.stencilPosition = false
                end

            end

        end):chainEvent(function(_, anchor)
            projectile.drawBelow = false
            if not projectile.hasHit then
                local target = moveFrom + Vector[direction] * thisDistance
                if not projectile:isPassable(target) then
                    projectile:callOnHit(anchor, target, false)
                    projectile.stencilPosition = target
                else
                    projectile.stencilPosition = false
                end

            end

        end)
    end

    return currentEvent
end

ACTIONS.WAIT = class(Action)
function ACTIONS.WAIT:initialize(entity, direction, abilityStats)
    ACTIONS.WAIT:super(self, "initialize", entity, direction, abilityStats)
end

function ACTIONS.WAIT:checkParallel()
    return true
end

function ACTIONS.WAIT:process(currentEvent)
    return currentEvent
end

ACTIONS.WAIT_PLAYER = class(Action)
function ACTIONS.WAIT_PLAYER:process(currentEvent)
    return currentEvent
end

ACTIONS.WAIT_IMMOBILIZED = class(ACTIONS.WAIT_PLAYER)
function ACTIONS.WAIT_IMMOBILIZED:process(currentEvent)
    self.entity.publisher:publish(Tags.UI_ABILITY_INVALID_DIRECTION, TERMS.INVALID_DIRECTION_IMMOBILIZED)
    return ACTIONS.WAIT_IMMOBILIZED:super(self, "process", currentEvent)
end

ACTIONS.FOUNTAIN_RESTORE = class(Action)
function ACTIONS.FOUNTAIN_RESTORE:process(currentEvent)
    local hit = self.entity.hitter:createHit()
    hit:setHealing(self.entity.mana:getMax(), false)
    hit.affectsMana = true
    hit:applyToEntity(currentEvent, self.entity)
    return currentEvent:chainProgress(ACTION_CONSTANTS.STANDARD_FLASH_DURATION)
end

ACTIONS.DEFAULT_MODE_CANCEL = class("actions.action")
function ACTIONS.DEFAULT_MODE_CANCEL:initialize(entity, direction, abilityStats)
    ACTIONS.DEFAULT_MODE_CANCEL:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("outline")
    self.outline.color = COLORS.ABILITY_MODE_DEACTIVATE:withAlpha(1)
    self:setToQuick()
end

function ACTIONS.DEFAULT_MODE_CANCEL:process(currentEvent)
    Common.playSFX("CAST_CANCEL")
    return self.outline:chainFullEvent(currentEvent, ACTION_CONSTANTS.MINOR_CAST_CHARGE_DURATION):chainEvent(function(_, anchor)
        self.entity.equipment:deactivateSlot(anchor, self.abilityStats:get(Tags.STAT_SLOT))
    end)
end

ACTIONS.WAIT_MODE_CANCEL = class(ACTIONS.WAIT_PLAYER)
function ACTIONS.WAIT_MODE_CANCEL:initialize(entity, direction, abilityStats)
    ACTIONS.WAIT_MODE_CANCEL:super(self, "initialize", entity, direction, abilityStats)
    self:setToQuick()
end

function ACTIONS.WAIT_MODE_CANCEL:process(currentEvent)
    return ACTIONS.WAIT_MODE_CANCEL:super(self, "process", currentEvent):chainEvent(function(_, anchor)
        self.entity.equipment:deactivateSlot(anchor, self.abilityStats:get(Tags.STAT_SLOT))
    end)
end

ACTIONS.DIE = class(Action)
function ACTIONS.DIE:initialize(entity, direction, abilityStats)
    ACTIONS.DIE:super(self, "initialize", entity, direction, abilityStats)
    self.duration = ACTION_CONSTANTS.NEGATIVE_FADE_DURATION
    self.position = false
    self.killer = false
    self.killingHit = false
end

function ACTIONS.DIE:parallelResolve(anchor)
    self.position = self.entity.body:getPosition()
    self.entity.body:removeFromGrid()
end

function ACTIONS.DIE:spawnRewards()
    self.entity.tank:spawnDeathRewards(self.position)
end

function ACTIONS.DIE:process(currentEvent)
    local entity = self.entity
    if entity:hasComponent("tank") then
        self:spawnRewards()
    end

    entity.charactereffects.negativeOverlay = 1
    entity.sprite.opacity = 0
    if not entity.sprite:isVisible() then
        self.duration = 0
    end

    return currentEvent:chainProgress(self.duration):chainEvent(function()
        Common.getPositionComponent(entity):removeFromGrid()
        entity.sprite.isRemoved = true
        if entity:hasComponent("caster") then
            entity.caster.preparedAction = false
        end

        entity:callIfHasComponent("indicator", "removeFromGrid")
    end)
end

ACTIONS.DESTROY_ANVIL = class(Action)
function ACTIONS.DESTROY_ANVIL:initialize(entity, direction, abilityStats)
    ACTIONS.DESTROY_ANVIL:super(self, "initialize", entity, direction, abilityStats)
    self.anvil = false
end

function ACTIONS.DESTROY_ANVIL:process(currentEvent)
    self.anvil.tank:kill(currentEvent)
    return currentEvent:chainProgress(ACTION_CONSTANTS.NEGATIVE_FADE_DURATION)
end

local WAIT_EQUIP = 0.33
ACTIONS.EQUIP = class("actions.action")
function ACTIONS.EQUIP:initialize(entity, direction, abilityStats)
    ACTIONS.EQUIP:super(self, "initialize", entity, direction, abilityStats)
    self.itemEntity = false
    self.cancelAction = false
    self:setToQuick()
end

function ACTIONS.EQUIP:setItemEntity(itemEntity)
    self.itemEntity = itemEntity
    local equipment = self.entity.equipment
    local slot = self.itemEntity.item.item:getSlot()
    if equipment:isSlotActive(slot) then
        local ability = equipment:getAbility(slot)
        local abilityStats = equipment:getSlotStats(slot)
        self.cancelAction = self.entity.actor:create(ability.modeCancelClass, self.entity.sprite.direction, abilityStats)
    else
        self.cancelAction = false
    end

    if not self.cancelAction or self.cancelAction:isQuick() then
        self:setToQuick()
    else
        self.abilityStats:deleteKey(Tags.STAT_ABILITY_QUICK)
    end

end

function ACTIONS.EQUIP:shouldDeleteOriginal()
    return not self.entity.equipment:get(self.itemEntity.item.item:getSlot())
end

function ACTIONS.EQUIP:process(currentEvent)
    local item = self.itemEntity.item.item
    local slot = item:getSlot()
    local entity = self.entity
    if self.cancelAction then
        currentEvent = self.cancelAction:parallelChainEvent(currentEvent)
    end

    local previousItem = entity.equipment:get(slot)
    local shouldDelete = self:shouldDeleteOriginal()
    entity.equipment:equip(item)
    entity.publisher:publish(Tags.UI_ITEM_EQUIP, item)
    if not shouldDelete then
        self.itemEntity.item.item = previousItem
        self.itemEntity.stepinteractive:uninteract()
    else
        self.itemEntity:delete()
    end

    if slot == Tags.SLOT_AMULET then
        entity.charactereffects.negativeOverlay = 1
    end

    return currentEvent
end

ACTIONS.EQUIP_FINAL = class(ACTIONS.EQUIP)
function ACTIONS.EQUIP_FINAL:initialize(entity, direction, abilityStats)
    ACTIONS.EQUIP_FINAL:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("lightningspawner")
    self.lightningspawner.color = COLORS.STANDARD_GHOST
    self.lightningspawner.lightningCount = 4
end

function ACTIONS.EQUIP_FINAL:shouldDeleteOriginal()
    return true
end

function ACTIONS.EQUIP_FINAL:process(currentEvent)
    currentEvent = ACTIONS.EQUIP_FINAL:super(self, "process", currentEvent)
    local directions = DIRECTIONS_AA:shuffle(self:getLogicRNG())
    local entity = self.entity
    for direction in directions() do
        local target = entity.body:getPosition() + Vector[direction] * 2
        if entity.body:canBePassable(target) then
            currentEvent:chainEvent(function()
                Common.playSFX("LIGHTNING")
            end)
            return self.lightningspawner:spawn(currentEvent, target, entity.body:getPosition()):chainEvent(function(_, anchor)
                local entityAt = entity.body:getEntityAt(entity.body:getPosition() + Vector[direction])
                if entityAt and entityAt:hasComponent("tank") then
                    entityAt.tank:killNoTrigger(anchor)
                end

                entityAt = entity.body:getEntityAt(entity.body:getPosition() + Vector[direction] * 2)
                if entityAt and entityAt:hasComponent("tank") then
                    entityAt.tank:killNoTrigger(anchor)
                end

                entity.entityspawner:spawn("victory_portal", target)
            end)
        end

    end

end

local VICTORY_SPRITE_FADE = 0.45
local VICTORY_OUTLINE_FADE = 0.35
ACTIONS.VICTORY = class(Action)
function ACTIONS.VICTORY:initialize(entity, direction, abilityStats)
    ACTIONS.VICTORY:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("outline")
    self.outline:setIsFull()
    self:addComponent("charactereffects")
    self.outline.color = COLORS.STANDARD_GHOST
    self:setToQuick()
end

function ACTIONS.VICTORY:process(currentEvent)
    self.charactereffects:chainFadeOutSprite(currentEvent, VICTORY_SPRITE_FADE)
    currentEvent = self.outline:chainFadeIn(currentEvent, VICTORY_SPRITE_FADE)
    return self.outline:chainFadeOut(currentEvent, VICTORY_OUTLINE_FADE):chainEvent(function()
        self.entity.publisher:publish(Tags.UI_GAMEOVER, self.entity.equipment:get(Tags.SLOT_AMULET))
    end)
end

return ACTIONS

