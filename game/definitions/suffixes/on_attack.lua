local textStatFormat = require("text.stat_format")
local Vector = require("utils.classes.vector")
local Common = require("common")
local BUFFS = require("definitions.buffs")
local Array = require("utils.classes.array")
local ActionUtils = require("actions.utils")
local TRIGGERS = require("actions.triggers")
local ACTION_CONSTANTS = require("actions.constants")
local PLAYER_TRIGGERS = require("actions.player_triggers")
local ModifierDef = require("structures.modifier_def")
local AWAKENING = ModifierDef:new("Awakening")
local AWAKENING_FORMAT = "{C:KEYWORD}Chance on {C:KEYWORD}Attack to reduce this ability's cooldown by %s turns."
AWAKENING:setToStatsBase({ [Tags.STAT_MODIFIER_VALUE] = 3 })
AWAKENING:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
AWAKENING:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
AWAKENING:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
AWAKENING.statLine = function(item)
    return textStatFormat(AWAKENING_FORMAT, item, Tags.STAT_MODIFIER_VALUE)
end
AWAKENING.canRoll = function(itemDef)
    return true
end
AWAKENING.modifyItem = function(item)
    item.triggers:push(PLAYER_TRIGGERS.ATTACK_REDUCE_COOLDOWN)
end
local SHOCK = ModifierDef:new("Shock")
local SHOCK_FORMAT = "{C:KEYWORD}Chance on {C:KEYWORD}Attack to deal %s damage to " .. "another random enemy and {C:KEYWORD}Stun it for {C:NUMBER}1 turn."
SHOCK:setToStatsBase({ [Tags.STAT_MODIFIER_DAMAGE_BASE] = 12.75, [Tags.STAT_MODIFIER_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.96) })
SHOCK.statLine = function(item)
    return textStatFormat(SHOCK_FORMAT, item, Tags.STAT_MODIFIER_DAMAGE_MIN)
end
SHOCK.canRoll = function(itemDef)
    return itemDef:isSlotOffensive()
end
local SHOCK_TRIGGER = class(TRIGGERS.ON_DAMAGE)
local SHOCK_DELAY = 0.13
function SHOCK_TRIGGER:initialize(entity, direction, abilityStats)
    SHOCK_TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self.activationType = Tags.TRIGGER_CHANCE
    self:addComponent("lightningspawner")
end

function SHOCK_TRIGGER:isEnabled()
    return (self.hit.damageType == Tags.DAMAGE_TYPE_MELEE and self.hit:isDamagePositive() and self.hit:isTargetAgent())
end

function SHOCK_TRIGGER:process(currentEvent)
    self.entity.agentvisitor:visit(function(agent)
        local target = agent.body:getPosition()
        if self.entity.vision:isVisible(target) and agent ~= self.hit.targetEntity then
            currentEvent = currentEvent:chainProgress(SHOCK_DELAY):chainEvent(function()
                Common.playSFX("LIGHTNING")
            end)
            currentEvent = self.lightningspawner:spawn(currentEvent, target):chainEvent(function(_, anchor)
                local hit = self.entity.hitter:createHit()
                hit:setDamageFromModifierStats(Tags.DAMAGE_TYPE_SPELL, self.abilityStats)
                hit:addBuff(BUFFS:get("STUN"):new(1))
                hit:applyToEntity(anchor, agent)
            end)
            return true
        else
            return false
        end

    end, true, true)
    return currentEvent
end

SHOCK.modifyItem = function(item)
    item.triggers:push(SHOCK_TRIGGER)
end
local ECHO = ModifierDef:new("Echo")
local ECHO_FORMAT = "Your {C:KEYWORD}Attacks deal %s damage to the left and right side of the target."
ECHO:setToStatsBase({ [Tags.STAT_MODIFIER_DAMAGE_BASE] = 8, [Tags.STAT_MODIFIER_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.96) })
ECHO.statLine = function(item)
    return textStatFormat(ECHO_FORMAT, item, Tags.STAT_MODIFIER_DAMAGE_MIN)
end
ECHO.canRoll = function(itemDef)
    return itemDef.slot == Tags.SLOT_WEAPON
end
local ECHO_TRIGGER = class(TRIGGERS.ON_ATTACK)
function ECHO_TRIGGER:initialize(entity, direction, abilityStats)
    ECHO_TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self.sortOrder = -1
end

function ECHO_TRIGGER:process(currentEvent)
    local source = self.entity.body:getPosition()
    local direction = self.direction
    local directions = Array:new(ccwDirection(direction), cwDirection(direction))
    for direction in directions() do
        local target = self.attackTarget + Vector[direction]
        local hit = self.entity.hitter:createHit()
        hit:setDamageFromModifierStats(Tags.DAMAGE_TYPE_SPELL, self.abilityStats)
        hit:applyToPosition(currentEvent, target)
    end

    return currentEvent
end

ECHO.modifyItem = function(item)
    item.triggers:push(ECHO_TRIGGER)
end
local PRECISION = ModifierDef:new("Precision")
local PRECISION_FORMAT = "{C:KEYWORD}Chance on {C:KEYWORD}Attack to deal %s bonus damage."
PRECISION:setToStatsBase({ [Tags.STAT_MODIFIER_DAMAGE_BASE] = 16, [Tags.STAT_MODIFIER_DAMAGE_VARIANCE] = 0 })
PRECISION.statLine = function(item)
    return textStatFormat(PRECISION_FORMAT, item, Tags.STAT_MODIFIER_DAMAGE_MIN)
end
PRECISION.canRoll = function(itemDef)
    return itemDef.slot ~= Tags.SLOT_HELM
end
PRECISION.decorateOutgoingHit = function(entity, hit, abilityStats)
    local slot = abilityStats:get(Tags.STAT_SLOT)
    if entity.playertriggers.proccingSlot == slot and hit.damageType == Tags.DAMAGE_TYPE_MELEE then
        if hit:isDamagePositive() then
            hit.minDamage = hit.minDamage + abilityStats:get(Tags.STAT_MODIFIER_DAMAGE_MIN)
            hit.maxDamage = hit.maxDamage + abilityStats:get(Tags.STAT_MODIFIER_DAMAGE_MAX)
            hit:increaseBonusState()
        end

    end

end
local VAMPIRE = ModifierDef:new("the Vampire")
VAMPIRE:setToStatsBase({ [Tags.STAT_MODIFIER_DAMAGE_BASE] = 11, [Tags.STAT_MODIFIER_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.55) })
local VAMPIRE_FORMAT = "{C:KEYWORD}Chance whenever you {C:KEYWORD}Attack an enemy to restore %s health."
VAMPIRE.statLine = function(item)
    return textStatFormat(VAMPIRE_FORMAT, item, Tags.STAT_MODIFIER_DAMAGE_MIN)
end
VAMPIRE.canRoll = function(itemDef)
    return itemDef.slot ~= Tags.SLOT_GLOVES
end
local VAMPIRE_TRIGGER = class(TRIGGERS.ON_DAMAGE)
function VAMPIRE_TRIGGER:initialize(entity, direction, abilityStats)
    VAMPIRE_TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self.activationType = Tags.TRIGGER_CHANCE
end

function VAMPIRE_TRIGGER:isEnabled()
    return (self.hit.damageType == Tags.DAMAGE_TYPE_MELEE and self.hit:isDamagePositive() and self.hit:isTargetAgent())
end

function VAMPIRE_TRIGGER:process(currentEvent)
    local entity = self.entity
    local hit = entity.hitter:createHit()
    hit:setHealing(self.abilityStats:get(Tags.STAT_MODIFIER_DAMAGE_MIN), self.abilityStats:get(Tags.STAT_MODIFIER_DAMAGE_MAX), self.abilityStats)
    hit:applyToEntity(currentEvent, entity)
    return currentEvent
end

VAMPIRE.modifyItem = function(item)
    item.triggers:push(VAMPIRE_TRIGGER)
end
local BANSHEE = ModifierDef:new("the Banshee")
BANSHEE:setToStatsBase({ [Tags.STAT_MODIFIER_DAMAGE_BASE] = 15, [Tags.STAT_MODIFIER_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.35) })
local BANSHEE_FORMAT = "{C:KEYWORD}Chance whenever you {C:KEYWORD}Attack an enemy to restore %s mana."
BANSHEE.statLine = function(item)
    return textStatFormat(BANSHEE_FORMAT, item, Tags.STAT_MODIFIER_DAMAGE_MIN)
end
BANSHEE.canRoll = function(itemDef)
    return itemDef.slot ~= Tags.SLOT_GLOVES
end
local BANSHEE_TRIGGER = class(TRIGGERS.ON_DAMAGE)
function BANSHEE_TRIGGER:initialize(entity, direction, abilityStats)
    BANSHEE_TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self.activationType = Tags.TRIGGER_CHANCE
end

function BANSHEE_TRIGGER:isEnabled()
    return (self.hit.damageType == Tags.DAMAGE_TYPE_MELEE and self.hit:isDamagePositive() and self.hit:isTargetAgent())
end

function BANSHEE_TRIGGER:process(currentEvent)
    local entity = self.entity
    local hit = entity.hitter:createHit()
    hit:setHealing(self.abilityStats:get(Tags.STAT_MODIFIER_DAMAGE_MIN), self.abilityStats:get(Tags.STAT_MODIFIER_DAMAGE_MAX), self.abilityStats)
    hit.affectsMana = true
    hit:applyToEntity(currentEvent, entity)
    return currentEvent
end

BANSHEE.modifyItem = function(item)
    item.triggers:push(BANSHEE_TRIGGER)
end
local WRATH = ModifierDef:new("Wrath")
WRATH.statLine = "{C:KEYWORD}Chance on {C:KEYWORD}Attack to {C:KEYWORD}Attack an enemy in a different direction."
WRATH.canRoll = function(itemDef)
    return itemDef:isSlotOffensive()
end
local WRATH_TRIGGER = class(PLAYER_TRIGGERS.ATTACK_ANOTHER)
function WRATH_TRIGGER:initialize(entity, direction, abilityStats)
    WRATH_TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self.activationType = Tags.TRIGGER_CHANCE
end

function WRATH_TRIGGER:isAttackValid(entityAt, direction)
    return direction ~= self.direction
end

WRATH.modifyItem = function(item)
    item.triggers:push(WRATH_TRIGGER)
end
local TRICKERY = ModifierDef:new("Trickery")
TRICKERY.statLine = "{C:KEYWORD}Chance after {C:KEYWORD}Attacking an enemy to move {C:NUMBER}1 step backwards."
TRICKERY.canRoll = function(itemDef)
    return itemDef.slot ~= Tags.SLOT_HELM
end
local TRICKERY_TRIGGER = class(TRIGGERS.ON_ATTACK)
function TRICKERY_TRIGGER:initialize(entity, direction, abilityStats)
    TRICKERY_TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self.activationType = Tags.TRIGGER_CHANCE
    self.sortOrder = 20
    self:addComponent("move")
    self:addComponent("charactertrail")
end

local TRICKERY_DELAY = 0.1
local MOVE_DURATION = ACTION_CONSTANTS.WALK_DURATION * 0.9
function TRICKERY_TRIGGER:isEnabled()
    if self.entity.buffable:canMove() then
        if self.entity.body:hasEntityWithAgent(self.attackTarget) then
            return self.entity.body:isPassableDirection(reverseDirection(self.direction))
        end

    end

    return false
end

function TRICKERY_TRIGGER:process(currentEvent)
    self.charactertrail:start(currentEvent)
    self.move.distance = 1
    self.move.direction = reverseDirection(self.direction)
    self.move:prepare(currentEvent)
    Common.playSFX("DASH_SHORT")
    return self.move:chainMoveEvent(currentEvent, MOVE_DURATION):chainEvent(function()
        self.charactertrail:stop()
    end)
end

TRICKERY.modifyItem = function(item)
    item.triggers:push(TRICKERY_TRIGGER)
end
local RATTLING = ModifierDef:new("Rattling")
RATTLING.statLine = "{C:KEYWORD}Chance on {C:KEYWORD}Attack to make the enemy skip its turn."
RATTLING.canRoll = function(itemDef)
    return itemDef.slot ~= Tags.SLOT_HELM
end
local RATTLING_TRIGGER = class(TRIGGERS.ON_DAMAGE)
function RATTLING_TRIGGER:initialize(entity, direction, abilityStats)
    RATTLING_TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self.activationType = Tags.TRIGGER_CHANCE
end

function RATTLING_TRIGGER:isEnabled()
    return (self.hit.damageType == Tags.DAMAGE_TYPE_MELEE and self.hit:isDamagePositive() and self.hit:isTargetAgent())
end

function RATTLING_TRIGGER:parallelResolve(currentEvent)
    RATTLING_TRIGGER:super(self, "parallelResolve", currentEvent)
    self.hit.turnSkip = true
end

local RATTLING_SHAKE = 1
function RATTLING_TRIGGER:process(currentEvent)
    Common.playSFX("ROCK_SHAKE", 1.4, 0.8)
    self:shakeScreen(currentEvent, RATTLING_SHAKE)
    return currentEvent
end

RATTLING.modifyItem = function(item)
    item.triggers:push(RATTLING_TRIGGER)
end
local FERVOR = ModifierDef:new("Fervor")
local FERVOR_FORMAT = "Your {C:KEYWORD}Attacks deal %s bonus damage to enemies you " .. "attacked last turn."
FERVOR:setToStatsBase({ [Tags.STAT_MODIFIER_DAMAGE_BASE] = 3.35, [Tags.STAT_MODIFIER_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.85) })
FERVOR.statLine = function(item)
    return textStatFormat(FERVOR_FORMAT, item, Tags.STAT_MODIFIER_DAMAGE_MIN)
end
FERVOR.canRoll = function(itemDef)
    return itemDef:isSlotOffensive()
end
local FERVOR_DEBUFF = BUFFS:define("FERVOR")
function FERVOR_DEBUFF:initialize(duration)
    FERVOR_DEBUFF:super(self, "initialize", duration)
end

FERVOR.decorateOutgoingHit = function(entity, hit, abilityStats)
    if hit.damageType == Tags.DAMAGE_TYPE_MELEE and hit:isDamagePositive() then
        hit:addBuff(FERVOR_DEBUFF:new(2))
        if hit.targetEntity and hit.targetEntity:hasComponent("buffable") then
            if hit.targetEntity.buffable:isAffectedBy(FERVOR_DEBUFF) then
                hit.minDamage = hit.minDamage + abilityStats:get(Tags.STAT_MODIFIER_DAMAGE_MIN)
                hit.maxDamage = hit.maxDamage + abilityStats:get(Tags.STAT_MODIFIER_DAMAGE_MAX)
                hit:increaseBonusState()
            end

        end

    end

end
return { AWAKENING = AWAKENING, SHOCK = SHOCK, ECHO = ECHO, PRECISION = PRECISION, VAMPIRE = VAMPIRE, BANSHEE = BANSHEE, WRATH = WRATH, TRICKERY = TRICKERY, RATTLING = RATTLING, FERVOR = FERVOR }

