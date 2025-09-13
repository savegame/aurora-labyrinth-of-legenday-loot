local Tank = require("components.create_class")()
local Array = require("utils.classes.array")
local Rect = require("utils.classes.rect")
local Vector = require("utils.classes.vector")
local Set = require("utils.classes.set")
local MEASURES = require("draw.measures")
local COLORS = require("draw.colors")
local DrawMethods = require("draw.methods")
local ACTIONS_BASIC = require("actions.basic")
local TRIGGERS = require("actions.triggers")
local EffectDamage = require("effects.damage")
local Common = require("common")
local BAR_WIDTH = MEASURES.TILE_SIZE - 4
local BAR_HEIGHT = 5
local BAR_MARGIN = 1
function Tank:initialize(entity)
    Tank:super(self, "initialize")
    Debugger.assertComponent(entity, "stats")
    self._stats = entity.stats
    self._entity = entity
    local maxHealth = self:getMax()
    Utils.assert(maxHealth > 0, "Max health must be greater that 0 for tank")
    self.currentHealth = maxHealth
    self.currentRegeneration = 0
    self.delayDeath = false
    self.preDeath = doNothing
    self.deathActionClass = ACTIONS_BASIC.DIE
    self.orbChance = 0
    self.orbSize = 1
    self.scrapReward = 0
    self.killingHit = false
    self.lastDamager = false
    self.drawBar = false
    self.hasDiedOnce = false
    self.keepAlive = false
    self.damageEffects = Array:new()
    entity:callIfHasComponent("serializable", "addComponent", "tank")
    entity:callIfHasComponent("serializable", "addComponentPost", "tank")
end

function Tank:toData(convertToData)
    return { currentHealth = self.currentHealth, currentRegeneration = self.currentRegeneration, keepAlive = self.keepAlive, lastDamager = convertToData(self.lastDamager), hasDiedOnce = self.hasDiedOnce, isPreDeathNothing = (self.preDeath == doNothing) }
end

function Tank:fromData(data, convertFromData)
    self.currentHealth = data.currentHealth
    self.currentRegeneration = data.currentRegeneration
    self.keepAlive = data.keepAlive
    self.hasDiedOnce = data.hasDiedOnce
    if data.isPreDeathNothing then
        self.preDeath = doNothing
    end

end

function Tank:fromDataPost(data, convertFromData)
    self.lastDamager = convertFromData(data.lastDamager)
end

function Tank:regenerate()
    self.currentRegeneration = (self.currentRegeneration + self._stats:get(Tags.STAT_HEALTH_REGEN) * self:getMax())
    if self.currentRegeneration % 1 > 0.9999 then
        self.currentRegeneration = ceil(self.currentRegeneration)
    end

    local integerRegen = floor(self.currentRegeneration)
    if integerRegen > 0 then
        self:restore(integerRegen)
        self.currentRegeneration = self.currentRegeneration - integerRegen
    end

end

function Tank:getMax()
    return self._stats:get(Tags.STAT_MAX_HEALTH)
end

function Tank:getCurrent()
    if not self.keepAlive then
        return max(0, self.currentHealth)
    else
        return self.currentHealth
    end

end

function Tank:isAlive()
    return self.keepAlive or self.currentHealth > 0
end

function Tank:createDamageEffect(value, sourcePosition, bonusState)
    local isNegative = value < 0
    for otherEffect in self.damageEffects() do
        if otherEffect.progress < 0.1 and otherEffect.negative == isNegative then
            otherEffect.value = otherEffect.value + abs(value)
            return otherEffect
        end

    end

    local color = COLORS.NORMAL
        if value < 0 then
        color = COLORS.HEAL
    elseif bonusState then
                                                if bonusState == Tags.DAMAGE_TYPE_BURN then
            color = COLORS.STANDARD_FIRE
        elseif bonusState == Tags.DAMAGE_TYPE_POISON then
            color = COLORS.STANDARD_POISON
        elseif bonusState == Tags.DAMAGE_TYPE_FROSTBITE then
            color = COLORS.STANDARD_ICE
        elseif bonusState == Tags.DAMAGE_TYPE_NIGHTMARE then
            color = COLORS.STANDARD_PSYCHIC
        elseif bonusState > 0 then
            color = COLORS.DAMAGE_INCREASED
        elseif bonusState < 0 then
            color = COLORS.DAMAGE_DECREASED
        end

    end

    local effect = EffectDamage:new(value, color)
    effect.position = self._entity.sprite
    effect.xDirection = sign(effect.position:getDisplayPosition(true, true).x - sourcePosition.x)
    self.damageEffects:push(effect)
end

function Tank:takeDamage(value, sourcePosition, bonusState, killingHit)
    self.currentHealth = self.currentHealth - value
    self.killingHit = killingHit
    self.lastDamager = killingHit.sourceEntity
    self:createDamageEffect(value, sourcePosition, bonusState)
end

function Tank:consume(value)
    self.currentHealth = self.currentHealth - value
end

function Tank:restore(value, sourcePosition)
    self.currentHealth = min(self:getMax(), self.currentHealth + value)
    if sourcePosition then
        self:createDamageEffect(-value, sourcePosition)
    end

end

function Tank:restoreToFull()
    self.currentHealth = self:getMax()
end

function Tank:getRatio()
    return self.currentHealth / self:getMax()
end

function Tank:setRatio(ratio)
        if ratio <= 0 then
        self.currentHealth = 0
    elseif ratio ~= self:getRatio() then
        self.currentHealth = max(1, floor(self:getMax() * ratio + 0.001))
        self.currentRegeneration = 0
    end

end

function Tank:shouldDrawBar()
    return (self.drawBar and self:isAlive() and self.currentHealth < self:getMax())
end

function Tank:getStat()
    return Tags.STAT_MAX_HEALTH
end

function Tank:killNoTrigger(anchor)
    self.lastDamager = false
    self.killingHit = false
    return self:kill(anchor)
end

function Tank:kill(anchor, killer)
    if self.currentHealth > 0 then
        self.currentHealth = 0
    end

    local position = Common.getPositionComponent(self._entity):getPosition()
    if killer then
        self.lastDamager = killer
    end

    local lastDamager = self.lastDamager
    if not self.hasDiedOnce then
        self.hasDiedOnce = true
        if lastDamager and lastDamager:hasComponent("triggers") then
            if self._entity:hasComponent("agent") and lastDamager:hasComponent("equipment") then
                lastDamager.equipment:recordKill()
            end

            if not self._entity:hasComponent("finalboss") then
                anchor = lastDamager.triggers:parallelChainEvent(anchor, TRIGGERS.ON_KILL, false, { killed = self._entity, position = position, killingHit = self.killingHit })
            end

        end

    end

    self.preDeath(self._entity, self.killingHit)
    if self:isAlive() or self.delayDeath then
        return anchor
    end

    local deathAction = self._entity.actor:create(self.deathActionClass)
    deathAction.killer = lastDamager
    deathAction.killingHit = self.killingHit
    deathAction.position = position
    deathAction:parallelResolve(anchor)
    return deathAction:chainEvent(anchor)
end

function Tank:undelayDeath(anchor)
    if not self.delayDeath and not self:isAlive() then
        return 
    end

    self.delayDeath = false
    if not self:isAlive() and self._entity.body:inGrid() then
        self:kill(anchor)
    end

end

function Tank:spawnDeathRewards(position)
    if self.system.services.logicrng:rollChance(self.orbChance) then
        local healthOrb = self.system.services.createEntity("health_orb", position, self.scrapReward, self.orbSize)
        healthOrb.item:startBounceEvent()
    end

end

function Tank.System:initialize()
    Tank.System:super(self, "initialize")
    self.storageClass = Set
    self:setDependencies("coordinates", "logicrng", "createEntity", "vision")
    self.extraDamageEffects = Array:new()
end

local function isEffectDone(effect)
    return effect.toDelete
end

function Tank.System:update(dt)
    for entity in self.entities() do
        for effect in entity.tank.damageEffects() do
            effect:update(dt)
        end

        entity.tank.damageEffects:rejectSelf(isEffectDone)
    end

    for effect in self.extraDamageEffects() do
        effect:update(dt)
    end

    self.extraDamageEffects:rejectSelf(isEffectDone)
end

function Tank.System:deleteInstance(entity)
    Tank.System:super(self, "deleteInstance", entity)
    for damageEffect in entity.tank.damageEffects() do
        self.extraDamageEffects:push(damageEffect)
    end

end

function Tank.System:draw()
    local vision = self.services.vision
    for entity in self.entities() do
        local position = entity.body:getPosition()
        if entity.tank:shouldDrawBar() and vision:isVisibleForDisplay(position) then
            local starting = self.services.coordinates:gridToScreen(entity.sprite:getDisplayPosition())
            local barRect = Rect:new(starting.x + (MEASURES.TILE_SIZE - BAR_WIDTH) / 2, starting.y - BAR_MARGIN - BAR_HEIGHT, BAR_WIDTH, BAR_HEIGHT):sizeAdjusted(-1)
            graphics.wSetColor(COLORS.STROKE)
            DrawMethods.fillClippedRect(barRect:sizeAdjusted(1), 1)
            graphics.wSetColor(COLORS.BAR_BASE)
            graphics.wRectangle(barRect)
            graphics.wSetColor(COLORS.HEALTH_TOP)
            DrawMethods.bar(barRect, entity.tank:getRatio())
            graphics.wSetColor(COLORS.HEALTH_BOTTOM)
            DrawMethods.bar(barRect.x, barRect.y + barRect.height - 1, barRect.width, 1, entity.tank:getRatio())
        end

    end

    for entity in self.entities() do
        for effect in entity.tank.damageEffects() do
            effect:draw(self.services.coordinates)
        end

    end

    for effect in self.extraDamageEffects() do
        effect:draw(self.services.coordinates)
    end

end

return Tank

