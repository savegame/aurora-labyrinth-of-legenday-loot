local Array = require("utils.classes.array")
local Common = require("common")
local BUFFS = require("definitions.buffs")
local CONSTANTS = require("logic.constants")
local COLORS = require("draw.colors")
local TRIGGERS = require("actions.triggers")
local POISON = BUFFS:define("POISON")
local function willPoisonKill(buff, entity)
    return not buff.damageTicks:isEmpty() and buff.damageTicks[1] >= entity.tank:getCurrent()
end

function POISON:initialize(duration, sourceEntity, damage)
    POISON:super(self, "initialize", duration)
    self.sourceEntity = sourceEntity
    self.colorTint = COLORS.BUFF_TINT_POISON
    if type(damage) == "number" then
        self.damageTicks = self:toDamageTicks(duration, damage)
    else
        self.damageTicks = damage
    end

    self.delayTurn = willPoisonKill
end

function POISON:getDataArgs()
    return self.duration, self.sourceEntity, self.damageTicks
end

function POISON:toData(convertToData)
    return { expiresAtStart = self.expiresAtStart }
end

function POISON:fromData(data, convertFromData)
    self.expiresAtStart = data.expiresAtStart
end

function POISON:toDamageTicks(duration, damage)
    local result = Array:new()
    damage = max(damage, duration)
    while duration > 0 do
        local tick = ceil(damage / duration)
        result:push(tick)
        damage = damage - tick
        duration = duration - 1
    end

    return result
end

function POISON:setDuration(duration)
    local damage = self.damageTicks:sum()
    self.duration = duration
    self.damageTicks = self:toDamageTicks(self.duration, damage)
end

function POISON:tick(anchor, entity)
    local damage = self.damageTicks:popFirst()
    local hit = self.sourceEntity.hitter:createHit()
    hit:setDamage(Tags.DAMAGE_TYPE_POISON, damage, damage)
    hit:applyToEntity(anchor, entity, entity.body:getPosition())
end

function POISON:onTurnEnd(anchor, entity)
    if not self.expiresAtStart then
        self:tick(anchor, entity)
    end

end

function POISON:onTurnStart(anchor, entity)
    if self.expiresAtStart then
        self:tick(anchor, entity)
    end

end

function POISON:extendLast()
    self.damageTicks:push(self.damageTicks:last())
    self.duration = self.duration + 1
end

function POISON:onCombine(oldBuff)
    local oldTicks = oldBuff.damageTicks:subArray(1, oldBuff.duration)
    for i = 1, max(self.damageTicks:size(), oldTicks:size()) do
                if i > self.damageTicks:size() then
            self.damageTicks:push(oldTicks[i])
        elseif i <= oldTicks:size() then
            self.damageTicks[i] = max(self.damageTicks[i], oldTicks[i])
        end

    end

    self.duration = self.damageTicks:size()
        if oldBuff.sourceEntity:hasComponent("player") then
        self.sourceEntity = oldBuff.sourceEntity
    elseif oldBuff.sourceEntity:callIfHasComponent("buffable", "isAffectedBy", BUFFS:get("VICIOUS")) then
        self.sourceEntity = oldBuff.sourceEntity
    end

end

local COLD = BUFFS:define("COLD")
function COLD:initialize(duration)
    COLD:super(self, "initialize", duration)
    self.disablesMovement = true
    self.flashOnApply = true
    self.colorTint = COLORS.BUFF_TINT_COLD
end

function COLD:decorateIncomingHit(hit)
    if hit:isDamagePositive() and hit.damageType == Tags.DAMAGE_TYPE_BURN then
        self.duration = self.duration - 1
    end

end

local STUN = BUFFS:define("STUN")
function STUN:initialize(duration)
    STUN:super(self, "initialize", duration)
    self.disablesAction = true
    self.flashOnApply = true
    self.colorTint = COLORS.BUFF_TINT_STUN
end

function STUN:getColorTint(timePassed)
    return self.colorTint:withAlpha(Common.getPulseOpacity(timePassed, 0.3, 0.7))
end

function STUN:onExpire(anchor, entity)
    entity.buffable:apply(BUFFS:get("POST_STUN"):new(1))
end

local POST_STUN = BUFFS:define("POST_STUN")
local STUN_HIDDEN = BUFFS:define("STUN_HIDDEN")
function STUN_HIDDEN:initialize(duration)
    STUN_HIDDEN:super(self, "initialize", duration)
    self.disablesAction = true
end

local CAST_CANCEL = BUFFS:define("CAST_CANCEL", "STUN_HIDDEN")
function CAST_CANCEL:initialize()
    CAST_CANCEL:super(self, "initialize", 1)
    self.expiresAtStart = true
end

local IMMOBILIZE_HIDDEN = BUFFS:define("IMMOBILIZE_HIDDEN")
function IMMOBILIZE_HIDDEN:initialize(duration)
    IMMOBILIZE_HIDDEN:super(self, "initialize", duration)
    self.disablesMovement = true
end

function IMMOBILIZE_HIDDEN:isEntityImmune(entity)
    if entity:hasComponent("caster") then
        return entity.caster.preparedAction
    else
        return false
    end

end

local IMMUNE_HIDDEN = BUFFS:define("IMMUNE_HIDDEN")
function IMMUNE_HIDDEN:initialize(duration)
    IMMUNE_HIDDEN:super(self, "initialize", duration)
    self.expiresAtStart = true
end

function IMMUNE_HIDDEN:decorateIncomingHit(hit)
    hit:clear()
end

local ON_DEATH_IMMORTALITY = BUFFS:define("ON_DEATH_IMMORTALITY")
function ON_DEATH_IMMORTALITY:decorateIncomingHit(hit)
    hit:multiplyDamage(0)
    hit.minDamage = 0
    hit.maxDamage = 0
    hit.forceFlash = true
end

function ON_DEATH_IMMORTALITY:onTurnEnd(anchor, entity)
    if not entity:getIfHasComponent("caster", "preparedAction") then
        if entity.tank.currentHealth > 0 then
            entity.tank:kill(anchor)
        end

    end

end

local REACTIVE_TIME_STOP = BUFFS:define("REACTIVE_TIME_STOP")
function REACTIVE_TIME_STOP:initialize(duration)
    REACTIVE_TIME_STOP:super(self, "initialize", duration)
    self.expiresAtStart = true
end

function REACTIVE_TIME_STOP:onApply(entity)
    entity.agentvisitor:getSystemAgent():addTimeStop(1)
    entity.actor:getEffects():addTimeStop(1)
end

function REACTIVE_TIME_STOP:onDelete(anchor, entity)
    entity.agentvisitor:getSystemAgent():addTimeStop(-1)
    entity.actor:getEffects():addTimeStop(-1)
end


