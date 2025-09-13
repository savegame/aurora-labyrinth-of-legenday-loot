local Equipment = require("components.create_class")()
local Vector = require("utils.classes.vector")
local Hash = require("utils.classes.hash")
local Array = require("utils.classes.array")
local TRIGGERS = require("actions.triggers")
local ITEMS = require("definitions.items")
local SLOT_ORDER = ITEMS.SLOTS
local CONSTANTS = require("logic.constants")
local RESOURCE_STATS = require("utils.classes.set"):new(Tags.STAT_MAX_HEALTH, Tags.STAT_MAX_MANA)
local Global = require("global")
Tags.add("ALERT_NO_SOUND", 1)
function Equipment:initialize(entity)
    Equipment:super(self, "initialize", entity)
    entity.stats:addBonusSource(self)
    self._entity = entity
    self.equipped = Hash:new()
    self.cooldowns = Hash:new()
    self.alertChanged = Hash:new()
    self.slotBuffs = Hash:new()
    self.tempStatBonus = Hash:new()
    self.abilityStatBonuses = Hash:new()
    self.postCastTriggerAction = false
    entity:callIfHasComponent("serializable", "addComponentPost", "equipment")
end

function Equipment:toData(convertToData)
    local slotBuffs = {  }
    for slot, buff in self.slotBuffs() do
        local buffData = buff:toData(convertToData)
        buffData.duration = buff.duration
        buffData.abilityStats = buff.abilityStats.container
        if buff:rememberAction() then
            buffData.actionDirection = buff.action.direction
            buffData.actionAbilityStats = convertToData(buff.action.abilityStats)
            buffData.actionData = buff.action:toData(convertToData)
        end

        slotBuffs[slot] = buffData
    end

    local tempStatBonus = {  }
    for slot, bonuses in self.tempStatBonus() do
        tempStatBonus[slot] = bonuses.container
    end

    return { equipped = self.equipped:mapValues(convertToData).container, cooldowns = self.cooldowns.container, tempStatBonus = tempStatBonus, slotBuffs = slotBuffs }
end

function Equipment:fromDataPost(data, convertFromData)
    self:setFromHash(Hash:new(data.equipped):mapValues(convertFromData), true)
    self.cooldowns = Hash:new(data.cooldowns)
    self.tempStatBonus = Hash:new()
    for slot, bonusData in pairs(data.tempStatBonus) do
        self.tempStatBonus:set(slot, Hash:new(bonusData))
    end

    for slot, buffData in pairs(data.slotBuffs) do
        local buffClass = self:get(slot):getBuffClass()
        local buff = buffClass:new(buffData.duration, Hash:new(buffData.abilityStats))
        buff:fromData(buffData, convertFromData)
        if buffData.actionDirection then
            local actionClass = self:getAbility(slot).actionClass
            local action = self._entity.actor:create(actionClass, buffData.actionDirection, convertFromData(buffData.actionAbilityStats))
            action:setFromLoad(buffData.actionData, convertFromData)
            buff.action = action
        end

        self._entity.buffable:forceApply(buff)
        self.slotBuffs:set(slot, buff)
    end

end

function Equipment:setFromHash(equipped, fromLoad)
    self.equipped = equipped
    for slot, item in self.equipped() do
        item:onEquip(self._entity, fromLoad)
        if slot == Tags.SLOT_AMULET then
            self:setClassSprite(item)
        end

    end

end

local FEMALE_OFFSET = Vector:new(1, 0)
function Equipment:setClassSprite(item)
    local classSprite = item:getClassSprite()
    if self._entity.player.isFemale then
        classSprite = classSprite + FEMALE_OFFSET
    end

    self._entity.sprite:setCell(classSprite)
    local strokeColor = item:getStrokeColor()
    if strokeColor then
        self._entity.sprite.strokeColor:push(strokeColor)
    end

end

function Equipment:getSlotsWithAbilities()
    return ITEMS.SLOTS_WITH_ABILITIES
end

function Equipment:getClassName()
    local amulet = self:get(Tags.SLOT_AMULET)
    if amulet then
        return amulet:getClassName()
    else
        return "Adventurer"
    end

end

function Equipment:getAndConsumeAlert(slot)
    local result = self.alertChanged:get(slot, false)
    self.alertChanged:deleteKeyIfExists(slot)
    return result
end

function Equipment:clearTempStatBonus(slot)
    self.tempStatBonus:deleteKeyIfExists(slot)
end

function Equipment:setTempStatBonus(slot, stat, value)
    if not self.tempStatBonus:hasKey(slot) then
        self.tempStatBonus:set(slot, Hash:new())
    end

    self.tempStatBonus:get(slot):set(stat, value)
end

function Equipment:addTempStatBonus(slot, stat, value)
    if not self.tempStatBonus:hasKey(slot) then
        self.tempStatBonus:set(slot, Hash:new())
    end

    self.tempStatBonus:get(slot):add(stat, value, 0)
end

function Equipment:getTempStatBonus(slot, stat)
    if not self.tempStatBonus:hasKey(slot) then
        return 0
    end

    return self.tempStatBonus:get(slot):get(stat, 0)
end

function Equipment:equip(item, slot)
    slot = slot or item:getSlot()
    local healthRatio = self._entity.tank:getRatio()
    local manaRatio = self._entity.mana:getRatio()
    local equipped = self.equipped:get(slot, false)
    if equipped then
        equipped:onUnequip(self._entity)
    end

    if item then
        self.equipped:set(slot, item)
    else
        self.equipped:deleteKey(slot)
    end

    self:clearTempStatBonus(slot)
    if slot == Tags.SLOT_AMULET then
        if not item then
            self._entity.sprite:resetCell()
        else
            self:setClassSprite(item)
        end

    else
        self:setOnCooldown(slot)
    end

    self._entity.tank:setRatio(healthRatio)
    self._entity.mana:setRatio(manaRatio)
    if item then
        item:onEquip(self._entity)
    end

    self.alertChanged:set(slot, Tags.ALERT_NO_SOUND)
end

function Equipment:get(slot)
    return self.equipped:get(slot, false)
end

function Equipment:hasEquipped(slot)
    return toBoolean(self.equipped:get(slot, false))
end

function Equipment:getAbility(slot)
    local item = self:get(slot)
    if item then
        return item:getAbility()
    else
        return false
    end

end

function Equipment:_getBonusForStat(item, stat, baseValue, exceptForSlot)
    local bonus = self.tempStatBonus:get(item:getSlot(), Hash.EMPTY):get(stat, 0)
    local bonusProviders = self.abilityStatBonuses:get(stat, Array.EMPTY)
    for bonusProvider in bonusProviders() do
        if bonusProvider:getSlot() ~= exceptForSlot then
            bonus = bonus + bonusProvider:getAbilityStatBonus(item, stat, baseValue, self._entity, baseValue + bonus)
        end

    end

    return bonus
end

function Equipment:getSlotStat(slot, stat, exceptForSlot)
    local item = self:get(slot)
    if item then
        local baseValue = item.stats:get(stat, 0)
        return baseValue + self:_getBonusForStat(item, stat, baseValue, exceptForSlot)
    else
        return 0
    end

end

function Equipment:getBaseSlotStat(slot, stat)
    local item = self:get(slot)
    if item then
        return item.stats:get(stat, 0)
    else
        return 0
    end

end

function Equipment:getSlotStats(slot)
    local item = self:get(slot)
    if item then
        local result = item.stats:mapValues(function(baseValue, stat)
            return baseValue + self:_getBonusForStat(item, stat, baseValue)
        end)
        if not result:hasKey(Tags.STAT_ABILITY_MANA_COST) then
            result:set(Tags.STAT_ABILITY_MANA_COST, self:getSlotStat(slot, Tags.STAT_ABILITY_MANA_COST))
        end

        if not result:hasKey(Tags.STAT_ABILITY_HEALTH_COST) then
            result:set(Tags.STAT_ABILITY_HEALTH_COST, self:getSlotStat(slot, Tags.STAT_ABILITY_HEALTH_COST))
        end

        return result
    else
        return Hash:new()
    end

end

function Equipment:hasManaForSlot(slot)
    local manaCost = self:getSlotStat(slot, Tags.STAT_ABILITY_MANA_COST)
    return self._entity.mana:getCurrent() >= manaCost
end

function Equipment:hasHealthForSlot(slot)
    local healthCost = self:getSlotStat(slot, Tags.STAT_ABILITY_HEALTH_COST)
    if healthCost <= 0 then
        return true
    end

    return self._entity.tank:getCurrent() >= healthCost + 1
end

function Equipment:hasResourcesForSlot(slot)
    return self:hasManaForSlot(slot) and self:hasHealthForSlot(slot)
end

function Equipment:consumeSlotResources(abilityStats)
    self._entity.mana:consume(abilityStats:get(Tags.STAT_ABILITY_MANA_COST))
    self._entity.tank:consume(abilityStats:get(Tags.STAT_ABILITY_HEALTH_COST))
end

function Equipment:getSlotManaCost(slot)
    return self:getSlotStat(slot, Tags.STAT_ABILITY_MANA_COST)
end

function Equipment:getSlotHealthCost(slot)
    return self:getSlotStat(slot, Tags.STAT_ABILITY_HEALTH_COST)
end

function Equipment:getSlotMaxCooldown(slot)
    local item = self:get(slot)
    local cooldown = self:getSlotStat(slot, Tags.STAT_ABILITY_COOLDOWN)
    local reduction = self._entity.stats:get(Tags.STAT_COOLDOWN_REDUCTION)
    if slot == Tags.SLOT_RING or slot == Tags.SLOT_AMULET then
        reduction = 0
    end

    if cooldown == 0 then
        return 0
    end

    return max(CONSTANTS.MIN_COOLDOWN_ON_REDUCE, cooldown - reduction)
end

function Equipment:getStatBonus(stat, exceptSlot)
    local totalBonus = 0
    for slot, item in self.equipped() do
        if slot ~= exceptSlot then
            totalBonus = totalBonus + item:getNonAbilityStat(stat, self._entity)
        end

    end

    if not self:get(Tags.SLOT_WEAPON) then
                if stat == Tags.STAT_ATTACK_DAMAGE_MIN then
            totalBonus = totalBonus + CONSTANTS.BAREHANDED_DAMAGE_MIN
        elseif stat == Tags.STAT_ATTACK_DAMAGE_MAX then
            totalBonus = totalBonus + CONSTANTS.BAREHANDED_DAMAGE_MAX
        end

    end

    return totalBonus
end

function Equipment:getStatMultiplier(stat)
    if RESOURCE_STATS:contains(stat) then
        return DebugOptions.RESOURCES_MULTIPLIER
    else
        return 1
    end

end

function Equipment:getCooldownFor(slot)
    return self.cooldowns:get(slot, 0)
end

function Equipment:isReady(slot)
    return self.cooldowns:get(slot, 0) <= 0
end

function Equipment:setOnCooldown(slot, extra)
    local cooldown = self:getSlotMaxCooldown(slot) + (extra or 0)
    if DebugOptions.COOLDOWN_MAXIMUM then
        cooldown = min(DebugOptions.COOLDOWN_MAXIMUM, cooldown)
    end

    return self.cooldowns:set(slot, cooldown)
end

function Equipment:resetCooldown(slot)
    if self.cooldowns:get(slot, 0) > 0 then
        self.cooldowns:set(slot, 0)
        self.alertChanged:set(slot, true)
    end

end

function Equipment:reduceCooldown(slot, value)
    local current = self.cooldowns:get(slot, 0)
    if current > 0 then
        self.cooldowns:set(slot, max(0, current - value))
        self.alertChanged:set(slot, true)
    end

end

function Equipment:reduceCooldownSilent(slot, value)
    self.cooldowns:set(slot, max(0, self.cooldowns:get(slot, 0) - value))
end

function Equipment:activateSlot(slot, action)
    local item = self:get(slot)
    self.postCastTriggerAction = action
    local slotStats = self:getSlotStats(slot)
    local duration = slotStats:get(Tags.STAT_ABILITY_BUFF_DURATION, 0)
    if duration >= CONSTANTS.PRESUMED_INFINITE then
        duration = math.huge
    end

    local buff = item:getBuffClass():new(duration, slotStats)
    if buff:rememberAction() then
        buff.action = action
    end

    if buff.expiresImmediately or self:getSlotStat(slot, Tags.STAT_ABILITY_QUICK) > 0 then
        self._entity.buffable:forceApply(buff)
    else
        self._entity.buffable:apply(buff)
    end

    self.slotBuffs:set(slot, buff)
    self:recordCast(slot)
end

function Equipment:recordCast(slot)
    local item = self:get(slot)
    if item then
        Global:get(Tags.GLOBAL_PROFILE):recordCast(item)
    end

end

function Equipment:recordStairs()
    Global:get(Tags.GLOBAL_PROFILE):recordItemStats(self.equipped, "stairs")
end

function Equipment:recordKill()
    Global:get(Tags.GLOBAL_PROFILE):recordItemStats(self.equipped, "kills")
end

function Equipment:recordDeath()
    Global:get(Tags.GLOBAL_PROFILE):recordItemStats(self.equipped, "deaths")
end

function Equipment:recordWin()
    Global:get(Tags.GLOBAL_PROFILE):recordItemStats(self.equipped, "wins")
end

function Equipment:deactivateSlot(anchor, slot)
    if self.slotBuffs:hasKey(slot) then
        self._entity.buffable:delete(anchor, self.slotBuffs:get(slot):getClass())
        self.slotBuffs:deleteKey(slot)
    end

    self:setOnCooldown(slot)
    return self._entity.triggers:parallelChainEvent(anchor, TRIGGERS.ON_SLOT_DEACTIVATE, false, { triggeringSlot = slot })
end

function Equipment:isSlotActive(slot)
    return self.slotBuffs:hasKey(slot)
end

function Equipment:extendSlotBuff(slot, amount)
    if self:isSlotActive(slot) then
        local buff = self.slotBuffs:get(slot)
        buff.duration = buff.duration + amount
        self.alertChanged:set(slot, true)
    end

end

function Equipment:getDuration(slot)
    if self.slotBuffs:hasKey(slot) then
        return self.slotBuffs:get(slot).duration
    else
        return 0
    end

end

function Equipment:getSlotBuff(slot)
    return self.slotBuffs:get(slot, false)
end

function Equipment:getSustainedSlot()
    for slot, slotBuff in self.slotBuffs() do
        if slotBuff:getSustainMode() > Tags.SUSTAIN_MODE_NONE then
            return slot
        end

    end

    return false
end

function Equipment:isSustainAutocast()
    return self.slotBuffs:values():any(function(slotBuff)
        return slotBuff:getSustainMode() >= Tags.SUSTAIN_MODE_AUTOCAST
    end)
end

function Equipment:isSustainMobile()
    return self.slotBuffs:values():any(function(slotBuff)
        return slotBuff:getSustainMode() == Tags.SUSTAIN_MODE_MOBILE
    end)
end

function Equipment:isSustainSpecial()
    return self.slotBuffs:values():any(function(slotBuff)
        return slotBuff:getSustainMode() == Tags.SUSTAIN_MODE_SPECIAL
    end)
end

function Equipment:_clearExpiredBuffs(anchor)
    local slots = self.slotBuffs:keys()
    for slot in slots() do
        local buff = self.slotBuffs:get(slot)
        if buff.duration <= 0 then
            self.slotBuffs:deleteKey(slot)
            self:setOnCooldown(slot)
            anchor = self._entity.triggers:parallelChainEvent(anchor, TRIGGERS.ON_SLOT_DEACTIVATE, false, { triggeringSlot = slot })
        end

    end

    if self.postCastTriggerAction then
        self._entity.triggers:parallelChainEvent(anchor, TRIGGERS.POST_CAST, self.postCastTriggerAction.direction, { triggeringAction = self.postCastTriggerAction, triggeringSlot = self.postCastTriggerAction:getSlot() })
        self.postCastTriggerAction = false
    end

end

function Equipment:startOfTurn(anchor)
    self:_clearExpiredBuffs(anchor)
end

function Equipment:midTurnQuick(anchor)
    self:_clearExpiredBuffs(anchor)
end

function Equipment:endOfTurn(anchor)
    self.cooldowns = self.cooldowns:mapValues(function(value)
        return max(0, value - 1)
    end)
    self:_clearExpiredBuffs(anchor)
end

function Equipment:decorateOutgoingHit(hit)
    for slot, item in self.equipped:sortedKeysIterator() do
        item:decorateOutgoingHit(self._entity, hit, self:getSlotStats(slot))
    end

    if DebugOptions.DAMAGE_MULTIPLIER > 1 then
        hit:multiplyDamage(DebugOptions.DAMAGE_MULTIPLIER)
    end

end

function Equipment:decorateIncomingHit(hit)
    for slot, item in self.equipped:sortedKeysIterator() do
        item:decorateIncomingHit(self._entity, hit, self:getSlotStats(slot))
    end

end

function Equipment:decorateBasicMove(action)
    for _, item in self.equipped:sortedKeysIterator() do
        item:decorateBasicMove(self._entity, action)
    end

end

function Equipment:getTotalSellCost()
    local total = 0
    for slot, item in self.equipped() do
        total = total + item:getSellCost()
    end

    return total
end

return Equipment

