local Item = class()
local Hash = require("utils.classes.hash")
local Array = require("utils.classes.array")
local Global = require("global")
Tags.add("STAT_UPGRADED", 1)
Tags.add("STAT_UNCHANGED", 0)
Tags.add("STAT_DOWNGRADED", -1)
local UPGRADE_COSTS = Array:new(12, 14, 16, 19, 22, 26, 30, 35, 40, 45)
local CONSTANTS = require("logic.constants")
local LogicMethods = require("logic.methods")
function Item:initialize(definition)
    self.name = false
    self.level = 0
    self.definition = definition
    self.modifierDef = false
    self.stats = false
    self.extraCostLine = false
    self.labelColor = false
    self.triggers = false
    self.scrapSpent = 0
    self.hasBeenSeen = false
    self.scrapCost = 0
    self.alteredStats = Hash:new()
    self.extraGrowth = Hash:new()
    self.onEquipCallbacks = Array:new()
    self.onUnequipCallbacks = Array:new()
    self.conditionalNonAbilityStat = false
end

function Item:setHasBeenSeen()
    if not self.hasBeenSeen then
        self.hasBeenSeen = true
        Global:get(Tags.GLOBAL_PROFILE):recordSeen(self)
    end

end

function Item:toData()
    local data = { itemDefinition = self.definition.saveKey, scrapSpent = self.scrapSpent, hasBeenSeen = self.hasBeenSeen, level = self.level }
    if self:isLegendary() then
        data.isLegendary = true
    else
        data.isLegendary = false
        if self.modifierDef then
            data.modifier = self.modifierDef.saveKey
        end

    end

    return data
end

function Item:getBuffClass()
    return self:getAbility().buffClass
end

local function lessSlot(a, b)
    return a:getSlot() < b:getSlot()
end

function Item:getNonAbilityStat(stat, entity)
    local value = 0
    if self.conditionalNonAbilityStat then
        value = self.conditionalNonAbilityStat(stat, entity, self.stats)
    end

    return value + self.stats:get(stat, 0)
end

function Item:_getStatsWithBonuses()
    local result = self.definition.abilityStatBonuses:keys()
    if self.modifierDef then
        result:concat(self.modifierDef.abilityStatBonuses:keys())
    end

    return result
end

function Item:onEquip(entity, fromLoad)
    for callback in self.onEquipCallbacks() do
        callback(entity, self, fromLoad)
    end

    local equipment = entity.equipment
    for stat, _ in (self:_getStatsWithBonuses())() do
        local bonuses = equipment.abilityStatBonuses:get(stat, false)
        if not bonuses then
            equipment.abilityStatBonuses:set(stat, Array:new(self))
        else
            bonuses:push(self)
            bonuses:stableSortSelf(lessSlot)
        end

    end

end

function Item:onUnequip(entity)
    for callback in self.onUnequipCallbacks() do
        callback(entity, self)
    end

    local equipment = entity.equipment
    for stat, _ in (self:_getStatsWithBonuses())() do
        local statBonuses = equipment.abilityStatBonuses:get(stat)
        statBonuses:delete(self)
        if statBonuses:isEmpty() then
            equipment.abilityStatBonuses:deleteKey(stat)
        end

    end

end

function Item:isMaxLevel()
    return self.level >= CONSTANTS.ITEM_UPGRADE_LEVELS
end

function Item:isAccessory()
    local slot = self:getSlot()
    return slot == Tags.SLOT_RING or slot == Tags.SLOT_AMULET
end

function Item:_addStat(stat, addend)
    if addend ~= 0 then
        local value = self.stats:get(stat, 0) + addend
        self.stats:set(stat, value)
    end

end

function Item:multiplyStatAndGrowth(stat, multiplier)
    local currentValue = self.stats:get(stat)
    local multiplied = round(currentValue * multiplier)
    local lastValue = multiplied
    self.stats:set(stat, multiplied)
    for i = 1, CONSTANTS.ITEM_UPGRADE_LEVELS do
        local growth = self:getGrowthForLevel(i):get(stat, 0)
        if self.modifierDef then
            growth = growth + self.modifierDef:getGrowthForLevel(i):get(stat, 0)
        end

        currentValue = currentValue + growth
        multiplied = round(currentValue * multiplier)
        local newGrowth = multiplied - lastValue - growth
        if newGrowth ~= 0 then
            local extraGrowth
            if self.extraGrowth:hasKey(i) then
                extraGrowth = self.extraGrowth:get(i)
            else
                extraGrowth = Hash:new()
                self.extraGrowth:set(i, extraGrowth)
            end

            extraGrowth:add(stat, newGrowth, 0)
        end

        lastValue = multiplied
    end

end

function Item:decorateOutgoingHit(entity, hit, abilityStats)
    self.definition.decorateOutgoingHit(entity, hit, abilityStats)
    if self.modifierDef then
        self.modifierDef.decorateOutgoingHit(entity, hit, abilityStats)
    end

end

function Item:decorateIncomingHit(entity, hit, abilityStats)
    self.definition.decorateIncomingHit(entity, hit, abilityStats)
    if self.modifierDef then
        self.modifierDef.decorateIncomingHit(entity, hit, abilityStats)
    end

end

function Item:decorateBasicMove(entity, action)
    if self.modifierDef then
        self.modifierDef.decorateBasicMove(entity, action, self.stats)
    end

    self.definition.decorateBasicMove(entity, action, self.stats)
end

function Item:getAbilityStatBonus(item, stat, baseValue, entity, currentValue)
    local bonus = 0
    if self.definition.abilityStatBonuses:hasKey(stat) then
        bonus = self.definition.abilityStatBonuses:get(stat)(item, baseValue, self.stats, entity, currentValue)
    end

    if self.modifierDef and self.modifierDef.abilityStatBonuses:hasKey(stat) then
        bonus = bonus + self.modifierDef.abilityStatBonuses:get(stat)(item, baseValue, self.stats, entity, currentValue + bonus)
    end

    return bonus
end

function Item:upgrade()
    self.level = self.level + 1
    for stat, value in (self.definition:getGrowthForLevel(self.level))() do
        self:_addStat(stat, value)
    end

    local scrapMultiplier = 1
    if self.modifierDef then
        for stat, value in (self.modifierDef:getGrowthForLevel(self.level))() do
            self:_addStat(stat, value)
        end

    end

    if self.extraGrowth:hasKey(self.level) then
        for stat, value in (self.extraGrowth:get(self.level))() do
            self:_addStat(stat, value)
        end

    end

    self.scrapCost = self.scrapCost + CONSTANTS.SCRAP_COST_PER_LEVEL * scrapMultiplier
end

function Item:getNextUpgradeWithGrowth()
    for i = self.level + 1, CONSTANTS.ITEM_UPGRADE_LEVELS do
        if not self.definition:getGrowthForLevel(i):isEmpty() then
            return i
        end

    end

    return CONSTANTS.ITEM_UPGRADE_LEVELS
end

function Item:getUpgradeCost(difficulty)
    local cost = UPGRADE_COSTS[self.level + 1] + (difficulty - Tags.DIFFICULTY_NORMAL) * CONSTANTS.DIFFICULTY_UPGRADE_DIFFERENCE
    return cost - self.stats:get(Tags.STAT_UPGRADE_DISCOUNT, 0)
end

function Item:isUpgradeDisabled()
    if self:isLegendaryAmulet() then
        return false
    end

    return self.definition.disableUpgrade
end

function Item:getFullName()
    if self.level == 0 or self:isLegendaryAmulet() then
        return self.name
    else
        return "+" .. self.level .. " " .. self.name
    end

end

function Item:isLegendary()
    return self.modifierDef and self.modifierDef.isLegendary
end

function Item:isLegendaryAmulet()
    return self:getSlot() == Tags.SLOT_AMULET and self:isLegendary()
end

function Item:getPassiveDescription()
    return Utils.evaluate(self.definition.getPassiveDescription, self)
end

function Item:isFirstPassiveNegative()
    return self.definition.firstPassiveNegative
end

function Item:getModifierStatLine()
    if self.modifierDef and self.modifierDef.statLine then
        return Utils.evaluate(self.modifierDef.statLine, self)
    else
        return false
    end

end

function Item:getSellCost()
    local multiplier = 1
    if self:isLegendary() then
        multiplier = CONSTANTS.LEGENDARY_SELL_COST_MULTIPLIER
    end

    return ceil(self.scrapCost * multiplier + self.scrapSpent * CONSTANTS.SCRAP_SPENT_SELL_RATIO)
end

function Item:getSlot()
    return self.definition.slot
end

function Item:getIcon()
    return self.definition.icon
end

function Item:getAbility()
    return self.definition.ability
end

function Item:getClassSprite()
    return self.definition.classSprite
end

function Item:getClassName()
    return self.definition.className
end

function Item:getAttackClass()
    return self.definition.attackClass
end

function Item:getGrowthForLevel(level)
    return self.definition:getGrowthForLevel(level)
end

function Item:getStatAtMax(stat)
    return self.definition:getStatAtMax(stat)
end

function Item:getModeColor()
    local ability = self.definition.ability
    if ability.noModeColor then
        return false
    else
        return self.definition.ability.iconColor
    end

end

function Item:getStrokeColor()
    if self.modifierDef then
        return self.modifierDef:getLegendaryStrokeColor(self.definition)
    end

    return false
end

function Item:markAltered(stat, alteration)
    self.alteredStats:set(stat, alteration)
end

function Item:getStatAlteration(stat)
    return self.alteredStats:get(stat, Tags.STAT_UNCHANGED)
end

function Item:displayNextIncrease()
    return self.definition.displayNextIncrease
end

return Item

