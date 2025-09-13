local ACTIONS = {  }
local Vector = require("utils.classes.vector")
local Array = require("utils.classes.array")
local COLORS = require("draw.colors")
local Common = require("common")
local ActionUtils = require("actions.utils")
local ACTION_CONSTANTS = require("actions.constants")
local TRIGGERS = require("actions.triggers")
ACTIONS.DODGE = class(TRIGGERS.PRE_HIT)
local DODGE_DURATION = 0.12
local DODGE_DISTANCE = 0.5
local DODGE_JUMP = 0.1
function ACTIONS.DODGE:initialize(entity, direction, abilityStats)
    ACTIONS.DODGE:super(self, "initialize", entity, direction, abilityStats)
    self.activationType = Tags.TRIGGER_CHANCE
    self:addComponent("charactertrail")
    self:addComponent("tackle")
    self.tackle.braceDistance = DODGE_DISTANCE
    self.tackle.forwardDistance = 0
    self:addComponent("jump")
    self.jump.height = DODGE_JUMP
end

function ACTIONS.DODGE:isEnabled()
    return self.hit.damageType == Tags.DAMAGE_TYPE_MELEE and self.hit:isDamagePositive()
end

function ACTIONS.DODGE:parallelResolve(anchor)
    self.hit:clear()
    self.hit.sound = "DASH_SHORT"
end

function ACTIONS.DODGE:process(currentEvent)
    local entity = self.entity
    self.direction = Common.getDirectionTowards(entity.body:getPosition(), self.hit.sourcePosition)
    self.tackle:createOffset()
    self.charactertrail:start(currentEvent)
    self.jump:chainFullEvent(currentEvent, DODGE_DURATION)
    currentEvent = self.tackle:chainBraceEvent(currentEvent, DODGE_DURATION)
    return self.tackle:chainForwardEvent(currentEvent, DODGE_DURATION):chainEvent(function()
        self.tackle:deleteOffset()
        self.charactertrail:stop()
    end)
end

ACTIONS.EVASIVE_STEP = class(TRIGGERS.PRE_HIT)
local STEP_DURATION = ACTION_CONSTANTS.WALK_DURATION * 0.9
function ACTIONS.EVASIVE_STEP:initialize(entity, direction, abilityStats)
    ACTIONS.EVASIVE_STEP:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("move")
    self:addComponent("charactertrail")
end

function ACTIONS.EVASIVE_STEP:isEnabled()
    if self.entity.buffable:canMove() then
        if self.hit:isDamagePositive() and self.hit.damageType == Tags.DAMAGE_TYPE_MELEE then
            local body = self.entity.body
            for direction in DIRECTIONS_AA() do
                if body:isPassable(body:getPosition() + Vector[direction]) then
                    return true
                end

            end

        end

    end

    return false
end

function ACTIONS.EVASIVE_STEP:getDirections()
    local body = self.entity.body
    local attackDirection = Common.getDirectionTowards(body:getPosition(), self.hit.sourcePosition)
    local directions = Array:new(cwDirection(attackDirection), ccwDirection(attackDirection))
    directions:push(reverseDirection(attackDirection))
    directions:shuffleSelf(self:getLogicRNG())
    directions:push(attackDirection)
    directions:stableSortSelf(function(a, b)
        local costA = body:getStepCost(body:getPosition() + Vector[a])
        local costB = body:getStepCost(body:getPosition() + Vector[b])
        return costA < costB
    end)
    return directions
end

function ACTIONS.EVASIVE_STEP:parallelResolve(anchor)
    local directions = self:getDirections()
    local body = self.entity.body
    for direction in directions() do
        if body:isPassable(body:getPosition() + Vector[direction]) then
            self.move.direction = direction
            self.move:prepare(anchor)
            self.hit:clear()
            break
        end

    end

end

function ACTIONS.EVASIVE_STEP:process(currentEvent)
    if not self.move.direction then
        return currentEvent
    end

    self.charactertrail:start(currentEvent)
    Common.playSFX("DASH_SHORT")
    return self.move:chainMoveEvent(currentEvent, STEP_DURATION):chainEvent(function()
        self.charactertrail:stop()
    end)
end

ACTIONS.COUNTER_ATTACK = class(TRIGGERS.POST_HIT)
local COUNTER_ATTACK_DELAY = 0.15
function ACTIONS.COUNTER_ATTACK:isEnabled()
    if not self.entity.player:canAttack() then
        return false
    end

    if self.hit:isDamageOrDebuff() then
        local source = self.hit.sourceEntity
        if ActionUtils.isAliveAgent(source) then
            local position = source.body:getPosition()
            local entityPosition = self.entity.body:getPosition()
            local distance = position:distanceManhattan(entityPosition)
            if position.x == entityPosition.x or position.y == entityPosition.y then
                                if distance == 1 then
                    return true
                elseif distance == 2 and self.entity.stats:getExtenderProperty() then
                    return true
                end

            end

        end

    end

    return false
end

function ACTIONS.COUNTER_ATTACK:process(currentEvent)
    currentEvent = currentEvent:chainProgress(COUNTER_ATTACK_DELAY)
    local direction = Common.getDirectionTowardsEntity(self.entity, self.hit.sourceEntity)
    local attackAction = self.entity.melee:createAction(direction)
    return attackAction:parallelChainEvent(currentEvent):chainEvent(function()
        self.entity.sprite:resetLayer()
    end)
end

ACTIONS.BARRAGE = class(TRIGGERS.POST_CAST)
function ACTIONS.BARRAGE:initialize(entity, direction, abilityStats)
    ACTIONS.BARRAGE:super(self, "initialize", entity, direction, abilityStats)
    self.activationType = Tags.TRIGGER_CHANCE
end

function ACTIONS.BARRAGE:isEnabled()
    return self.triggeringSlot == self:getSlot()
end

function ACTIONS.BARRAGE:shouldDeleteOriginal()
    return true
end

function ACTIONS.BARRAGE:process(currentEvent)
    local ability = self.entity.equipment:get(self.triggeringSlot):getAbility()
    local directions = DIRECTIONS_AA:shuffle(self:getLogicRNG())
    if self:shouldDeleteOriginal() then
        directions:delete(self.direction)
    end

    for direction in directions() do
        if not ability.getInvalidReason(self.entity, direction, self.abilityStats) then
            local action = self.entity.actor:create(ability.actionClass, direction, self.abilityStats)
            return action:parallelChainEvent(currentEvent)
        end

    end

    return currentEvent
end

ACTIONS.ATTACK_REDUCE_COOLDOWN = class(TRIGGERS.ON_ATTACK)
function ACTIONS.ATTACK_REDUCE_COOLDOWN:initialize(entity, direction, abilityStats)
    ACTIONS.ATTACK_REDUCE_COOLDOWN:super(self, "initialize", entity, direction, abilityStats)
    self.activationType = Tags.TRIGGER_CHANCE
end

function ACTIONS.ATTACK_REDUCE_COOLDOWN:process(currentEvent)
    local equipment = self.entity.equipment
    local value = self.abilityStats:get(Tags.STAT_MODIFIER_VALUE)
    equipment:reduceCooldown(self.abilityStats:get(Tags.STAT_SLOT), value)
    return currentEvent
end

ACTIONS.HIT_REDUCE_COOLDOWN = class(TRIGGERS.POST_HIT)
function ACTIONS.HIT_REDUCE_COOLDOWN:initialize(entity, direction, abilityStats)
    ACTIONS.HIT_REDUCE_COOLDOWN:super(self, "initialize", entity, direction, abilityStats)
    self.activationType = Tags.TRIGGER_CHANCE
end

function ACTIONS.HIT_REDUCE_COOLDOWN:process(currentEvent)
    local equipment = self.entity.equipment
    local value = self.abilityStats:get(Tags.STAT_MODIFIER_VALUE)
    equipment:reduceCooldown(self.abilityStats:get(Tags.STAT_SLOT), value)
    return currentEvent
end

ACTIONS.ATTACK_KILL = class(TRIGGERS.ON_ATTACK)
local ATTACK_KILL_ICON = Vector:new(21, 7)
local ATTACK_KILL_FLASH_DURATION = 0.3
local ATTACK_KILL_LINGER_DURATION = 0.15
local ATTACK_KILL_EFFECT_DELAY = 0.2
function ACTIONS.ATTACK_KILL:initialize(entity, direction, abilityStats)
    ACTIONS.ATTACK_KILL:super(self, "initialize", entity, direction, abilityStats)
    self.sortOrder = 10
    self:addComponent("iconflash")
    self.iconflash.icon = ATTACK_KILL_ICON
    self.iconflash.color = COLORS.STANDARD_DEATH_BRIGHTER
end

function ACTIONS.ATTACK_KILL:shouldKill(entity)
    return true
end

function ACTIONS.ATTACK_KILL:process(currentEvent)
    local entityAt = self.entity.body:getEntityAt(self.attackTarget)
    if ActionUtils.isAliveAgent(entityAt) and self:shouldKill(entityAt) then
        self.iconflash.target = entityAt.sprite
        currentEvent = currentEvent:chainProgress(ATTACK_KILL_EFFECT_DELAY):chainEvent(function()
            Common.playSFX("DOOM")
        end)
        currentEvent = self.iconflash:chainFlashEvent(currentEvent, ATTACK_KILL_FLASH_DURATION):chainEvent(function(_, anchor)
            Common.playSFX("GENERIC_HIT")
            if ActionUtils.isAliveAgent(entityAt) then
                entityAt.charactereffects.negativeOverlay = 1
                entityAt.tank:kill(anchor)
            end

        end)
        self.iconflash:chainFadeEvent(currentEvent, ATTACK_KILL_LINGER_DURATION)
    end

    return currentEvent
end

ACTIONS.ATTACK_ANOTHER = class(TRIGGERS.ON_ATTACK)
function ACTIONS.ATTACK_ANOTHER:initialize(entity, direction, abilityStats)
    ACTIONS.ATTACK_ANOTHER:super(self, "initialize", entity, direction, abilityStats)
    self.sortOrder = 11
end

local ATTACK_ANOTHER_DELAY = 0.15
function ACTIONS.ATTACK_ANOTHER:isAttackValid(entityAt, direction)
    return true
end

function ACTIONS.ATTACK_ANOTHER:isEnabled()
    return self.entity.player:canAttack()
end

function ACTIONS.ATTACK_ANOTHER:process(currentEvent)
    local direction = ActionUtils.getRandomAttackDirection(self:getLogicRNG(), self.entity, function(entityAt, direction)
        return self:isAttackValid(entityAt, direction)
    end)
    if direction then
        return self:doAttack(currentEvent, direction)
    end

    return currentEvent
end

function ACTIONS.ATTACK_ANOTHER:doAttack(currentEvent, direction)
    local attackAction = self.entity.melee:createAction(direction)
    return attackAction:parallelChainEvent(currentEvent:chainProgress(ATTACK_ANOTHER_DELAY))
end

ACTIONS.MANA_ON_HEAL = class(TRIGGERS.WHEN_HEALED)
local MANA_DELAY = 0.25
function ACTIONS.MANA_ON_HEAL:getHealValue()
    return -self.hit.minDamage / 2
end

function ACTIONS.MANA_ON_HEAL:isEnabled()
    return self.hit.slotSource == self:getSlot() and not self.hit.affectsMana
end

function ACTIONS.MANA_ON_HEAL:process(currentEvent)
    self.hit:forceResolve()
    return currentEvent:chainProgress(MANA_DELAY):chainEvent(function(_, anchor)
        local healHit = self.entity.hitter:createHit()
        healHit:setHealing(self:getHealValue(), self.abilityStats)
        healHit.affectsMana = true
        healHit.sound = false
        healHit:applyToEntity(anchor, self.entity)
    end)
end

return ACTIONS

