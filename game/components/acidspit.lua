local AcidSpit = require("components.create_class")()
local Common = require("common")
local BUFFS = require("definitions.buffs")
function AcidSpit:initialize(entity)
    AcidSpit:super(self, "initialize", entity)
    self.poisonDuration = false
    self._entity = entity
end

function AcidSpit:shouldCreatePool(target)
    local body = self._entity.body
    if not body:canBePassable(target) then
        return false
    end

    if body:isPassable(target) then
        return true
    end

    local entityAt = body:getEntityAt(target)
    return not entityAt or entityAt:hasComponent("acidspit") or entityAt.body.phaseProjectiles
end

function AcidSpit:applyToPosition(anchor, target)
    local poisonDamage = self._entity.stats:getConstantEnemyAbility()
    if self:shouldCreatePool(target) then
        Common.playSFX("POISON_DAMAGE")
        self.system:createPool(target, self.poisonDuration, poisonDamage, self._entity)
    else
        local hit = self._entity.hitter:createHit()
        hit.sound = "POISON_DAMAGE"
        hit:addBuff(BUFFS:get("POISON"):new(self.poisonDuration, self._entity, poisonDamage))
        hit:applyToPosition(anchor, target)
    end

end

function AcidSpit.System:initialize()
    AcidSpit.System:super(self, "initialize")
    self:setDependencies("createEntity", "steppable")
end

function AcidSpit.System:createPool(target, duration, damage)
    if not self.services.steppable:hasPermanentExclusivity(target, Tags.STEP_EXCLUSIVE_LIQUID) then
        return self.services.createEntity("acid_pool", target, duration, damage)
    end

    return false
end

return AcidSpit

