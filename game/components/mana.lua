local Mana = require("components.create_class")()
local Array = require("utils.classes.array")
local EffectDamage = require("effects.damage")
local COLORS = require("draw.colors")
function Mana:initialize(entity)
    Mana:super(self, "initialize")
    Debugger.assertComponent(entity, "stats")
    self._entity = entity
    self._stats = entity.stats
    local maxMana = self:getMax()
    Utils.assert(maxMana > 0, "Max mana must be greater that 0 for mana")
    self.currentMana = maxMana
    self.currentRegeneration = 0
    self.damageEffects = Array:new()
    self.preventNextTick = false
    entity:callIfHasComponent("serializable", "addComponent", "mana")
end

function Mana:toData()
    return { currentMana = self.currentMana, currentRegeneration = self.currentRegeneration, preventNextTick = self.preventNextTick }
end

function Mana:fromData(data)
    self.currentMana = data.currentMana
    self.currentRegeneration = data.currentRegeneration
    self.preventNextTick = data.preventNextTick
end

function Mana:regenerate()
    if self.preventNextTick then
        self.preventNextTick = false
        return 
    end

    self.currentRegeneration = (self.currentRegeneration + self._stats:get(Tags.STAT_MANA_REGEN) * self:getMax())
    if self.currentRegeneration % 1 > 0.9999 then
        self.currentRegeneration = ceil(self.currentRegeneration)
    end

    self.currentRegeneration = self.currentRegeneration + self._stats:get(Tags.STAT_FLAT_MANA_REGEN)
    local integerRegen = floor(self.currentRegeneration)
        if integerRegen > 0 then
        self:restore(integerRegen)
    elseif integerRegen < 0 then
        self:consume(-integerRegen)
    end

    self.currentRegeneration = self.currentRegeneration - integerRegen
end

function Mana:consume(value)
    self.currentMana = max(self.currentMana - value, 0)
end

function Mana:restore(value, sourcePosition)
    self:restoreSilent(value)
    if sourcePosition then
        for otherEffect in self.damageEffects() do
            if otherEffect.progress < 0.1 and otherEffect.negative then
                otherEffect.value = otherEffect.value + abs(value)
                return 
            end

        end

        local effect = EffectDamage:new(-value, COLORS.MANA_HEAL)
        effect.position = self._entity.sprite
        effect.xDirection = sign(effect.position:getDisplayPosition(true, true).x - sourcePosition.x)
        self.damageEffects:push(effect)
    end

end

function Mana:takeDamage(value, sourcePosition)
    self.currentMana = max(self.currentMana - value, 0)
    local effect = EffectDamage:new(value, COLORS.MANA_DAMAGE)
    effect.position = self._entity.sprite
    effect.xDirection = sign(effect.position:getDisplayPosition(true, true).x - sourcePosition.x)
    self.damageEffects:push(effect)
end

function Mana:restoreToFull()
    self.currentMana = self:getMax()
end

function Mana:restoreSilent(value)
    self.currentMana = min(self.currentMana + value, self:getMax())
end

function Mana:getMax()
    return self._stats:get(Tags.STAT_MAX_MANA)
end

function Mana:getCurrent()
    return self.currentMana
end

function Mana:getRatio()
    return self.currentMana / self:getMax()
end

function Mana:setRatio(ratio)
        if ratio <= 0 then
        self.currentMana = 0
    elseif ratio ~= self:getRatio() then
        self.currentMana = floor(self:getMax() * ratio + 0.001)
        self.currentRegeneration = 0
    end

end

function Mana:getStat()
    return Tags.STAT_MAX_MANA
end

local function isEffectDone(effect)
    return effect.toDelete
end

function Mana.System:initialize()
    Mana.System:super(self, "initialize")
    self.storageClass = Array
    self:setDependencies("coordinates")
end

function Mana.System:update(dt)
    for entity in self.entities() do
        for effect in entity.mana.damageEffects() do
            effect:update(dt)
        end

        entity.mana.damageEffects:rejectSelf(isEffectDone)
    end

end

function Mana.System:draw()
    for entity in self.entities() do
        for effect in entity.mana.damageEffects() do
            effect:draw(self.services.coordinates)
        end

    end

end

return Mana

