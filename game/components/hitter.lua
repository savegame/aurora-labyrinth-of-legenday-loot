local Hitter = require("components.create_class")()
local Common = require("common")
local BUFFS = require("definitions.buffs")
local CONSTANTS = require("logic.constants")
local LogicMethods = require("logic.methods")
local Hit = class()
local Vector = require("utils.classes.vector")
local Array = require("utils.classes.array")
local TRIGGERS = require("actions.triggers")
local ActionUtils = require("actions.utils")
local ACTION_CONSTANTS = require("actions.constants")
local GET_KNOCKED_BACK = require("actions.get_knocked_back")
local COLORS = require("draw.colors")
local FIRE_FLASH_COLOR = COLORS.STANDARD_FIRE
local DEFAULT_KNOCKBACK_STEP_DURATION = 0.15
Tags.add("HIT_SOUND_MATERIAL", 1)
local Hit = class()
local SpawnFire = struct("duration", "minDamage", "maxDamage", "noVision")
local Knockback = struct("distance", "direction", "stepDuration", "skipTriggers", "isPull", "minDamage", "maxDamage", "damageBoosted", "distanceMinDamage", "distanceMaxDamage")
function Hit:initialize(sourceEntity, sourcePosition)
    self.sourceEntity = sourceEntity
    self.sourcePosition = sourcePosition
    self.targetEntity = false
    self.targetPosition = false
    self.slotSource = false
    self:clear()
    self.sound = Tags.HIT_SOUND_MATERIAL
    self.soundPitch = 1
end

function Hit:clear()
    self.minDamage = 0
    self.maxDamage = 0
    self.damageMultiplier = 1
    self.damageType = false
    self.affectsMana = false
    self.buffs = Array:new()
    self.knockback = false
    self.turnSkip = false
    self.spawnFire = false
    self.forceFlash = false
    self.forceNoFlash = false
    self.bonusState = 0
    self.sound = false
    self.soundPitch = 1
end

function Hit:increaseBonusState()
    self.bonusState = self.bonusState + 1
end

function Hit:decreaseBonusState()
    self.bonusState = self.bonusState - 1
end

function Hit:setDamage(damageType, minDamage, maxDamage)
    self.damageType = damageType
    self.minDamage = minDamage
    self.maxDamage = maxDamage
end

function Hit:setDamageFromAbilityStats(damageType, abilityStats)
    self.damageType = damageType
    self.minDamage = abilityStats:get(Tags.STAT_ABILITY_DAMAGE_MIN)
    self.maxDamage = abilityStats:get(Tags.STAT_ABILITY_DAMAGE_MAX)
    if abilityStats:hasKey(Tags.STAT_SLOT) then
        self.slotSource = abilityStats:get(Tags.STAT_SLOT)
    end

end

function Hit:setDamageFromSecondaryStats(damageType, abilityStats)
    self.damageType = damageType
    self.minDamage = abilityStats:get(Tags.STAT_SECONDARY_DAMAGE_MIN)
    self.maxDamage = abilityStats:get(Tags.STAT_SECONDARY_DAMAGE_MAX)
    if abilityStats:hasKey(Tags.STAT_SLOT) then
        self.slotSource = abilityStats:get(Tags.STAT_SLOT)
    end

end

function Hit:setDamageFromModifierStats(damageType, abilityStats)
    self.damageType = damageType
    self.minDamage = abilityStats:get(Tags.STAT_MODIFIER_DAMAGE_MIN)
    self.maxDamage = abilityStats:get(Tags.STAT_MODIFIER_DAMAGE_MAX)
end

function Hit:setHealing(minDamage, maxDamage, abilityStats)
    if not abilityStats then
        self.minDamage = -minDamage
        self.maxDamage = -minDamage
        abilityStats = maxDamage
    else
        self.minDamage = -maxDamage
        self.maxDamage = -minDamage
    end

    if abilityStats and abilityStats:hasKey(Tags.STAT_SLOT) then
        self.slotSource = abilityStats:get(Tags.STAT_SLOT)
    end

end

function Hit:multiplyDamage(multiplier)
    self.damageMultiplier = self.damageMultiplier * multiplier
end

function Hit:forceResolve()
    if DebugOptions.LOG_DAMAGE_RESOLVED then
        Debugger.log("Resolved damage: ", self.minDamage, self.maxDamage, self.damageMultiplier)
    end

    self.minDamage = self.minDamage * self.damageMultiplier
    self.maxDamage = self.maxDamage * self.damageMultiplier
    self.damageMultiplier = 1
    self.minDamage = self.sourceEntity.hitter:rollDamage(self.minDamage, self.maxDamage)
    self.maxDamage = self.minDamage
end

function Hit:isDamageDirect()
    if self.affectsMana then
        return false
    end

    return (self.damageType ~= Tags.DAMAGE_TYPE_BURN and self.damageType ~= Tags.DAMAGE_TYPE_POISON and self.damageType ~= Tags.DAMAGE_TYPE_FROSTBITE and self.damageType ~= Tags.DAMAGE_TYPE_NIGHTMARE and self.damageType ~= Tags.DAMAGE_TYPE_KNOCKBACK)
end

function Hit:isDamageIndirect()
    if self.affectsMana then
        return false
    end

    return (self.damageType == Tags.DAMAGE_TYPE_BURN or self.damageType == Tags.DAMAGE_TYPE_POISON or self.damageType == Tags.DAMAGE_TYPE_FROSTBITE or self.damageType == Tags.DAMAGE_TYPE_NIGHTMARE)
end

function Hit:isDamageAnyMelee()
    return (self.damageType == Tags.DAMAGE_TYPE_MELEE or self.damageType == Tags.DAMAGE_TYPE_MELEE_UNAVOIDABLE)
end

function Hit:isDamageOrDebuff()
    return self:isDamagePositiveDirect() or (not self.buffs:isEmpty())
end

function Hit:isDamagePositive()
    return self.minDamage >= 0 and self.maxDamage > 0 and self.damageMultiplier > 0
end

function Hit:isDamagePositiveDirect()
    return self:isDamagePositive() and self:isDamageDirect()
end

function Hit:isDamageNegative()
    return self.minDamage <= 0 and self.maxDamage < 0 and self.damageMultiplier > 0
end

function Hit:isTargetAgent()
    return self.targetEntity and self.targetEntity:hasComponent("agent")
end

function Hit:hasActionDisabling()
    return toBoolean(self.buffs:findOne(function(buff)
        return buff.disablesAction
    end))
end

function Hit:addBuff(buff)
    self.buffs:push(buff)
end

function Hit:setKnockback(distance, direction, stepDuration, skipTriggers, isPull)
    Utils.assert(direction, "Knockback requires direction")
    Utils.assert(distance > 0, "Cannot have negative knockback, use reverseDirection")
    self.knockback = Knockback:new(distance, direction, stepDuration or DEFAULT_KNOCKBACK_STEP_DURATION, toBoolean(skipTriggers), toBoolean(isPull))
end

function Hit:setKnockbackDamage(abilityStats)
    self.knockback.minDamage = abilityStats:get(Tags.STAT_KNOCKBACK_DAMAGE_MIN)
    self.knockback.maxDamage = abilityStats:get(Tags.STAT_KNOCKBACK_DAMAGE_MAX)
    self.knockback.damageBoosted = abilityStats:get(Tags.STAT_KNOCKBACK_DAMAGE_BOOSTED, 0) > 0
end

function Hit:setSpawnFire(duration, minDamage, maxDamage)
    self.spawnFire = SpawnFire:new(duration, minDamage, maxDamage)
end

function Hit:setSpawnFireFromSecondary(stats)
    local duration = stats:get(Tags.STAT_ABILITY_BURN_DURATION)
    local minDamage = stats:get(Tags.STAT_SECONDARY_DAMAGE_MIN)
    local maxDamage = stats:get(Tags.STAT_SECONDARY_DAMAGE_MAX)
    self.spawnFire = SpawnFire:new(duration, minDamage, maxDamage)
end

local MIN_DAMAGE = CONSTANTS.MIN_DAMAGE_ON_REDUCE
function Hit:reduceDamage(value)
    if self.minDamage > MIN_DAMAGE then
        self.minDamage = max(MIN_DAMAGE, self.minDamage - value)
    end

    if self.maxDamage > MIN_DAMAGE then
        self.maxDamage = max(MIN_DAMAGE, self.maxDamage - value)
    end

end

function Hit:applyToPosition(anchor, targetPosition)
    self.targetPosition = targetPosition
    self.sourceEntity.hitter:apply(anchor, self)
end

function Hit:applyToEntity(anchor, targetEntity, targetPosition)
    self.targetEntity = targetEntity
    self.targetPosition = targetPosition or false
    self.sourceEntity.hitter:apply(anchor, self)
end

function Hit:getApplyDistance()
    return self.sourcePosition:distanceManhattan(self.targetPosition)
end

function Hitter:initialize(entity)
    Hitter:super(self, "initialize", entity)
    self._entity = entity
end

function Hitter:createHit(sourcePosition)
    sourcePosition = sourcePosition or Common.getPositionComponent(self._entity):getPosition()
    return Hit:new(self._entity, sourcePosition)
end

function Hitter:_applyToEntity(anchor, hit, targetEntity)
    if not targetEntity:hasComponent("tank") or not targetEntity.tank:isAlive() then
        return 
    end

    if targetEntity:hasComponent("triggers") then
        local kwargs = { hit = hit }
                if (hit:isDamageOrDebuff() or hit.knockback) and self._entity ~= targetEntity then
            targetEntity.triggers:parallelChainEvent(anchor, TRIGGERS.PRE_HIT, false, kwargs)
            targetEntity = hit.targetEntity
        elseif hit.maxDamage < 0 and not hit.affectsMana then
            targetEntity.triggers:parallelChainEvent(anchor, TRIGGERS.WHEN_HEALED, false, kwargs)
        end

    end

    if targetEntity:hasComponent("equipment") then
        targetEntity.equipment:decorateIncomingHit(hit)
        targetEntity.playertriggers:rerollProccingSlot()
    end

    targetEntity:callIfHasComponent("buffable", "decorateIncomingHit", hit)
    self:_applyToEntityRaw(anchor, hit, targetEntity)
end

local HIT_SLOW_DURATION = 0.04
local HEAL_FLASH_OPACITY = 0.75
function Hitter:_applyToEntityRaw(anchor, hit, targetEntity)
    if hit.knockback then
        if targetEntity.body.cantBeMoved then
            hit.knockback.distance = 0
        else
            targetEntity.tank.delayDeath = true
            if not targetEntity:getIfHasComponent("buffable", "delayAllNonStart") then
                hit:addBuff(BUFFS:get("IMMOBILIZE_HIDDEN"):new(1))
            end

            local direction = hit.knockback.direction
            local action = targetEntity.actor:create(GET_KNOCKED_BACK, hit.knockback.direction)
            action.sourceEntity = hit.sourceEntity
            action.distance = hit.knockback.distance
            action.stepDuration = hit.knockback.stepDuration
            if hit.knockback.minDamage then
                action.bumpMinDamage = hit.knockback.minDamage
                action.bumpMaxDamage = hit.knockback.maxDamage
                if hit.knockback.damageBoosted then
                    action.bumpDamageBoosted = true
                end

            end

            action.move.interimSkipTriggers = hit.knockback.skipTriggers
            action:parallelResolve(anchor)
            hit.knockback.distance = action.resolvedDistance
            if hit.knockback.distanceMinDamage then
                action.bumpMinDamage = (action.bumpMinDamage + hit.knockback.distanceMinDamage * (action.resolvedDistance + 1))
                action.bumpMaxDamage = (action.bumpMaxDamage + hit.knockback.distanceMaxDamage * (action.resolvedDistance + 1))
            end

            action:chainEvent(anchor)
        end

    end

    if hit.forceFlash then
        targetEntity.charactereffects.negativeOverlay = 1
    end

        if hit.sound == Tags.HIT_SOUND_MATERIAL then
                                if hit.damageType == Tags.DAMAGE_TYPE_BURN then
            Common.playSFX("BURN_DAMAGE", hit.soundPitch)
        elseif hit.damageType == Tags.DAMAGE_TYPE_FROSTBITE then
            Common.playSFX("ICE_DAMAGE", hit.soundPitch)
        elseif hit:isDamageIndirect() then
            Common.playSFX("POISON_DAMAGE", hit.soundPitch)
        elseif hit:isDamageNegative() then
            Common.playSFX("HEAL", hit.soundPitch)
        else
            Common.playSFX("GENERIC_HIT", hit.soundPitch)
        end

    elseif hit.sound then
        Common.playSFX(hit.sound, hit.soundPitch)
    end

    if hit.maxDamage ~= 0 then
        hit:forceResolve()
        local damage = hit.minDamage
                if damage > 0 then
            if hit.affectsMana then
                if targetEntity:hasComponent("mana") then
                    targetEntity.mana:takeDamage(damage, hit.sourcePosition)
                end

            else
                local bonusState = hit.bonusState
                if hit:isDamageIndirect() then
                    bonusState = hit.damageType
                end

                targetEntity.tank:takeDamage(damage, hit.sourcePosition, bonusState, hit)
            end

        elseif damage < 0 then
            if hit.affectsMana then
                if not hit.forceNoFlash then
                    targetEntity.charactereffects:flash(ACTION_CONSTANTS.STANDARD_FLASH_DURATION, COLORS.MANA_HEAL:withAlpha(HEAL_FLASH_OPACITY))
                end

                targetEntity.mana:restore(-damage, hit.sourcePosition)
            else
                if not hit.forceNoFlash then
                    targetEntity.charactereffects:flash(ACTION_CONSTANTS.STANDARD_FLASH_DURATION, COLORS.HEALTH_ORB_FLASH:withAlpha(HEAL_FLASH_OPACITY))
                end

                targetEntity.tank:restore(-damage, hit.sourcePosition)
            end

        end

        if damage > 0 and not hit.forceNoFlash then
            targetEntity.charactereffects.negativeOverlay = 1
            local effects = self.system.services.effects
            if hit:isDamageDirect() then
                if targetEntity and targetEntity:hasComponent("buffable") then
                    effects.currentHits = effects.currentHits + 1
                    local currentEvent = self.system.services.parallelscheduler:createEvent()
                    currentEvent:chainProgress(HIT_SLOW_DURATION):chainEvent(function()
                        effects.currentHits = effects.currentHits - 1
                    end)
                end

            end

        end

        if self._entity:hasComponent("triggers") then
            local kwargs = { hit = hit }
            self._entity.triggers:parallelChainEvent(anchor, TRIGGERS.ON_DAMAGE, false, kwargs)
        end

    end

    if targetEntity:hasComponent("buffable") then
        if hit.buffs then
            for buff in hit.buffs() do
                targetEntity.buffable:apply(buff)
            end

        end

    end

    if hit.turnSkip and targetEntity:hasComponent("agent") then
        targetEntity.agent.isRattled = true
    end

    if hit.minDamage > 0 then
        if not targetEntity.tank:isAlive() and not targetEntity.tank.delayDeath then
            targetEntity.tank:kill(anchor)
        end

    end

    if self._entity ~= targetEntity and hit:isDamageOrDebuff() then
        if not targetEntity:hasComponent("tank") or targetEntity.tank:isAlive() then
            targetEntity:callIfHasComponent("triggers", "parallelChainEvent", anchor, TRIGGERS.POST_HIT, false, { hit = hit })
        end

        self._entity:callIfHasComponent("triggers", "parallelChainEvent", anchor, TRIGGERS.ON_HIT, false, { hit = hit })
    end

end

function Hitter:apply(anchor, hit)
    Utils.assert(hit.targetPosition or hit.targetEntity, "Hit must have a target")
    local services = self.system.services
    if not hit.targetPosition then
        hit.targetPosition = Common.getPositionComponent(hit.targetEntity):getPosition()
    end

    if not hit.targetEntity then
        hit.targetEntity = services.body:getAt(hit.targetPosition)
    end

    if self._entity:hasComponent("buffable") then
        self._entity.buffable:decorateOutgoingHit(hit)
    end

    if self._entity:hasComponent("equipment") then
        self._entity.equipment:decorateOutgoingHit(hit)
        self._entity.playertriggers:rerollProccingSlot()
    end

    if hit.targetEntity then
        self:_applyToEntity(anchor, hit, hit.targetEntity)
    end

    if hit.spawnFire and services.body:canBePassable(hit.targetPosition) then
        local firewall = services.createEntity("firewall", hit.targetPosition, hit.spawnFire.duration, hit.spawnFire.minDamage, hit.spawnFire.maxDamage, self._entity, hit.spawnFire.noVision)
        firewall.charactereffects:flash(ACTION_CONSTANTS.STANDARD_FLASH_DURATION, FIRE_FLASH_COLOR)
    end

    if not hit.targetEntity then
        hit:clear()
    end

end

function Hitter:rollDamage(minDamage, maxDamage)
    if minDamage < 1 and minDamage > 0 then
        minDamage = 1
    end

    if maxDamage < 1 and maxDamage > 0 then
        maxDamage = 1
    end

    local logicRNG = self.system.services.logicrng
    minDamage = logicRNG:resolveInteger(minDamage)
    maxDamage = logicRNG:resolveInteger(maxDamage)
    if minDamage > maxDamage then
        return maxDamage
    else
        return logicRNG:roll(minDamage, maxDamage)
    end

end

function Hitter:resolveInteger(value)
    if value < math.huge then
        return self.system.services.logicrng:resolveInteger(value)
    else
        return value
    end

end

function Hitter:getFloor()
    return self.system.services.run.currentFloor
end

function Hitter.System:initialize()
    Hitter.System:super(self, "initialize")
    self:setDependencies("createEntity", "body", "run", "logicrng", "effects", "parallelscheduler")
end

return Hitter

