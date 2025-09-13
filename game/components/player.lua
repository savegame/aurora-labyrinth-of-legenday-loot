local Vector = require("utils.classes.vector")
local Array = require("utils.classes.array")
local Common = require("common")
local CONSTANTS = require("logic.constants")
local ACTIONS_BASIC = require("actions.basic")
local ATTACK_UNARMED = require("actions.attack_unarmed")
local ATTACK_WEAPON = require("actions.attack_weapon")
local ACTION_CONSTANTS = require("actions.constants")
local TERMS = require("text.terms")
local Player = require("components.create_class")()
local BAREHAND_STATS = require("utils.classes.hash"):new()
local DEFAULT_ATTACK = ATTACK_UNARMED.TACKLE_AND_DAMAGE
local REACH_ATTACK = ATTACK_WEAPON.STAB_EXTENDED_AND_DAMAGE
local LUNGE_ATTACK = class("actions.base_attack")
function LUNGE_ATTACK:initialize(entity, direction, abilityStats)
    LUNGE_ATTACK:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("move")
    self.speedMultiplier = self.entity.player.attackSpeedMultiplier
end

function LUNGE_ATTACK:parallelResolve(currentEvent)
    self.move:prepare(currentEvent)
end

function LUNGE_ATTACK:process(currentEvent)
    self.entity.sprite:turnToDirection(self.direction)
    local speedMultiplier = self.speedMultiplier
    self.move:chainMoveEvent(currentEvent, ACTION_CONSTANTS.WALK_DURATION / speedMultiplier)
    local attackAction = self.entity.player:getWeaponAttackAction(self.direction)
    attackAction.bonusMinDamage = self.bonusMinDamage
    attackAction.bonusMaxDamage = self.bonusMaxDamage
    attackAction.forcedMinDamage = self.forcedMinDamage
    attackAction.forcedMaxDamage = self.forcedMaxDamage
    attackAction.buff = self.buff
    attackAction.attackTarget = self.attackTarget
    attackAction:speedMultiply(speedMultiplier)
    return attackAction:parallelChainEvent(currentEvent)
end

function Player:initialize(entity)
    Player:super(self, "initialize")
    self._entity = entity
    self.isFemale = false
    self.skipNextTurn = false
    self.attackSpeedMultiplier = 1
end

function Player:multiplyAttackSpeed(value)
    self.attackSpeedMultiplier = self.attackSpeedMultiplier * value
    if abs(self.attackSpeedMultiplier - 1) <= 0.001 then
        self.attackSpeedMultiplier = 1
    end

end

function Player:getMoveAction(direction)
    return self._entity.actor:createMove(direction)
end

function Player:getWeaponAttackAction(direction)
    local entity = self._entity
    local ring = entity.equipment:get(Tags.SLOT_RING)
    if ring then
        local attackClass = ring:getAttackClass()
        if attackClass and entity.equipment:isReady(Tags.SLOT_RING) then
            return entity.actor:create(attackClass, direction, ring.stats)
        end

    end

    local weapon = entity.equipment:get(Tags.SLOT_WEAPON)
    if weapon then
        local attackClass = weapon:getAttackClass(entity)
        return entity.actor:create(attackClass, direction, weapon.stats)
    end

    local amulet = entity.equipment:get(Tags.SLOT_AMULET)
    if amulet then
        local attackClass = amulet:getAttackClass()
        if attackClass then
            return entity.actor:create(attackClass, direction, amulet.stats)
        end

    end

    return entity.actor:create(DEFAULT_ATTACK, direction)
end

function Player:getBaseAttackAction(direction)
    local attackTarget = self._entity.body:getPosition() + Vector[direction]
    local attackClass = false
    local action = false
    local weapon = self._entity.equipment:get(Tags.SLOT_WEAPON)
    local stats = false
    if weapon then
        stats = weapon.stats
    end

    local extendedTarget = attackTarget + Vector[direction]
    local body = self._entity.body
    if body:isPassable(attackTarget) then
        local extenderProperty = self._entity.stats:getExtenderProperty()
        if extenderProperty then
            attackTarget = extendedTarget
                        if extenderProperty == Tags.STAT_LUNGE then
                attackClass = LUNGE_ATTACK
            elseif body:canBePassable(extendedTarget) then
                attackClass = REACH_ATTACK
            end

        end

    end

    if attackClass ~= LUNGE_ATTACK then
        local ring = self._entity.equipment:get(Tags.SLOT_RING)
        if ring and ring:getAttackClass() and self._entity.equipment:isReady(Tags.SLOT_RING) then
            attackClass = ring:getAttackClass()
            stats = ring.stats
        end

    end

    if attackClass then
        action = self._entity.actor:create(attackClass, direction, stats)
    else
        action = self:getWeaponAttackAction(direction)
    end

    action.attackTarget = attackTarget
    if attackClass ~= LUNGE_ATTACK then
        action:speedMultiply(self.attackSpeedMultiplier)
    end

    return action
end

function Player:shouldAttack(direction)
    local body = self._entity.body
    local target = body:getPosition() + Vector[direction]
    if body:isPassable(target) then
        if self._entity.stats:getExtenderProperty() then
            target = target + Vector[direction]
            if body:hasEntityWithAgent(target) then
                return true
            end

        end

        return false
    else
        return body:hasEntityWithTank(target)
    end

end

function Player:getBasicDirectionalAction(direction)
    local entity = self._entity
    local body = entity.body
    if self:canAttack() and self:shouldAttack(direction) then
        return entity.melee:createAction(direction)
    else
        local sustainSlot = entity.equipment:getSustainedSlot()
                if (not sustainSlot or entity.equipment:isSustainMobile()) then
            if body:isPassableDirection(direction) then
                if entity.buffable:canMove() then
                    return self:getMoveAction(direction)
                else
                    return entity.actor:create(ACTIONS_BASIC.WAIT_IMMOBILIZED)
                end

            end

        elseif (entity.equipment:isSustainSpecial()) then
            if entity.buffable:canMove() then
                return entity.equipment.slotBuffs:get(sustainSlot):getSustainSpecialAction(direction)
            else
                return entity.actor:create(ACTIONS_BASIC.WAIT_IMMOBILIZED)
            end

        else
            return entity.actor:create(ACTIONS_BASIC.WAIT_IMMOBILIZED)
        end

    end

    return false
end

function Player:canAct()
    return self._entity.buffable:canAct()
end

function Player:canMove()
    local entity = self._entity
    if entity.equipment:getSustainedSlot() then
        if not entity.equipment:isSustainMobile() then
            return false
        end

    end

    return entity.buffable:canMove()
end

function Player:canTurn()
    local entity = self._entity
    if entity.equipment:getSustainedSlot() then
        if not entity.equipment:isSustainMobile() and not entity.equipment:isSustainSpecial() then
            return false
        end

    end

    return true
end

function Player:canAttack()
    local entity = self._entity
    if entity.equipment:getSustainedSlot() then
        return false
    end

    return self._entity.buffable:canAttack()
end

function Player:onDeath()
    self.system.services.projectile:freezeAll()
end

function Player.System:initialize()
    Player.System:super(self, "initialize")
    self.storageClass = Array
    self:setDependencies("projectile")
end

function Player.System:get()
    if self.entities:isEmpty() then
        return false
    end

    return self.entities[1]
end

function Player.System:deleteInstance(entity)
end

return Player

