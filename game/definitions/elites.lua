local BUFFS = require("definitions.buffs")
local Common = require("common")
local TRIGGERS = require("actions.triggers")
local Array = require("utils.classes.array")
local Hash = require("utils.classes.hash")
local COLORS = require("draw.colors")
local Elite = struct("id", "color", "damageMultiplier", "healthMultiplier")
local ENEMY_PLAYER_RATIO = 3 / 5
local VICIOUS_OUTGOING_MULTIPLIER = 1.25
local TOUGH_INCOMING_MULTIPLIER = 0.8
local LIFESTEAL_RATIO = 1 / 3
local REGENERATION_RATIO = 0.2
local MANABURN_RATIO = 1
local POISONOUS_RATIO = 0.5
local POISONOUS_DURATION = 6
local COLD_DURATION = 2
local UNDYING_DURATION = 3
local ELITES = {  }
ELITES.ORDERED = Array:Convert({ [1] = Elite:new("HASTE", COLORS.ELITE_FAST), [2] = Elite:new("VICIOUS", COLORS.ELITE_VICIOUS), [3] = Elite:new("TOUGH", COLORS.ELITE_TOUGH), [4] = Elite:new("LIFESTEAL", COLORS.ELITE_LIFESTEAL), [5] = Elite:new("MANABURN", COLORS.ELITE_MANABURN), [6] = Elite:new("POISONOUS", COLORS.ELITE_POISONOUS), [7] = Elite:new("CHILLING", COLORS.ELITE_CHILLING), [8] = Elite:new("UNDYING", COLORS.ELITE_UNDYING), [9] = Elite:new("REGENERATION", COLORS.ELITE_REGENERATION) })
ELITES.BY_ID = Hash:new()
for elite in ELITES.ORDERED() do
    ELITES.BY_ID:set(elite.id, elite)
end

local BASE_ELITE = BUFFS:define("BASE_ELITE")
function BASE_ELITE:shouldSerialize()
    return false
end

local HASTE = BUFFS:define("HASTE", "BASE_ELITE")
function HASTE:initialize(duration)
    HASTE:super(self, "initialize", duration)
    self.hasQuickStepped = false
end

function HASTE:decorateBasicMove(action)
    if not self.hasQuickStepped then
        self.hasQuickStepped = true
        action:setToQuick()
    end

end

function HASTE:onTurnStart(anchor, entity)
    self.hasQuickStepped = false
end

local VICIOUS = BUFFS:define("VICIOUS", "BASE_ELITE")
function VICIOUS:decorateOutgoingHit(hit)
    hit:multiplyDamage(VICIOUS_OUTGOING_MULTIPLIER)
    hit:increaseBonusState()
end

local TOUGH = BUFFS:define("TOUGH", "BASE_ELITE")
function TOUGH:decorateIncomingHit(hit)
    if hit.damageType ~= Tags.DAMAGE_TYPE_SPELL_NO_REDUCE then
        hit:multiplyDamage(TOUGH_INCOMING_MULTIPLIER)
        hit:decreaseBonusState()
    end

end

local LIFESTEAL = BUFFS:define("LIFESTEAL", "BASE_ELITE")
local LIFESTEAL_TRIGGER = class(TRIGGERS.ON_DAMAGE)
function LIFESTEAL_TRIGGER:isEnabled()
    local targetEntity = self.hit.targetEntity
    if targetEntity:hasComponent("agent") or targetEntity:hasComponent("player") then
        return self.hit:isDamagePositiveDirect()
    else
        return false
    end

end

function LIFESTEAL_TRIGGER:process(currentEvent)
    local entity = self.entity
    local hit = entity.hitter:createHit()
    hit.sound = false
    hit:setHealing(self.hit.minDamage * LIFESTEAL_RATIO)
    hit:applyToEntity(currentEvent, entity)
    return currentEvent
end

function LIFESTEAL:initialize(duration)
    LIFESTEAL:super(self, "initialize", duration)
    self.triggerClasses:push(LIFESTEAL_TRIGGER)
end

local MANABURN = BUFFS:define("MANABURN", "BASE_ELITE")
local MANABURN_TRIGGER = class(TRIGGERS.ON_DAMAGE)
function MANABURN_TRIGGER:isEnabled()
    return self.hit:isDamagePositiveDirect() and not self.hit.affectsMana
end

function MANABURN_TRIGGER:process(currentEvent)
    local entity = self.entity
    local hit = entity.hitter:createHit()
    hit:setDamage(false, self.hit.minDamage * MANABURN_RATIO, self.hit.minDamage * MANABURN_RATIO)
    hit.affectsMana = true
    hit.sound = false
    hit.forceNoFlash = true
    hit:applyToEntity(currentEvent, self.hit.targetEntity)
    return currentEvent
end

function MANABURN:initialize(duration)
    MANABURN:super(self, "initialize", duration)
    self.triggerClasses:push(MANABURN_TRIGGER)
end

local POISONOUS = BUFFS:define("POISONOUS", "BASE_ELITE")
function POISONOUS:decorateOutgoingHit(hit)
    if hit:isDamagePositiveDirect() then
        local damage = (hit.minDamage + hit.maxDamage) * POISONOUS_RATIO / 2
        hit:addBuff(BUFFS:get("POISON"):new(POISONOUS_DURATION, hit.sourceEntity, damage))
    end

end

local CHILLING = BUFFS:define("CHILLING", "BASE_ELITE")
function CHILLING:decorateOutgoingHit(hit)
    if hit:isDamageOrDebuff() then
        hit:addBuff(BUFFS:get("COLD"):new(COLD_DURATION))
    end

end

local UNDYING_KILLER = BUFFS:define("UNDYING_KILLER", "ON_DEATH_IMMORTALITY")
function UNDYING_KILLER:initialize(duration)
    UNDYING_KILLER:super(self, "initialize", duration)
    self.displayTimerColor = COLORS.STANDARD_DEATH_BRIGHTER
end

function UNDYING_KILLER:onExpire(anchor, entity)
    Common.playSFX("GENERIC_HIT")
    entity.tank.keepAlive = false
    entity.tank.preDeath = doNothing
    entity.tank.delayDeath = false
    entity.tank:kill(anchor)
end

function UNDYING_KILLER:onTurnEnd(anchor, entity)
end

local UNDYING = BUFFS:define("UNDYING", "BASE_ELITE")
function UNDYING:onApply(entity)
    entity.tank.preDeath = function(entity)
        entity.tank.keepAlive = true
        entity.buffable:apply(UNDYING_KILLER:new(UNDYING_DURATION))
    end
end

local KNOCKBACK = BUFFS:define("KNOCKBACK", "BASE_ELITE")
local KNOCKBACK_STEP_DURATION = 0.1
function KNOCKBACK:decorateOutgoingHit(hit)
    if hit:isDamageOrDebuff() then
        hit:setKnockback(1, Common.getDirectionTowards(hit.sourcePosition, hit.targetPosition), KNOCKBACK_STEP_DURATION)
    end

end

local REGENERATION = BUFFS:define("REGENERATION", "BASE_ELITE")
local REGENERATION_TRIGGER = class(TRIGGERS.START_OF_TURN)
function REGENERATION_TRIGGER:initialize(entity, direction, abilityStats)
    REGENERATION_TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self.tookDamage = false
end

function REGENERATION_TRIGGER:isEnabled()
    return not self.tookDamage and self.entity.tank:getRatio() < 1
end

function REGENERATION_TRIGGER:process(currentEvent)
    local hit = self.entity.hitter:createHit()
    local minDamage, maxDamage = self.entity.stats:getAttack()
    local healing = (minDamage + maxDamage) * REGENERATION_RATIO / 2
    hit:setHealing(healing)
    hit.sound = false
    hit:applyToEntity(currentEvent, self.entity)
    return currentEvent
end

function REGENERATION:initialize(duration)
    REGENERATION:super(self, "initialize", duration)
    self.triggerClasses:push(REGENERATION_TRIGGER)
    self.tookDamage = false
end

function REGENERATION:shouldSerialize()
    return true
end

function REGENERATION:toData()
    return { tookDamage = self.tookDamage }
end

function REGENERATION:fromData(data)
    self.tookDamage = data.tookDamage
end

function REGENERATION:decorateIncomingHit(hit)
    if hit:isDamageOrDebuff() or hit:isDamagePositive() then
        self.tookDamage = true
    end

end

function REGENERATION:onTurnStart(anchor, entity)
    self.tookDamage = false
end

function REGENERATION:decorateTriggerAction(action)
    action.tookDamage = self.tookDamage
end

return ELITES

