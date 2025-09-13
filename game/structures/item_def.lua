local ItemDef = class("structures.growing_stats_def")
local Set = require("utils.classes.set")
local Hash = require("utils.classes.hash")
local Array = require("utils.classes.array")
local RollTable = require("utils.classes.roll_table")
local CONSTANTS = require("logic.constants")
local ModifierDef = require("structures.modifier_def")
function ItemDef:initialize(name)
    ItemDef:super(self, "initialize")
    Utils.assert(name, "ItemDef requires name")
    self.name = name
    self.minFloor = 0
    self.getPassiveDescription = alwaysFalse
    self.firstPassiveNegative = false
    self.slot = false
    self.icon = false
    self.ability = false
    self.attackClass = false
    self.triggers = Array:new()
    self.legendaryMod = false
    self.suffixTable = RollTable:new()
    self.extraCostLine = false
    self.disableUpgrade = false
    self.classSprite = false
    self.onEquip = false
    self.onUnequip = false
    self.displayNextIncrease = false
    self.postCreate = doNothing
    self.isComplex = false
end

function ItemDef:setToMediumComplexity()
    self.isComplex = true
end

function ItemDef:setToHighComplexity()
    self.minFloor = CONSTANTS.MIN_FLOOR_HIGH_COMPLEXITY
end

function ItemDef:getManaCostMultiplied(multiplier)
    return round(self.statsBase:get(Tags.STAT_ABILITY_MANA_COST) * multiplier - 0.001)
end

function ItemDef:isSlotOffensive()
    return self.slot == Tags.SLOT_WEAPON or self.slot == Tags.SLOT_GLOVES or self.slot == Tags.SLOT_HELM
end

function ItemDef:createLegendary(name)
    local modifier = ModifierDef:new(name)
    modifier.statsBase:set(Tags.STAT_LEGENDARY, 1)
    modifier.isLegendary = true
    self.legendaryMod = modifier
    return modifier
end

function ItemDef:calculateCostsIfHasPower()
    if self.ability and self.statsBase:hasKey(Tags.STAT_ABILITY_POWER) then
        self:calculateCostsFromPower()
    end

end

local FINAL_COOLDOWN_MULTIPLIER = 1.5
local FINAL_MANA_MULTIPLIER = 1.0
local POWER_EXPONENT = 1.25
local BOOTS_COOLDOWN_MULTIPLIER = 1.3
local WEAPON_COOLDOWN_MULTIPLIER = 0.9
local GLOVES_COOLDOWN_MULTIPLIER = 0.9
local UNUPGRADED_MANA_RATIO = 1.25
function ItemDef:calculateCostsFromPower()
    Utils.assert(not self.statsBase:hasKey(Tags.STAT_ABILITY_MANA_COST))
    Utils.assert(not self.statsBase:hasKey(Tags.STAT_ABILITY_COOLDOWN))
    local costMultiplier = 425
    local minCostPerTurn = 4
    local maxCostPerTurn = 13
        if self.slot == Tags.SLOT_WEAPON then
        costMultiplier = costMultiplier * 0.9
    elseif self.slot == Tags.SLOT_BOOTS then
    end

    local power = self.statsBase:get(Tags.STAT_ABILITY_POWER) ^ POWER_EXPONENT
    local power = (power - 1) * costMultiplier
    local maxMana = self.statsBase:get(Tags.STAT_MAX_MANA, 0)
    local maxHealth = self.statsBase:get(Tags.STAT_MAX_HEALTH, 0)
    local ratio
    if maxMana == 0 and maxHealth == 0 then
        ratio = self.statsBase:get(Tags.STAT_VIRTUAL_RATIO)
    else
        ratio = maxMana / (maxMana + maxHealth)
    end

    if self.slot == Tags.SLOT_ARMOR or self.slot == Tags.SLOT_BOOTS then
        ratio = ratio / 2
    end

    local manaCDRatio = minCostPerTurn + (maxCostPerTurn - minCostPerTurn) * ratio
    local manaCost = sqrt(power) * sqrt(manaCDRatio)
    manaCost = round(manaCost * FINAL_MANA_MULTIPLIER / 5) * 5
    local cooldown = (FINAL_COOLDOWN_MULTIPLIER * manaCost / manaCDRatio)
            if self.slot == Tags.SLOT_BOOTS then
        cooldown = cooldown * BOOTS_COOLDOWN_MULTIPLIER
    elseif self.slot == Tags.SLOT_WEAPON then
        cooldown = cooldown * WEAPON_COOLDOWN_MULTIPLIER
    elseif self.slot == Tags.SLOT_GLOVES then
        cooldown = cooldown * GLOVES_COOLDOWN_MULTIPLIER
    end

    local buffDuration = max(1, self.statsBase:get(Tags.STAT_ABILITY_BUFF_DURATION, 0))
    local countDiscount = self.powerSpikes:countIf(function(spikeHash)
        return spikeHash:get(Tags.STAT_ABILITY_MANA_DISCOUNT, 0) > 0
    end)
    local targetManaCost = manaCost
    if countDiscount > 0 then
        targetManaCost = floor((manaCost * UNUPGRADED_MANA_RATIO) / 5) * 5
    end

    for spikeHash in self.powerSpikes() do
        if spikeHash:get(Tags.STAT_ABILITY_MANA_DISCOUNT, 0) > 0 then
            local diff = floor((targetManaCost - manaCost) / countDiscount)
            spikeHash:set(Tags.STAT_ABILITY_MANA_COST, -diff)
            countDiscount = countDiscount - 1
        end

        manaCost = manaCost - spikeHash:get(Tags.STAT_ABILITY_MANA_COST, 0)
        cooldown = cooldown - spikeHash:get(Tags.STAT_ABILITY_COOLDOWN, 0)
        buffDuration = buffDuration + spikeHash:get(Tags.STAT_ABILITY_BUFF_DURATION, 0)
    end

    if (not self.ability:hasTag(Tags.ABILITY_TAG_BUFF_NOT_CONSIDERED)) then
        if self.ability:hasTag(Tags.ABILITY_TAG_BUFF_HALF_CONSIDERED) then
            cooldown = cooldown - (buffDuration - 1) / 2
        else
            cooldown = cooldown - (buffDuration - 1)
        end

    end

    cooldown = round(cooldown)
    self.statsBase:set(Tags.STAT_ABILITY_MANA_COST, manaCost)
    self.statsBase:set(Tags.STAT_ABILITY_COOLDOWN, cooldown)
end

function ItemDef:extrapolate()
    ItemDef:super(self, "extrapolate")
    for i, growth in ipairs(self.growthPerLevel) do
        local hasGrowth = false
        for k, v in growth() do
                        if k ~= Tags.STAT_MAX_MANA and k ~= Tags.STAT_MAX_HEALTH then
                hasGrowth = true
                break
            elseif self.slot == Tags.SLOT_AMULET or self.slot == Tags.SLOT_RING then
                hasGrowth = true
                break
            end

        end

        if not hasGrowth then
            Debugger.log("Missing growth: ", self.name, i)
        end

    end

end

return ItemDef

