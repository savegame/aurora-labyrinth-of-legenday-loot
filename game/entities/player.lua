local Array = require("utils.classes.array")
local Vector = require("utils.classes.vector")
local BUFFS = require("definitions.buffs")
local ACTIONS_BASIC = require("actions.basic")
local ACTION_CONSTANTS = require("actions.constants")
local COLORS = require("draw.colors")
local ITEMS = require("definitions.items")
local CONSTANTS = require("logic.constants")
local MELEE_ATTACK = class("actions.action")
function MELEE_ATTACK:initialize(entity, direction, abilityStats)
    MELEE_ATTACK:super(self, "initialize", entity, direction, abilityStats)
    self.baseAttack = false
    self.attackTarget = false
end

function MELEE_ATTACK:parallelResolve(currentEvent)
    self.baseAttack = self.entity.player:getBaseAttackAction(self.direction)
    self.baseAttack:parallelResolve(currentEvent)
    self.attackTarget = self.baseAttack.attackTarget
end

function MELEE_ATTACK:process(currentEvent)
    currentEvent = self.baseAttack:chainEvent(currentEvent)
    return self.entity.triggers:parallelChainAttack(currentEvent, self.direction, self.attackTarget)
end

local PLAYER_DIE = class(ACTIONS_BASIC.DIE)
local DEATH_SPEED_MULTIPLIER = 0.2
local DEATH_DURATION = 0.16
function PLAYER_DIE:parallelResolve(anchor)
    self:getEffects():multiplySpeed(DEATH_SPEED_MULTIPLIER)
    self.entity.agentvisitor:visit(function(entity)
        entity.buffable:apply(BUFFS:get("IMMUNE_HIDDEN"):new(math.huge))
        entity.agent.hasActedThisTurn = true
    end)
    self.entity.player:onDeath()
end

function PLAYER_DIE:process(currentEvent)
    local entity = self.entity
    entity.charactereffects.negativeOverlay = 1
    entity.sprite.opacity = 0
    for slot in ITEMS.SLOTS() do
        if entity.equipment:isSlotActive(slot) then
            entity.equipment:deactivateSlot(currentEvent, slot)
        end

    end

    entity.buffable:clear()
    currentEvent:chainProgress(ACTION_CONSTANTS.NEGATIVE_FADE_DURATION, function(progress)
        entity.sprite.opacity = 0
    end):chainEvent(function()
        entity.sprite.isRemoved = true
    end)
    return currentEvent:chainProgress(DEATH_DURATION):chainEvent(function()
        self:getEffects():divideSpeed(DEATH_SPEED_MULTIPLIER)
        entity.publisher:publish(Tags.UI_GAMEOVER, self.killer)
    end)
end

local BAREHANDED_ICON = Vector:new(1, 1)
return function(entity, position, isFemale)
    entity:addComponent("serializable", isFemale)
    entity:addComponent("stats")
    entity.stats:set(Tags.STAT_MAX_HEALTH, 200)
    entity.stats:set(Tags.STAT_HEALTH_REGEN, CONSTANTS.HEALTH_PER_TURN)
    entity.stats:set(Tags.STAT_MAX_MANA, 200)
    entity.stats:set(Tags.STAT_MANA_REGEN, CONSTANTS.MANA_PER_TURN)
    entity.stats:set(Tags.STAT_ATTACK_DAMAGE_MIN, 0)
    entity.stats:set(Tags.STAT_ATTACK_DAMAGE_MAX, 0)
    entity:addComponent("player")
    entity.player.isFemale = isFemale
    entity:addComponent("turn")
    entity:addComponent("vision")
    entity:addComponent("body", position)
    entity:addComponent("sprite")
    if isFemale then
        entity.sprite:setCell(9, 1)
    else
        entity.sprite:setCell(8, 1)
    end

    entity.sprite.strokeColor = Array:new()
    entity:addComponent("indicator", "PLAYER")
    entity:addComponent("charactereffects")
    entity:addComponent("offset")
    entity:addComponent("wallet", scrapWrapper)
    entity:addComponent("equipment")
    entity:addComponent("tank")
    entity.tank.deathActionClass = PLAYER_DIE
    entity:addComponent("mana")
    entity:addComponent("playertriggers")
    entity:addComponent("triggers")
    entity.triggers.source = entity.playertriggers
    entity:addComponent("melee")
    entity.melee.attackClass = MELEE_ATTACK
    entity.melee.swingIcon = function(entity)
        local weapon = entity.equipment:get(Tags.SLOT_WEAPON)
        if weapon then
            return weapon:getIcon()
        else
            return BAREHANDED_ICON
        end

    end
    entity:addComponent("buffable")
    entity.buffable:addImmunity(BUFFS:get("IMMOBILIZE_HIDDEN"))
    entity:addComponent("hitter")
    entity:addComponent("publisher")
    entity:addComponent("agentvisitor")
    entity:addComponent("entityspawner")
    entity:addComponent("projectilespawner")
    entity:addComponent("label", "Friendly Fire")
    entity.label.properNoun = true
    entity:addComponent("actor")
end

